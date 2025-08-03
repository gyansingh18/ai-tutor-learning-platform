require "test_helper"

class PdfMaterialsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pdf_materials_index_url
    assert_response :success
  end

  test "should get show" do
    get pdf_materials_show_url
    assert_response :success
  end

  test "should get new" do
    get pdf_materials_new_url
    assert_response :success
  end

  test "should get create" do
    get pdf_materials_create_url
    assert_response :success
  end

  test "should get destroy" do
    get pdf_materials_destroy_url
    assert_response :success
  end
end
