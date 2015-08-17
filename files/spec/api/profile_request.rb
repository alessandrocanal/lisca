require 'rails_helper'

describe "profile", type: :request do

  before(:all) { @apiroot = "" }
  before(:each) do
    set_json_headers_api
    login_api
  end

  describe "index" do
    let(:url) { "#{@apiroot}/profile" }
    let(:parms) { {} }

    it "responds with profile and status 200" do
      get url, parms, @hd
      expect(response.status).to eq(200)
    end
  end
end
