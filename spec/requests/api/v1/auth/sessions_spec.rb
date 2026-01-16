require 'rails_helper'

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let!(:user) { FactoryBot.create(:user, email: "test@example.com", password: "password123") }

  describe "POST /api/v1/auth/login" do
    context "with valid credentials" do
      it "returns a JWT token" do
        post "/api/v1/auth/login", params: {
          user: {
            email: user.email,
            password: "password123"
          }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response["token"]).to be_present
        expect(json_response["user"]["email"]).to eq(user.email)
      end

      it "is case-insensitive for email" do
        post "/api/v1/auth/login", params: {
          user: {
            email: "TEST@EXAMPLE.COM",
            password: "password123"
          }
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized for wrong password" do
        post "/api/v1/auth/login", params: {
          user: {
            email: user.email,
            password: "wrongpassword"
          }
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to eq("Invalid email or password")
      end

      it "returns unauthorized for non-existent email" do
        post "/api/v1/auth/login", params: {
          user: {
            email: "nonexistent@example.com",
            password: "password123"
          }
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "returns success message" do
      token = Authentication::JsonWebToken.encode(user_id: user.id)
      
      delete "/api/v1/auth/logout", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(json_response["message"]).to eq("Logout successful")
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end