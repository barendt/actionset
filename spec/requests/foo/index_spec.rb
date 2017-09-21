# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /foos', type: :request do
  let!(:foo) { FactoryGirl.create(:foo) }
  let!(:others) { FactoryGirl.create_list(:foo, 2) }
  let(:results) { JSON.parse(response.body) }
  let(:results_ids) { results.map { |f| f['id'] } }

  before(:each) do
    get foos_path, params: params, headers: {}
  end

  context 'with no params' do
    let(:params) do
      {}
    end

    it { expect(response).to have_http_status :ok }
    it { expect(results_ids).to eq [1, 2, 3] }
  end

  context 'with filter params' do
  end

  context 'with sort params' do
    context 'on the base object' do
      let(:params) do
        { sort: { string: :asc } }
      end
      let(:expected_ids) do
        Foo.order(string: :asc)
           .pluck(:id)
      end

      it { expect(response).to have_http_status :ok }
      it { expect(results_ids).to eq expected_ids }
    end

    context 'on an associated object' do
      let(:params) do
        { sort: { assoc: { string: :asc } } }
      end
      let(:expected_ids) do
        Foo.joins(:assoc)
           .merge(Assoc.order(string: :asc))
           .pluck(:id)
      end

      it { expect(response).to have_http_status :ok }
      it { expect(results_ids).to eq expected_ids }
    end
  end
end
