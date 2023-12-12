module CanCan
  module ModelAdapters
    class Strategies
      class Base
        attr_reader :adapter, :relation, :where_conditions

        delegate(
          :compressed_rules,
          :extract_multiple_conditions,
          :joins,
          :model_class,
          :quoted_primary_key,
          :quoted_aliased_table_name,
          :quoted_table_name,
          to: :adapter
        )
        delegate :connection, :quoted_primary_key, to: :model_class
        delegate :quote_table_name, to: :connection

        def initialize(adapter:, relation:, where_conditions:)
          @adapter = adapter
          @relation = relation
          @where_conditions = where_conditions
        end

        def aliased_table_name
          @aliased_table_name ||= "#{model_class.table_name}_alias"
        end

        def quoted_aliased_table_name
          @quoted_aliased_table_name ||= quote_table_name(aliased_table_name)
        end

        def quoted_table_name
          @quoted_table_name ||= quote_table_name(model_class.table_name)
        end

        def scope_for_rule(rule)
          conditions_extractor = ConditionsExtractor.new(model_class)
          rule_where_conditions = extract_multiple_conditions(conditions_extractor, [rule])
          joins_hash, left_joins_hash = extract_joins_from_rule(rule)
          sub_query_for_rules_and_join_hashes(rule_where_conditions, joins_hash, left_joins_hash)
        end

        def sub_query_for_rules_and_join_hashes(rule_where_conditions, joins_hash, left_joins_hash)
          model_class
            .joins(joins_hash)
            .left_joins(left_joins_hash)
            .where(rule_where_conditions)
        end

        def extract_joins_from_rule(rule)
          joins = {}
          left_joins = {}

          extra_joins_recursive([], rule.conditions, joins, left_joins)
          [joins, left_joins]
        end

        def extra_joins_recursive(current_path, conditions, joins, left_joins)
          conditions.each do |key, value|
            if value.is_a?(Hash)
              current_path << key
              extra_joins_recursive(current_path, value, joins, left_joins)
              current_path.pop
            else
              extra_joins_recursive_merge_joins(current_path, value, joins, left_joins)
            end
          end
        end

        def extra_joins_recursive_merge_joins(current_path, value, joins, left_joins)
          hash_joins = current_path_to_hash(current_path)

          if value.nil?
            left_joins.deep_merge!(hash_joins)
          else
            joins.deep_merge!(hash_joins)
          end
        end

        # Converts an array like [:child, :grand_child] into a hash like {child: {grand_child: {}}
        def current_path_to_hash(current_path)
          hash_joins = {}
          current_hash_joins = hash_joins

          current_path.each do |path_part|
            new_hash = {}
            current_hash_joins[path_part] = new_hash
            current_hash_joins = new_hash
          end

          hash_joins
        end
      end
    end
  end
end
