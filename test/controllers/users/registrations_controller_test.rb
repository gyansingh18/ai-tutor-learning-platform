require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should create student with valid student access code" do
    assert_difference('User.count') do
      post user_registration_path, params: {
        user: {
          email: 'student@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'student',
          access_code: 'ai-tutor-93105'
        }
      }
    end

    user = User.last
    assert_equal 'student', user.role
    assert_equal 'student@example.com', user.email
  end

  test "should create admin with valid admin access code" do
    assert_difference('User.count') do
      post user_registration_path, params: {
        user: {
          email: 'admin@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'admin',
          access_code: 'admin@93105M'
        }
      }
    end

    user = User.last
    assert_equal 'admin', user.role
    assert_equal 'admin@example.com', user.email
  end

  test "should not create user with invalid access code" do
    assert_no_difference('User.count') do
      post user_registration_path, params: {
        user: {
          email: 'invalid@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'student',
          access_code: 'invalid-code'
        }
      }
    end

    assert_response :success
  end

  test "should not create user without access code" do
    assert_no_difference('User.count') do
      post user_registration_path, params: {
        user: {
          email: 'noaccess@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'student',
          access_code: ''
        }
      }
    end

    assert_response :success
  end
end
