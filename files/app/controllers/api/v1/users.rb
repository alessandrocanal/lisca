require 'doorkeeper/grape/helpers'

module API
  module V1
    class Users < Grape::API
      version 'v1', using: :path, vendor: 'Rawfish'
      format :json
      formatter :json, Grape::Formatter::Rabl
      default_format :json

      helpers Doorkeeper::Grape::Helpers

      before do
        header 'Content-Type', 'application/json; charset=utf-8'
        doorkeeper_authorize!
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
  end
end
