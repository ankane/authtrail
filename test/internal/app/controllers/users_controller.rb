class UsersController < ActionController::Base
  def sign_in
    request.env["warden"].authenticate!(scope: :user)
  end
end
