module AuthTrail
  class Activity < ActiveRecord::Base
    self.table_name = "authtrail_activities"

    belongs_to :user, polymorphic: true, optional: true
  end
end
