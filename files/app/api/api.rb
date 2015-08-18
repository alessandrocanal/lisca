require 'doorkeeper/grape/helpers'

class API < Grape::API
  version 'v1', using: :path, vendor: 'Rawfish'
  format :json
  formatter :json, Grape::Formatter::Jbuilder
  default_format :json
  prefix :api

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
    desc "user detail"
    get ':id', jbuilder: 'v1/users/show' do
      @user = User.find params[:id]
    end
  end
end

