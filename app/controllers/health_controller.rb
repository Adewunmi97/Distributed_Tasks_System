class HealthController < ApplicationController
  def show
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      database: database_status
    }
  end

  private

  def database_status
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue StandardError => e
    "error: #{e.message}"
  end
end