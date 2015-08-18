require 'rails_helper'

describe "api auth", type: :request do

  before(:all) { @apiroot = "" }
  before(:each) { set_json_headers_api }

  describe "signup" do
    let(:url) { "#{@apiroot}/users" }
    let(:password) { "thisisasecretpassword" }
    let(:user) { FactoryGirl.attributes_for(:user) }
    let(:parms) do
      {
        registration: {
          email: user[:email],
          password: password,
          password_confirmation: password
        }
      }
    end

    describe "with non existent email" do

      it "creates new user and respond 201" do
        post url, parms.to_json, @hd
        r = JSON.parse(response.body)
        expect(response.status).to eq(201)
      end
    end
  end

  describe "login with username" do
    let(:url) { "#{@apiroot}/oauth/token" }
    let(:password) { "thisisasecretpassword" }
    let(:user) { FactoryGirl.create(:user, password: password, password_confirmation: password) }

    describe "and valid password" do

      let(:parms) do
        {
          grant_type: "password",
          username: user.email,
          password: password
        }
      end

      it "responds 200" do
        post url, parms.to_json, @hd
        r = JSON.parse(response.body)

        expected_token = Doorkeeper::AccessToken.last.try(:token)

        expect(response.status).to eq(200)

        expect(r.has_key?("access_token")).to eq(true)
        expect(r.has_key?("token_type")).to eq(true)
        expect(r.has_key?("expires_in")).to eq(true)
        expect(r.has_key?("created_at")).to eq(true)

        expect(r["access_token"]).to eq(expected_token)
        expect(r["token_type"]).to eq("bearer")
      end
    end#valid password

    describe "and invalid password" do

      let(:parms) do
        {
          grant_type: "password",
          username: user.email,
          password: password + "_"
        }
      end

      it "responds 401" do
        post url, parms.to_json, @hd
        r = JSON.parse(response.body)

        expected_token = Doorkeeper::AccessToken.last.try(:token)

        expect(response.status).to eq(401)

        expect(r.has_key?("error")).to eq(true)
        expect(r.has_key?("error_description")).to eq(true)

        expect(r["error"]).to eq("invalid_grant")
      end

     end#invalid password

  end#login with username

  describe "login with social uid" do

    let(:url) { "#{@apiroot}/tokens/social" }
    let(:social_token) { "0123456789" }
    let(:social_uid) { "0123456789" }
    let(:social_provider) { "facebook" }

    describe "with valid social token" do

      describe "and existing user" do

        let(:user) { FactoryGirl.create(:user) }
        let(:social_account) do
          stub_fb(social_uid, social_token, true)
          FactoryGirl.create(:social_account, uid: social_uid, token: social_token, provider: social_provider, user: user)
        end
        let(:parms) do
          {
            grant_type: "social",
            social_provider: social_account.provider,
            social_uid: social_account.uid,
            social_token: social_account.token
          }
        end

        it "responds 200" do

          post url, parms.to_json, @hd
          r = JSON.parse(response.body)

          expected_token = Doorkeeper::AccessToken.last.try(:token)

          expect(response.status).to eq(200)

          expect(r.has_key?("access_token")).to eq(true)
          expect(r.has_key?("token_type")).to eq(true)
          expect(r.has_key?("expires_in")).to eq(true)
          expect(r.has_key?("created_at")).to eq(true)

          expect(r["access_token"]).to eq(expected_token)
          expect(r["token_type"]).to eq("bearer")
        end
      end

      describe "and non-existing user without email" do

        let(:social_account) do
          stub_fb(social_uid, social_token, true)
          FactoryGirl.attributes_for(:social_account, uid: social_uid, token: social_token, provider: social_provider)
        end
        let(:parms) do
          {
            grant_type: "password",
            social_provider: social_account[:provider],
            social_uid: social_account[:uid],
            social_token: social_account[:token]
          }
        end

        it "creates new user with fake email and responds 201" do
          post url, parms.to_json, @hd
          r = JSON.parse(response.body)

          expected_token = Doorkeeper::AccessToken.last.try(:token)

          expect(response.status).to eq(200)

          expect(r.has_key?("access_token")).to eq(true)
          expect(r.has_key?("token_type")).to eq(true)
          expect(r.has_key?("expires_in")).to eq(true)
          expect(r.has_key?("created_at")).to eq(true)

          expect(r["access_token"]).to eq(expected_token)
          expect(r["token_type"]).to eq("bearer")
        end
      end

    end#with valid social token

    describe "with invalid social token" do

      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_social_token) { social_token + "_"}
      let(:social_account) do
        stub_fb(social_uid, social_token, true)
        stub_fb(social_uid, wrong_social_token, false)
        FactoryGirl.create(:social_account, uid: social_uid, token: social_token, provider: social_provider, user: user)
      end
      let(:parms) do
        {
          grant_type: "password",
          social_provider: social_account[:provider],
          social_uid: social_account[:uid],
          social_token: wrong_social_token
        }
      end

      it "responds 401" do

        post url, parms.to_json, @hd
        r = JSON.parse(response.body)

        expect(response.status).to eq(401)
        expect(r.has_key?("error")).to eq(true)
        expect(r["error"]).to eq("invalid_grant")
      end
    end#with invalid social token
  end#login with social uid
end
