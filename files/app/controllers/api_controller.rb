module Api::V1
  class ApiController < ApplicationController
    # Generic API stuff here

    before_action do
      authenticate_request!
    end


  end
end
