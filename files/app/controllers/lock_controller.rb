class LockController < ApplicationController
  before_action :doorkeeper_authorize!
  before_action :sign_in_user

  private
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
  def sign_in_user
    user = current_resource_owner
    if user && user.active_for_authentication?
      sign_in user, store: false
    end
  end
end
