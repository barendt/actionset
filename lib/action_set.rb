# frozen_string_literal: true

require 'rails/railtie'
require 'active_support/core_ext/object/blank'
require 'active_support/lazy_load_hooks'
require 'active_set'

require_relative './action_set/attribute_value'
require_relative './action_set/helpers/helper_methods'

module ActionSet
  # Ensure that the HelperMethods are callable from the Rails view-layer
  ActiveSupport.on_load :action_view do
    ::ActionView::Base.send :include, Helpers::HelperMethods
  end

  module ClassMethods
  end

  module InstanceMethods
    def process_set(set)
      paginate_set(sort_set(filter_set(ensure_active_set(set))))
    end

    def filter_set(set)
      active_set = ensure_active_set(set)
      active_set = active_set.filter(filter_instructions_for(set)) if filter_params.any?
      active_set
    end

    def sort_set(set)
      active_set = ensure_active_set(set)
      active_set = active_set.sort(sort_params) if sort_params.any?
      active_set
    end

    # TODO: should we move the default value setting to this layer,
    # and have ActiveSet require instructions for pagination?
    def paginate_set(set)
      active_set = ensure_active_set(set)
      active_set = active_set.paginate(paginate_instructions)
      active_set
    end

    def export_set(set)
      return send_file(set, export_set_options(request.format)) if set.is_a?(String) && File.file?(set)

      active_set = ensure_active_set(set)
      exported_data = active_set.export(export_instructions)
      send_data(exported_data, export_set_options(request.format))
    end

    private

    def filter_instructions_for(set)
      filter_params.flatten_keys.reject { |_, v| v.try(:empty?) }.each_with_object({}) do |(keypath, value), memo|
        typecast_value = if value.respond_to?(:each)
                           value.map { |v| filter_typecasted_value_for(keypath, v, set) }
                         else
                           filter_typecasted_value_for(keypath, value, set)
                         end

        memo[keypath] = typecast_value
      end
    end

    def filter_typecasted_value_for(keypath, value, set)
      instruction = ActiveSet::AttributeInstruction.new(keypath, value)
      item_with_value = set.find { |i| !instruction.value_for(item: i).nil? }
      item_value = instruction.value_for(item: item_with_value)
p ['typecasting', instruction, set.count, item_with_value, item_value]
      ActionSet::AttributeValue.new(value)
                               .cast(to: item_value.class)
    end

    def paginate_instructions
      paginate_params.transform_values(&:to_i)
    end

    def export_instructions
      {}.tap do |struct|
        struct[:format] = export_params[:format] || request.format.symbol
        columns_params = export_params[:columns]&.map do |column|
          Hash[column&.map do |k, v|
            is_literal_value = ->(key) { key.to_s == 'value*' }
            key = is_literal_value.call(k) ? 'value' : k
            val = is_literal_value.call(k) ? send(v) : v
            [key, val]
          end]
        end

        struct[:columns] = if columns_params&.any?
                             columns_params
                           elsif respond_to?(:export_set_columns, true)
                             send(:export_set_columns)
                           else
                             [{}]
                           end
      end
    end

    def filter_params
      params.fetch(:filter, {}).to_unsafe_hash
    end

    def sort_params
      params.fetch(:sort, {}).to_unsafe_hash
    end

    def paginate_params
      params.fetch(:paginate, {}).to_unsafe_hash
    end

    def export_params
      params.fetch(:export, {}).to_unsafe_hash
    end

    def export_set_options(format)
      {}.tap do |opts|
        opts[:type] = format.to_s
        opts[:filename] = "#{Time.zone.now.strftime('%Y%m%d_%H:%M:%S')}.#{format.symbol}"
        opts[:disposition] = :inline if %w[development test].include?(Rails.env.to_s)
      end
    end

    def ensure_active_set(set)
      return set if set.is_a?(ActiveSet)

      ActiveSet.new(set)
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
