module Api
  module V1
    class TasksController < ApplicationController
      before_action :authenticate_user!

      def index
        tasks = Task.all
        render json: tasks
      end
    end
  end
end
