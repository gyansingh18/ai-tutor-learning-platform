require "test_helper"

class GradesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get grades_index_url
    assert_response :success
  end

  test "should get show" do
    get grades_show_url
    assert_response :success
  end
end
