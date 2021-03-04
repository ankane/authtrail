class LoginActivity < ApplicationRecord
  belongs_to :user, polymorphic: true, optional: true

  encrypts :identity, :ip
  blind_index :identity, :ip

  before_save :reduce_precision

  # reduce precision to city level to protect IP
  def reduce_precision
    self.latitude = latitude&.round(1) if try(:latitude_changed?)
    self.longitude = longitude&.round(1) if try(:longitude_changed?)
  end
end
