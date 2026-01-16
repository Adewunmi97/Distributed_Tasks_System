module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!, only: [:create]

        def create
          user = User.find_by(email: login_params[:email]&.downcase)

          if user&.authenticate(login_params[:password])
            token = Authentication::JsonWebToken.encode(user_id: user.id)
            
            render json: {
              message: "Login successful",
              user: user_response(user),
              token: token
            }, status: :ok
          else
            render json: {
              error: "Invalid email or password"
            }, status: :unauthorized
          end
        end

        def destroy
          # Since we're using stateless JWT, logout is handled client-side
          # by removing the token. We just return a success message.
          render json: {
            message: "Logout successful"
          }, status: :ok
        end

        private

        def login_params
          params.require(:user).permit(:email, :password)
        end

        def user_response(user)
          {
            id: user.id,
            email: user.email,
            role: user.role
          }
        end
      end
    end
  end
end