ActiveRecord::Schema.define do
  create_table :login_activities do |t|
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

    # app-specific fields
    t.string :request_id
  end

  create_table :users do |t|
    t.string :email
    t.string :encrypted_password
  end
end
