require 'rails_helper'

RSpec.describe "ping", type: :request do
  
  before(:each) { set_json_headers_api }

  it "I say ping, you say pong" do
    get "/ping", nil, @hd
    r = JSON.parse(response.body)
    expect(r['response']).to eq("pong")
  end
end
