require_relative "test_helper"

require "rails/generators/test_case"
require "generators/authtrail/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Authtrail::Generators::InstallGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def test_encryption_lockbox
    run_generator ["--encryption=lockbox"]
    assert_file "config/initializers/authtrail.rb", /AuthTrail.geocode = false/
    assert_file "app/models/login_activity.rb", /has_encrypted :identity, :ip/
    assert_migration "db/migrate/create_login_activities.rb", /t.text :identity_ciphertext/
  end

  def test_encryption_activerecord
    run_generator ["--encryption=activerecord"]
    assert_file "config/initializers/authtrail.rb", /AuthTrail.geocode = false/
    assert_file "app/models/login_activity.rb", /encrypts :identity, deterministic: true/
    assert_migration "db/migrate/create_login_activities.rb", /t.string :identity, index: true/
  end

  def test_encryption_none
    run_generator ["--encryption=none"]
    assert_file "config/initializers/authtrail.rb", /AuthTrail.geocode = false/
    assert_file "app/models/login_activity.rb", /LoginActivity < ApplicationRecord/
    assert_migration "db/migrate/create_login_activities.rb", /t.string :identity, index: true/
  end

  def test_primary_key_type
    with_generator_options({active_record: {primary_key_type: :uuid}}) do
      run_generator ["--encryption=lockbox"]
    end
    assert_migration "db/migrate/create_login_activities.rb", /id: :uuid/
    assert_migration "db/migrate/create_login_activities.rb", /type: :uuid/
  end

  private

  def with_generator_options(value)
    previous_value = Rails.configuration.generators.options
    begin
      Rails.configuration.generators.options = value
      yield
    ensure
      Rails.configuration.generators.options = previous_value
    end
  end
end
