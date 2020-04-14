class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :confirmable, :lockable, :trailable
end
