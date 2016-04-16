module Api
  module V1
    class UsersController < ApiController
      skip_before_action :auth_with_token!, only: [:create]

      def create
        if correct_secret_api_key?
          user = User.new(user_params)
          if user.save
            ask_email_confirmation(user)
            render json: user, status: :created
          else
            render_error(user.errors.full_messages[0], :unprocessable_entity)
          end
        end
      end

      def destroy
        current_user.notes.destroy_all
        current_user.destroy
        head :no_content
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end

      def correct_secret_api_key?
        if request.headers['Authorization'] == ENV['SECRET_API_KEY']
          true
        else
          head :unauthorized
          false
        end
      end

      def ask_email_confirmation(user)
        user.regenerate_conf_token
        user.conf_sent_at = DateTime.current
        user.save
        UserMailer.ask_email_confirmation(user).deliver
      end
    end
  end
end
