require 'rails_helper'

module Helpers
  def stub_fb(uid, token, valid)
    uri_template = Addressable::Template.new "https://graph.facebook.com/me?access_token=#{token}"

    if valid

      name = Faker::Name.name
      body_to_return = {
        id: uid,
        email: Faker::Internet.email,
        first_name: name.split(" ").first,
        gender: "male",
        last_name: name.split(" ").last,
        link: "https://www.facebook.com/app_scoped_user_id/#{uid}/",
        locale: "it_IT",
        name: name,
        timezone: 2,
        updated_time: "2013-06-17T11:03:33+0000",
        verified: true
      }

      stub_request(:get, uri_template).
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.1'}).
        to_return(
          status: 200,
          body: body_to_return.to_json,
          headers: {}
        )
    else
      body_to_return = {}
      stub_request(:get, uri_template).
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.1'}).
        to_return(
          status: 401,
          body: body_to_return.to_json,
          headers: {}
        )
    end

  end
end
