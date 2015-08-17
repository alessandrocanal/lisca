module SocialAuth
  extend ActiveSupport::Concern

  included do
    has_many :social_accounts
    accepts_nested_attributes_for :social_accounts
  end

  class_methods do

    def enter_with_social(parms)
      User.find_or_create_for_social_authentication(parms)
    end

    def find_or_create_for_social_authentication(parms)
      return unless parms.present?
      provider = parms[:social_provider].presence
      uid = parms[:social_uid].presence
      token = parms[:social_token].presence
      #user = SocialAccount.where(provider: provider, uid: uid).includes(:user).first.try(:user)
      social_account = SocialAccount.where(provider: provider, uid: uid).includes(:user).first
      social_account = SocialAccount.new(provider: provider, uid: uid) if social_account.blank?

      social_account.token = token

      if social_account.valid?
        if social_account.user.blank?
          password = Devise.friendly_token[0, 20]
          email = social_account.email.presence || User.random_mail
          social_account.build_user({
            email: email,
            password: password,
            password_confirmation: password
          })
        end
        social_account.save
        social_account.user
      else
        nil
      end
    end

    def random_mail
      Faker::Internet.email
    end

  end

end
