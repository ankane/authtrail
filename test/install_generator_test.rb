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
  
  def test_uuid_option
    run_generator ['--encryption=none', '--uuid']
    assert_migration 'db/migrate/create_login_activities.rb', /t.references :user, type: :uuid, polymorphic: true/
  end

  def test_default_id_type
    run_generator ['--encryption=none']
    assert_migration 'db/migrate/create_login_activities.rb', /t.references :user, polymorphic: true/
  end
end
