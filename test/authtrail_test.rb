require_relative "test_helper"

class AuthTrailTest < ActionDispatch::IntegrationTest
  def setup
    User.delete_all
    LoginActivity.delete_all
  end

  def test_success
    user = User.create!(email: "test@example.org")
    post users_sign_in_url, params: {user: {email: "test@example.org"}}
    assert_response :success

    assert_equal 1, LoginActivity.count
    login_activity = LoginActivity.last
    assert_equal "user", login_activity.scope
    assert_equal "password_strategy", login_activity.strategy
    assert_equal "test@example.org", login_activity.identity
    assert login_activity.success
    assert_nil login_activity.failure_reason
    assert_equal user, login_activity.user
    assert_equal "users#sign_in", login_activity.context
  end

  def test_failure
    post users_sign_in_url, params: {user: {email: "test@example.org"}}
    assert_response :unauthorized

    assert_equal 1, LoginActivity.count
    login_activity = LoginActivity.last
    assert_equal "user", login_activity.scope
    assert_equal "password_strategy", login_activity.strategy
    assert_equal "test@example.org", login_activity.identity
    refute login_activity.success
    assert_equal "Could not sign in", login_activity.failure_reason
    assert_nil login_activity.user
    assert_equal "users#sign_in", login_activity.context
  end
end
