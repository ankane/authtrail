require "rails/generators/active_record"

module Authtrail
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      def copy_migration
        migration_template "login_activities_migration.rb", "db/migrate/create_login_activities.rb", migration_version: migration_version
      end

      def generate_model
        template "login_activity_model.rb", "app/models/login_activity.rb"
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
