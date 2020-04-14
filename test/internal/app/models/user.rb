class User < ActiveRecord::Base
  devise :database_authenticatable
end
