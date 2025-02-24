require "rails/generators/active_record"

module Authtrail
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      class_option :encryption, type: :string, required: true
      class_option :uuid, type: :boolean, default: false, desc: 'Use UUID for user_id'

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
          if encryption == "activerecord" && mysql?
            "t.string :identity, limit: 510, index: true"
          else
            "t.string :identity, index: true"
          end
        end
      end

      def ip_column
        case encryption
        when "lockbox"
          "t.text :ip_ciphertext\n      t.string :ip_bidx, index: true"
        else
          "t.string :ip, index: true"
        end
      end

      def encryption
        case options[:encryption]
        when "lockbox", "activerecord", "none"
          options[:encryption]
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

      def mysql?
        adapter =~ /mysql|trilogy/i
      end

      def adapter
        ActiveRecord::Base.connection_db_config.adapter.to_s
      end

      def user_reference
        if options[:uuid]
          't.references :user, type: :uuid, polymorphic: true'
        else
          't.references :user, polymorphic: true'
        end
      end

      def id_type
        options[:uuid] ? ':uuid' : nil
      end
    end
  end
end
