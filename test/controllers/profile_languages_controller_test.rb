require "test_helper"

class ProfileLanguagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get profile_languages_create_url
    assert_response :success
  end

  test "should get update" do
    get profile_languages_update_url
    assert_response :success
  end

  test "should get destroy" do
    get profile_languages_destroy_url
    assert_response :success
  end
end
