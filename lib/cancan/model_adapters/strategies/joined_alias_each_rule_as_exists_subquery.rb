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
          double_exists_sql = ''

          compressed_rules.each_with_index do |rule, index|
            double_exists_sql << ' OR ' if index.positive?
            double_exists_sql << "EXISTS (#{sub_query_for_rule(rule).to_sql})"
          end

          double_exists_sql
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
