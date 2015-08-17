require 'rails_helper'

module Helpers
  def set_json_headers_api
    @hd ||= {}
    @hd["HTTP_ACCEPT"] = "application/json"
    @hd["CONTENT_TYPE"] = "application/json"
  end


  def login_api(parms = {})
    @current_user = FactoryGirl.create(:user, :access_token, parms)
    authentication_token = Doorkeeper::AccessToken.where(resource_owner_id: @current_user.id).pluck(:token).first
    @hd ||= {}
    @hd["Authorization"] = "Bearer #{authentication_token}"
    @hd["HTTP_ACCEPT"] = "application/json"
    @hd["CONTENT_TYPE"] = "application/json"
  end
end
