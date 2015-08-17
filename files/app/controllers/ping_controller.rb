class PingController < ApplicationController
  respond_to :json

  def index
    respond_with({ response: "pong" })
  end
end
