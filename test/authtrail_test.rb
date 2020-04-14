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

  def test_change_email
    user = create_user
    sign_in user
    patch user_registration_url, params: {user: {email: "new@example.org", current_password: "secret"}}
    assert_response :found

    login_activity = LoginActivity.last
    assert_equal "email_change", login_activity.activity_type
    assert_equal user, login_activity.user
    assert_equal "devise/registrations#update", login_activity.context
  end

  def test_change_password
    user = create_user
    sign_in user
    # confirmation not needed as long as confirmation field not present
    patch user_registration_url, params: {user: {password: "secret2", current_password: "secret"}}
    assert_response :found

    login_activity = LoginActivity.last
    assert_equal "password_change", login_activity.activity_type
    assert_equal user, login_activity.user
    assert_equal "devise/registrations#update", login_activity.context
  end

  def test_reset_password
    user = create_user
    post user_password_url, params: {user: {email: "test@example.org"}}
    assert_response :found

    login_activity = LoginActivity.last
    assert_equal "password_reset_request", login_activity.activity_type
    assert_equal user, login_activity.user
    assert_equal "devise/passwords#create", login_activity.context
  end

  def test_confirm
    post user_registration_url, params: {user: {email: "test@example.org", password: "secret"}}
    get user_confirmation_url, params: {confirmation_token: last_token}

    user = User.last
    login_activity = LoginActivity.find_by!(activity_type: "confirm")
    assert_equal user, login_activity.user
    assert_equal "devise/confirmations#show", login_activity.context
  end

  def test_lock
    user = create_user
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}

    login_activity = LoginActivity.find_by!(activity_type: "lock")
    assert_equal user, login_activity.user
    assert_equal "devise/sessions#create", login_activity.context
  end

  def test_unlock
    user = create_user
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    post user_session_url, params: {user: {email: "test@example.org", password: "bad"}}
    get user_unlock_url, params: {unlock_token: last_token}
    assert_response :found

    login_activity = LoginActivity.find_by!(activity_type: "unlock")
    assert_equal user, login_activity.user
    assert_equal "devise/unlocks#show", login_activity.context
  end

  def test_change_email_record
    user = create_user
    user.update!(email: "new@example.org")

    login_activity = LoginActivity.last
    assert_equal "email_change", login_activity.activity_type
    assert_equal user, login_activity.user
    assert_nil login_activity.context
  end

  def test_change_password_record
    user = create_user
    user.update!(password: "secret2")

    login_activity = LoginActivity.last
    assert_equal "password_change", login_activity.activity_type
    assert_equal user, login_activity.user
    assert_nil login_activity.context
  end

  def test_exclude_method
    user = create_user(email: "exclude@example.org")
    user.update!(password: "secret2")
    assert_empty LoginActivity.all
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
