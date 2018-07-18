require_relative "test_helper"

class AuthTrailTest < Minitest::Test
  def setup
    AccountActivity.delete_all
  end

  def test_email_change
    user = create_user
    user.email = "test2@example.org"
    user.save!

    assert_equal ["email_change"], AccountActivity.all.map(&:activity_type)
  end

  def test_password_change
    user = create_user
    user.encrypted_password = "secret2"
    user.save!

    assert_equal ["password_change"], AccountActivity.all.map(&:activity_type)
  end

  def test_password_reset_request
    user = create_user
    user.reset_password_sent_at = Time.now
    user.save!

    assert_equal ["password_reset_request"], AccountActivity.all.map(&:activity_type)
  end

  def test_password_reset_request_empty
    user = create_user(reset_password_sent_at: Time.now)
    user.reset_password_sent_at = nil
    user.save!
    assert_equal [], AccountActivity.all.map(&:activity_type)
  end

  private

  def create_user(attributes = {})
    User.create!({
      email: "test@example.org",
      encrypted_password: "secret"
    }.merge(attributes))
  end
end
