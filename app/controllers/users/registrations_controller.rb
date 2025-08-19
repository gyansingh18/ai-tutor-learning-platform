class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role, :access_code])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end

  def create
    # Validate access code before creating user
    unless valid_access_code?(params[:user][:access_code], params[:user][:role])
      resource = build_resource(sign_up_params)
      resource.errors.add(:access_code, "is invalid for the selected role")
      render :new and return
    end

    # Set the role based on access code validation
    params[:user][:role] = determine_role_from_access_code(params[:user][:access_code])
    
    super
  end

  private

  def valid_access_code?(access_code, role)
    case role
    when 'student'
      access_code == 'ai-tutor-93105'
    when 'admin'
      access_code == 'admin@93105M'
    else
      false
    end
  end

  def determine_role_from_access_code(access_code)
    case access_code
    when 'ai-tutor-93105'
      'student'
    when 'admin@93105M'
      'admin'
    else
      'student' # Default fallback
    end
  end
end
