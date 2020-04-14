require_relative "test_helper"

class AuthTrailTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    LoginActivity.delete_all
    User.delete_all
  end

  def test_sign_in_success
    user = create_user
    post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
    assert_response :found

    assert_equal 1, LoginActivity.count
    login_activity = LoginActivity.last
    assert_equal "sign_in", login_activity.activity_type
    assert_equal "user", login_activity.scope
    assert_equal "database_authenticatable", login_activity.strategy
    assert_equal "test@example.org", login_activity.identity
    assert login_activity.success
    assert_nil login_activity.failure_reason
    assert_equal user, login_activity.user
    assert_equal "devise/sessions#create", login_activity.context
  end

  def test_sign_in_failure
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    assert_response :unauthorized

    assert_equal 1, LoginActivity.count
    login_activity = LoginActivity.last
    assert_equal "sign_in", login_activity.activity_type
    assert_equal "user", login_activity.scope
    assert_equal "database_authenticatable", login_activity.strategy
    assert_equal "test@example.org", login_activity.identity
    refute login_activity.success
    assert_equal "not_found_in_database", login_activity.failure_reason
    assert_nil login_activity.user
    assert_equal "devise/sessions#create", login_activity.context
  end

  def test_sign_out
    user = create_user
    sign_in user
    delete destroy_user_session_url
    assert_response :found

    login_activity = LoginActivity.last
    assert_equal "sign_out", login_activity.activity_type
    assert_equal user, login_activity.user
    assert_equal "devise/sessions#destroy", login_activity.context
  end

  private

  def create_user
    User.create!(email: "test@example.org", password: "secret")
  end
end
