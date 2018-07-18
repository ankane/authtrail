require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

if ENV["VERBOSE"]
  ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
end

ActiveRecord::Migration.create_table :users do |t|
  t.string :email
  t.string :encrypted_password
  t.datetime :reset_password_sent_at
end

ActiveRecord::Migration.create_table :account_activities do |t|
  t.string :activity_type
  t.string :scope
  t.string :strategy
  t.string :identity
  t.boolean :success
  t.string :failure_reason
  t.references :user, polymorphic: true
  t.string :context
  t.string :ip
  t.text :user_agent
  t.text :referrer
  t.string :city
  t.string :region
  t.string :country
  t.datetime :created_at
end

class User < ActiveRecord::Base
  include AuthTrail::Model
end

class AccountActivity < ActiveRecord::Base
  belongs_to :user, polymorphic: true, optional: true
end
