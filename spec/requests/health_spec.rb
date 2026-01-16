require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'returns ok status' do
      get '/health'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['status']).to eq('ok')
      expect(json['database']).to eq('connected')
      expect(json['environment']).to eq('test')
    end
  end
end
