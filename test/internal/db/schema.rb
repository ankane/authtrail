ActiveRecord::Schema.define do
  create_table :login_activities do |t|
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
    t.float :latitude
    t.float :longitude
    t.datetime :created_at
  end

  create_table :users do |t|
    t.string :email
    t.string :encrypted_password
    t.string :reset_password_token
    t.datetime :reset_password_sent_at
    t.string :confirmation_token
    t.datetime :confirmed_at
    t.datetime :confirmation_sent_at
    t.integer :failed_attempts, default: 0, null: false
    t.string :unlock_token
    t.datetime :locked_at
  end
end
