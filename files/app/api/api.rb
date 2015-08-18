require 'doorkeeper/grape/helpers'

class API < Grape::API
  version 'v1', using: :path, vendor: 'Rawfish'
  format :json
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

end

