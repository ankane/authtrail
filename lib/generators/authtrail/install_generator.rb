# taken from https://github.com/collectiveidea/audited/blob/master/lib/generators/audited/install_generator.rb
require "rails/generators"
require "rails/generators/migration"
require "active_record"
require "rails/generators/active_record"

module Authtrail
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      # Implement the required interface for Rails::Generators::Migration.
      def self.next_migration_number(dirname) #:nodoc:
        next_migration_number = current_migration_number(dirname) + 1
        if ::ActiveRecord::Base.timestamped_migrations
          [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
        else
          "%.3d" % next_migration_number
        end
      end

      def copy_migration
        migration_template "login_activities_migration.rb", "db/migrate/create_login_activities.rb", migration_version: migration_version
      end

      def generate_model
        template "login_activity_model.rb", "app/models/login_activity.rb", model_base_class: model_base_class, ar_optional_flag: ar_optional_flag
      end

      def migration_version
        if rails5?
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end
      end

      def rails5?
        Rails::VERSION::MAJOR >= 5
      end

      def model_base_class
        rails5? ? 'ApplicationRecord' : 'ActiveRecord::Base'
      end

      def ar_optional_flag
        if rails5?
          ', optional: true'
        end
      end
    end
  end
end
