# frozen_string_literal: true

require_relative './constants'

class ActiveSet
  module Filtering
    module ActiveRecord
      class AttributeSetInstruction < SimpleDelegator
        include Constants

        def initialize(attribute_instruction, set)
          @attribute_instruction = attribute_instruction
          @set = set
          @operators ||= {}.tap do |_operators|
            AREL_OPERATORS.each { |op| _operators[op[:name]] = op }
            PREDICATE_OPERATORS.each { |op| _operators[op[:name]] = op }
            MATCHING_OPERATORS.each { |op| _operators[op[:name]] = op }
            TIME_OPERATORS.each { |op| _operators[op[:name]] = op }
          end
          super(@attribute_instruction)
        end

        def attribute_model
          return @set.klass if @attribute_instruction.associations_array.empty?
          return @attribute_model if defined? @attribute_model

          @attribute_model = @attribute_instruction
                               .associations_array
                               .reduce(@set) do |obj, assoc|
            obj.reflections[assoc.to_s]&.klass
          end
        end

        def arel_type
          attribute_model
            .columns_hash[@attribute_instruction.attribute]
            .type
        end

        def arel_table
          # This is to work around an bug in ActiveRecord,
          # where BINARY fields aren't found properly when using
          # the `arel_table` class method to build an ARel::Node
          if arel_type == :binary
            Arel::Table.new(attribute_model.table_name)
          else
            attribute_model.arel_table
          end
        end

        def arel_column
          _arel_column = arel_table[@attribute_instruction.attribute]
          return _arel_column.lower if @attribute_instruction.case_insensitive? && arel_type.presence_in(%i[string text])

          _arel_column
        end

        def arel_operator
          return :eq if operator_schema.nil?
          return operator_schema[:operator] if operator_schema

          @attribute_instruction.operator
        end

        def arel_value
p operator_schema
          return operator_schema[:transformer].call(@attribute_instruction.value) if operator_schema&.key?(:transformer)
          return @attribute_instruction.value unless @attribute_instruction.case_insensitive?
          return @attribute_instruction.value.downcase if @attribute_instruction.value.respond_to?(:downcase)
          return @attribute_instruction.value unless @attribute_instruction.value.is_a?(Array)

          @attribute_instruction.value.map do |v|
            next(v) unless v.respond_to?(:downcase)

            v.downcase
          end
        end

        def operator_schema
          instruction_operator = @attribute_instruction.operator
          return @operators[instruction_operator] if @operators.key?(instruction_operator)

p instruction_operator
          @operators.find { |_, schema| schema[:shorthand] == instruction_operator }&.last
        end
      end
    end
  end
end
