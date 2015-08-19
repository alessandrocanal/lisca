module API
  module V1
    class HealthCheck < Grape::API
      version 'v1', using: :path, vendor: 'Rawfish'
      format :json
      formatter :json, Grape::Formatter::Rabl
      default_format :json

      resource :ping do
        desc "ping pong"
        get do
          { response: "pong" }
        end
      end

    end
  end
end
