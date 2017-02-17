module Api::V1
  class PingController < ApiController

    def index
      respond_with({ response: "pong" })
    end
  end
end
