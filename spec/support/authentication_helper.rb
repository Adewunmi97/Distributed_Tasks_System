module AuthenticationHelper
  def auth_headers(user)
    token = Authentication::JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end