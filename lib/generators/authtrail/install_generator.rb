require "rails/generators/active_record"

module Authtrail
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      class_option :encryption, type: :string
      # deprecated
      class_option :lockbox, type: :boolean

      def copy_migration
        encryption # ensure valid
        migration_template "login_activities_migration.rb", "db/migrate/create_login_activities.rb", migration_version: migration_version
      end

      def copy_templates
        template "initializer.rb", "config/initializers/authtrail.rb"
      end

      def generate_model
        case encryption
        when "lockbox"
          template "model_lockbox.rb", "app/models/login_activity.rb", lockbox_method: lockbox_method
        when "activerecord"
          template "model_activerecord.rb", "app/models/login_activity.rb"
        else
          template "model_none.rb", "app/models/login_activity.rb"
        end
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def identity_column
        case encryption
        when "lockbox"
          "t.text :identity_ciphertext\n      t.string :identity_bidx, index: true"
        else
          # TODO add limit: 510 for Active Record encryption + MySQL?
          "t.string :identity, index: true"
        end
      end

      def ip_column
        case encryption
        when "lockbox"
          "t.text :ip_ciphertext\n      t.string :ip_bidx, index: true"
        else
          # TODO add limit: 510 for Active Record encryption + MySQL?
          "t.string :ip, index: true"
        end
      end

      # TODO remove default
      def encryption
        case options[:encryption]
        when "lockbox", "activerecord", "none"
          options[:encryption]
        when nil
          if options[:lockbox]
            # TODO deprecation warning
            "lockbox"
          else
            "none"
          end
        else
          abort "Error: encryption must be lockbox, activerecord, or none"
        end
      end

      def lockbox_method
        if defined?(Lockbox::VERSION) && Lockbox::VERSION.to_i < 1
          "encrypts"
        else
          "has_encrypted"
        end
      end
    end
  end
end
