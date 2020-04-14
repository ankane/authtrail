class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :lockable, :trailable
end
