class Users::RegistrationsController < Devise::RegistrationsController

  def create
    # Validate access code before creating user
    unless valid_access_code?(params[:user][:access_code], params[:user][:role])
      resource = build_resource(sign_up_params)
      resource.errors.add(:access_code, "is invalid for the selected role")
      render :new and return
    end

    # Set the role based on access code validation
    params[:user][:role] = determine_role_from_access_code(params[:user][:access_code])
    
    # Set allowed grade based on access code
    params[:user][:allowed_grade] = determine_allowed_grade_from_access_code(params[:user][:access_code])

    super
  end

  private

  def valid_access_code?(access_code, role)
    case role
    when 'student'
      ['ai-tutor-93105', 'grand-public-school-daltonganj'].include?(access_code)
    when 'admin'
      access_code == 'admin@93105M'
    else
      false
    end
  end

  def determine_role_from_access_code(access_code)
    case access_code
    when 'ai-tutor-93105', 'grand-public-school-daltonganj'
      'student'
    when 'admin@93105M'
      'admin'
    else
      'student' # Default fallback
    end
  end

  def determine_allowed_grade_from_access_code(access_code)
    case access_code
    when 'ai-tutor-93105'
      nil # No grade restriction - access to all grades
    when 'grand-public-school-daltonganj'
      '8' # Only Grade 8 access
    else
      nil # Default fallback
    end
  end
end
