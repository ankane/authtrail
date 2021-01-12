require_relative "test_helper"

class AuthTrailTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    User.delete_all
    AuthTrail::Activity.delete_all
  end

  def test_sign_in_success
    user = create_user
    post user_session_url, params: {user: {email: "test@example.org", password: "secret"}}
    assert_response :found

    assert_equal 1, AuthTrail::Activity.count
    activity = AuthTrail::Activity.last
    assert_equal "sign_in_success", activity.activity_type
    assert_equal "user", activity.scope
    assert_equal "database_authenticatable", activity.strategy
    assert_equal "test@example.org", activity.identity
    assert activity.success
    assert_nil activity.failure_reason
    assert_equal user, activity.user
    assert_equal "devise/sessions#create", activity.context
  end

  def test_sign_in_failure
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    assert_response :unauthorized

    assert_equal 1, AuthTrail::Activity.count
    activity = AuthTrail::Activity.last
    assert_equal "sign_in_failure", activity.activity_type
    assert_equal "user", activity.scope
    assert_equal "database_authenticatable", activity.strategy
    assert_equal "test@example.org", activity.identity
    refute activity.success
    assert_equal "not_found_in_database", activity.failure_reason
    assert_nil activity.user
    assert_equal "devise/sessions#create", activity.context
  end

  def test_sign_out
    user = create_user
    sign_in user
    delete destroy_user_session_url
    assert_response :found

    activity = AuthTrail::Activity.last
    assert_equal "sign_out", activity.activity_type
    assert_equal user, activity.user
    assert_equal "devise/sessions#destroy", activity.context
  end

  def test_change_email
    user = create_user
    sign_in user
    patch user_registration_url, params: {user: {email: "new@example.org", current_password: "secret"}}
    assert_response :found

    activity = AuthTrail::Activity.last
    assert_equal "email_change", activity.activity_type
    assert_equal user, activity.user
    assert_equal "devise/registrations#update", activity.context
  end

  def test_change_password
    user = create_user
    sign_in user
    # confirmation not needed as long as confirmation field not present
    patch user_registration_url, params: {user: {password: "secret2", current_password: "secret"}}
    assert_response :found

    activity = AuthTrail::Activity.last
    assert_equal "password_change", activity.activity_type
    assert_equal user, activity.user
    assert_equal "devise/registrations#update", activity.context
  end

  def test_reset_password
    user = create_user
    post user_password_url, params: {user: {email: "test@example.org"}}
    assert_response :found

    activity = AuthTrail::Activity.last
    assert_equal "password_reset_request", activity.activity_type
    assert_equal user, activity.user
    assert_equal "devise/passwords#create", activity.context
  end

  def test_confirm
    post user_registration_url, params: {user: {email: "test@example.org", password: "secret"}}
    get user_confirmation_url, params: {confirmation_token: last_token}

    user = User.last
    activity = AuthTrail::Activity.find_by!(activity_type: "confirm")
    assert_equal user, activity.user
    assert_equal "devise/confirmations#show", activity.context
  end

  def test_lock
    user = create_user
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}

    activity = AuthTrail::Activity.find_by!(activity_type: "lock")
    assert_equal user, activity.user
    assert_equal "devise/sessions#create", activity.context
  end

  def test_unlock
    user = create_user
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    get user_unlock_url, params: {unlock_token: last_token}
    assert_response :found

    activity = AuthTrail::Activity.find_by!(activity_type: "unlock")
    assert_equal user, activity.user
    assert_equal "devise/unlocks#show", activity.context
  end

  def test_change_email_record
    user = create_user
    user.update!(email: "new@example.org")

    activity = AuthTrail::Activity.last
    assert_equal "email_change", activity.activity_type
    assert_equal user, activity.user
    assert_nil activity.context
  end

  def test_change_password_record
    user = create_user
    user.update!(password: "secret2")

    activity = AuthTrail::Activity.last
    assert_equal "password_change", activity.activity_type
    assert_equal user, activity.user
    assert_nil activity.context
  end

  def test_exclude_method
    post user_session_url, params: {user: {email: "exclude@example.org", password: "secret"}}
    assert_empty AuthTrail::Activity.all
  end

  private

  def create_user(attributes = {})
    User.create!({email: "test@example.org", password: "secret", confirmed_at: Time.now}.merge(attributes))
  end

  def last_token
    m = /token=([A-Za-z0-9\-_]+)/.match(ActionMailer::Base.deliveries.last.body.to_s)
    m[1] if m
  end
end
