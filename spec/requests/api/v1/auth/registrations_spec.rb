RSpec.describe "Api::V1::Auth::Registrations", type: :request do
  let(:valid_attributes) do
    {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123",
        name: "New User"
      }
    }
  end
  
  describe "POST /api/v1/auth/register" do
    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/register", params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it "returns a JWT token" do
        post "/api/v1/auth/register", params: valid_attributes

        expect(response).to have_http_status(:created)
        expect(json_response["token"]).to be_present
        expect(json_response["user"]["email"]).to eq("newuser@example.com")
      end

      it "downcases the email" do
        valid_attributes[:user][:email] = "NewUser@EXAMPLE.COM"

        post "/api/v1/auth/register", params: valid_attributes

        expect(User.last.email).to eq("newuser@example.com")
      end
    end

    context "with invalid parameters" do
      it "returns errors for missing email" do
        valid_attributes[:user][:email] = ""

        post "/api/v1/auth/register", params: valid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["details"]).to include(match(/email/i))
      end

      it "returns errors for short password" do
        valid_attributes[:user][:password] = "short"
        valid_attributes[:user][:password_confirmation] = "short"

        post "/api/v1/auth/register", params: valid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["details"]).to include(match(/password/i))
      end

      it "returns errors for duplicate email" do
        FactoryBot.create(:user, email: "existing@example.com")
        valid_attributes[:user][:email] = "existing@example.com"

        post "/api/v1/auth/register", params: valid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["details"]).to include(match(/email.*taken/i))
      end
    end
  end
end
