require 'doorkeeper/grape/helpers'

class API < Grape::API
  prefix :api
  version 'v1', using: :path, vendor: 'Rawfish'
  format :json
  formatter :json, Grape::Formatter::Rabl
  default_format :json

  helpers Doorkeeper::Grape::Helpers

  before do
    header 'Content-Type', 'application/json; charset=utf-8'
    doorkeeper_authorize!
  end

  resource :ping do
    desc "ping pong"
    get do
      { response: "pong" }
    end
  end

  resource :users do
    desc "users list"
    get nil, rabl: 'v1/users/index' do
      @users = User.order("id desc")
    end

    desc "user detail"
    get ':id', rabl: 'v1/users/show' do
      @user = User.find params[:id]
    end
  end

end
