class SocialAccount < ActiveRecord::Base
  belongs_to :user

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
  validate :valid_token?

  def valid_token?
    rtn = case provider.to_s
    when "facebook"
      valid_facebook_token?
    end
    errors.add(:token, "not valid") unless rtn
  end

  def valid_facebook_token?
    fb_api && fb_user && (fb_user["id"] == uid)
  end

  private
  def fb_api
    return if token.blank?
    @fb_api ||= (Koala::Facebook::API.new(token, Rails.application.secrets.FB_APP_SECRET) rescue nil)
  end

  def fb_user
    @fb_user ||= (fb_api.get_object("me") rescue nil)
  end
end
