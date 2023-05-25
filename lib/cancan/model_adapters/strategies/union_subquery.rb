# frozen_string_literal: true

module CanCan
  module ModelAdapters
    class Strategies
      class UnionSubquery < Base
        def execute!
          cans, cannots = compressed_rules.partition(&:can_rule?)

          query = model_class

          if !cans.empty?
            subquery = union_select(cans)
            query = query.where("#{quoted_table_name}.#{quoted_primary_key} IN (#{subquery})")
          end

          if !cannots.empty?
            subquery = union_select(cannots.map(&:flip))
            query = query.where("#{quoted_table_name}.#{quoted_primary_key} NOT IN (#{subquery})")
          end

          query
        end

        def union_select(rules)
          selects = rules.map do |rule|
            node = scope_for_rule(rule).reorder(nil).select(model_class.primary_key).to_sql
          end.join(' UNION ')
        end
      end
    end
  end
end
