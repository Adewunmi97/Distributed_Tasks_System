module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        skip_before_action :authenticate_user!, only: [ :create ]

        def create
          user = User.new(registration_params)

          if user.save
            token = Authentication::JsonWebToken.encode(user_id: user.id)

            render json: {
              message: "User registered successfully",
              user: user_response(user),
              token: token
            }, status: :created
          else
            render json: {
              error: "Registration failed",
              details: user.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def registration_params
          params.require(:user).permit(:email, :password, :password_confirmation, :name)
        end

        def user_response(user)
          {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at
          }
        end
      end
    end
  end
end
