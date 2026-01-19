# app/services/authentication/json_web_token.rb

module Authentication
  class JsonWebToken
    SECRET_KEY = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    ALGORITHM = "HS256"
    EXPIRATION_TIME = 24.hours

    class << self
      def encode(payload, exp = EXPIRATION_TIME.from_now)
        payload[:exp] = exp.to_i
        JWT.encode(payload, SECRET_KEY, ALGORITHM)
      end

      def decode(token)
        decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })[0]
        HashWithIndifferentAccess.new(decoded)
      rescue JWT::DecodeError => e
        Rails.logger.error("JWT Decode Error: #{e.message}")
        nil
      end
    end
  end
end
