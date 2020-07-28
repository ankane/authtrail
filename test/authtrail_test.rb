require_relative "test_helper"

class AuthTrailTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper # for Rails < 6

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

  def test_geocode_true
    assert_enqueued_with(job: AuthTrail::GeocodeJob, queue: "default") do
      post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
    end
  end

  def test_geocode_false
    with_options(geocode: false) do
      post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
      assert_equal 0, enqueued_jobs.size
    end
  end

  def test_job_queue
    with_options(job_queue: :low_priority) do
      assert_enqueued_with(job: AuthTrail::GeocodeJob, queue: "low_priority") do
        post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
      end
    end
  end
end
