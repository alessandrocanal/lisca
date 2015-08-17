class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  include SocialAuth
  include DoorkeeperResourceOwnerPasswordCredentialsFlow

  def self.enter(parms)
    return unless parms.present?
    username = parms[:username].presence
    social_uid = parms[:social_uid].presence

    if username.present?
      rtn = self.enter_with_password(parms)
    elsif social_uid.present?
      rtn = self.enter_with_social(parms)
    else
      rtn = nil
    end

    rtn
  end

  def create_access_token
    Doorkeeper::AccessToken.create!(
      #application_id: app.id,
      resource_owner_id: id,
      #scopes: "public write preferences",
      use_refresh_token: true,
      expires_in: Doorkeeper.configuration.access_token_expires_in
    )
  end

end
