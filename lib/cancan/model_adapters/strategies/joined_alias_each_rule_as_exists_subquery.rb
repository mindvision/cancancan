# frozen_string_literal: false

module CanCan
  module ModelAdapters
    class Strategies
      class JoinedAliasEachRuleAsExistsSubquery < Base
        def execute!
          model_class
            .joins(
              "JOIN #{quoted_table_name} AS #{quoted_aliased_table_name} ON " \
              "#{quoted_aliased_table_name}.#{quoted_primary_key} = #{quoted_table_name}.#{quoted_primary_key}"
            )
            .where(double_exists_sql)
        end

        def double_exists_sql
          cans, cannots = compressed_rules.partition(&:can_rule?)

          if !cans.empty?
            can_sql = cans.map { |rule| "EXISTS (#{sub_query_for_rule(rule).to_sql})" }.join(' OR ')
            can_sql = "(#{can_sql})" if cans.size > 1
          end
          if !cannots.empty?
            cannot_sql = cannots.map { |rule| "EXISTS (#{sub_query_for_rule(rule.flip).to_sql})" }.join(' OR ')
            cannot_sql = "NOT (#{cannot_sql})"
          end
          [can_sql, cannot_sql].compact.join(' AND ')
        end

        def sub_query_for_rule(rule)
          scope_for_rule(rule)
            .select('1')
            .where(
              "#{quoted_table_name}.#{quoted_primary_key} = " \
              "#{quoted_aliased_table_name}.#{quoted_primary_key}"
            )
            .limit(1)
        end
      end
    end
  end
end
