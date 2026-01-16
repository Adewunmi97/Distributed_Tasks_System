# app/controllers/concerns/authenticatable.rb

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    attr_reader :current_user
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    
    if token.blank?
      render_unauthorized("Missing authentication token")
      return
    end

    payload = Authentication::JsonWebToken.decode(token)
    
    if payload.nil?
      render_unauthorized("Invalid or expired token")
      return
    end

    @current_user = User.find_by(id: payload[:user_id])
    
    if @current_user.nil?
      render_unauthorized("User not found")
      return
    end
  rescue StandardError => e
    Rails.logger.error("Authentication Error: #{e.message}")
    render_unauthorized("Authentication failed")
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil if header.blank?
    
    header.split(" ").last if header.start_with?("Bearer ")
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end
end