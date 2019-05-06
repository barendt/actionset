# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /things?sort', type: :request do
  before(:all) do
    @thing_1 = FactoryBot.create(:thing, string: 'a', integer: 1, boolean: true,
                                 date: 1.day.from_now.to_date, datetime: 1.day.from_now.to_datetime,
                                 decimal: 1.1, float: 1.1, time: 1.hour.from_now.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'ra', integer: 9))
    @thing_2 = FactoryBot.create(:thing, string: 'a', integer: 2, boolean: true,
                                 date: 1.day.ago.to_date, datetime: 1.day.ago.to_datetime,
                                 decimal: 2.2, float: 2.2, time: 2.hours.from_now.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'ra', integer: 8))
    @thing_3 = FactoryBot.create(:thing, string: 'z', integer: 1, boolean: true,
                                 date: 1.day.from_now.to_date, datetime: 1.day.from_now.to_datetime,
                                 decimal: 1.1, float: 1.1, time: 1.hour.ago.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'rz', integer: 9))
    @thing_4 = FactoryBot.create(:thing, string: 'z', integer: 2, boolean: true,
                                 date: 1.day.ago.to_date, datetime: 1.day.ago.to_datetime,
                                 decimal: 2.2, float: 2.2, time: 2.hours.ago.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'rz', integer: 8))
    @thing_5 = FactoryBot.create(:thing, string: 'A', integer: 1, boolean: false,
                                 date: 1.week.from_now.to_date, datetime: 1.week.from_now.to_datetime,
                                 decimal: 1.1, float: 1.1, time: 1.hour.from_now.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'rA', integer: 9))
    @thing_6 = FactoryBot.create(:thing, string: 'A', integer: 2, boolean: false,
                                 date: 1.week.ago.to_date, datetime: 1.week.ago.to_datetime,
                                 decimal: 2.2, float: 2.2, time: 2.hours.from_now.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'rA', integer: 8))
    @thing_7 = FactoryBot.create(:thing, string: 'Z', integer: 1, boolean: false,
                                 date: 1.week.from_now.to_date, datetime: 1.week.from_now.to_datetime,
                                 decimal: 1.1, float: 1.1, time: 1.hour.ago.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'rZ', integer: 9))
    @thing_8 = FactoryBot.create(:thing, string: 'Z', integer: 2, boolean: false,
                                 date: 1.week.ago.to_date, datetime: 1.week.ago.to_datetime,
                                 decimal: 2.2, float: 2.2, time: 2.hours.ago.to_time.to_s[12..-1],
                                 only: FactoryBot.create(:only, string: 'rZ', integer: 8))
    @active_set = ActiveSet.new(Thing.all)
  end

  context '.json' do
    let(:result) { JSON.parse(response.body) }

    before(:each) do
      get things_path(format: :json),
          params: { sort: instructions }
    end

    ApplicationRecord::SORTABLE_TYPES.each do |type|
      all_possible_sort_instructions_for(type).sample do |instruction|
        context instruction do
          it_should_behave_like 'a sorted collection', instruction do
            let(:result) { @active_set.sort(instruction) }
          end
        end
      end
    end

    ApplicationRecord::SORTABLE_TYPES.combination(2).each do |type_1, type_2|
      all_possible_sort_instruction_combinations_for(type_1, type_2).sample do |instructions|
        context instructions do
          it_should_behave_like 'a sorted collection', instructions do
            let(:result) { @active_set.sort(instructions) }
          end
        end
      end
    end
  end
end
