require_relative "test_helper"

class AuthTrailTest < ActionDispatch::IntegrationTest
  def setup
    User.delete_all
    LoginActivity.delete_all
  end

  def test_success
    user = User.create!(email: "test@example.org", password: "secret")
    post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
    assert_response :found

    assert_equal 1, LoginActivity.count
    login_activity = LoginActivity.last
    assert_equal "user", login_activity.scope
    assert_equal "database_authenticatable", login_activity.strategy
    assert_equal "test@example.org", login_activity.identity
    assert login_activity.success
    assert_nil login_activity.failure_reason
    assert_equal user, login_activity.user
    assert_equal "devise/sessions#create", login_activity.context
  end

  def test_failure
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    assert_response :unauthorized

    assert_equal 1, LoginActivity.count
    login_activity = LoginActivity.last
    assert_equal "user", login_activity.scope
    assert_equal "database_authenticatable", login_activity.strategy
    assert_equal "test@example.org", login_activity.identity
    refute login_activity.success
    assert_equal "not_found_in_database", login_activity.failure_reason
    assert_nil login_activity.user
    assert_equal "devise/sessions#create", login_activity.context
  end

  def test_exclude_method
    post user_session_url, params: {user: {email: "exclude@example.org", password: "secret"}}
    assert_empty LoginActivity.all
  end

  def test_geocode_job_enqueued
    skip if Rails::VERSION::MAJOR < 6

    post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
    assert_enqueued_with(job: AuthTrail::GeocodeJob, args: [LoginActivity.last])
  end
end
