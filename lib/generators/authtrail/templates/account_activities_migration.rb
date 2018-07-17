class <%= migration_class_name %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :account_activities do |t|
      t.string :activity_type
      t.text :scope
      t.text :strategy
      t.string :identity
      t.boolean :success
      t.text :failure_reason
      t.references :user, polymorphic: true
      t.text :context
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.text :city
      t.text :region
      t.text :country
      t.datetime :created_at
    end

    add_index :account_activities, :identity
    add_index :account_activities, :ip
  end
end
