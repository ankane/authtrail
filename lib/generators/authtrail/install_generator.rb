require "rails/generators/active_record"

module Authtrail
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      class_option :lockbox, type: :boolean

      def copy_migration
        migration_template "login_activities_migration.rb", "db/migrate/create_login_activities.rb", migration_version: migration_version
      end

      def copy_templates
        template "initializer.rb", "config/initializers/authtrail.rb"
      end

      def generate_model
        if lockbox?
          template "model_lockbox.rb", "app/models/login_activity.rb"
        else
          template "model.rb", "app/models/login_activity.rb"
        end
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def identity_column
        if lockbox?
          "t.text :identity_ciphertext\n      t.string :identity_bidx, index: true"
        else
          "t.string :identity, index: true"
        end
      end

      def ip_column
        if lockbox?
          "t.text :ip_ciphertext\n      t.string :ip_bidx, index: true"
        else
          "t.string :ip, index: true"
        end
      end

      def lockbox?
        options[:lockbox]
      end
    end
  end
end
