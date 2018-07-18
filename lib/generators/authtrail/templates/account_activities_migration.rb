class <%= migration_class_name %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :account_activities do |t|
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

    add_index :account_activities, :identity
    add_index :account_activities, :ip
  end
end
