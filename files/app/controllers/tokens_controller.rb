class TokensController < Doorkeeper::TokensController
  def create
    response = authorize_response

    self.headers.merge! response.headers
    self.response_body = response.body.to_json
    self.status        = response.status
  rescue Doorkeeper::Errors::DoorkeeperError => e
    handle_token_exception e
  end

  def social
    #TODO extend doorkeeper grant types
    params['grant_type'] = "password" if params['grant_type'] == "social"

    response = authorize_response

    self.headers.merge! response.headers
    self.response_body = response.body.to_json
    self.status        = response.status
  rescue Doorkeeper::Errors::DoorkeeperError => e
    handle_token_exception e
  end
end
