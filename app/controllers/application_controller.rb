class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role, :access_code, :allowed_grade])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end

  # Custom redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    # Force a full page reload by redirecting to root with a cache-busting parameter
    root_path(v: Time.current.to_i)
  end
end
