module DoorkeeperResourceOwnerPasswordCredentialsFlow
  extend ActiveSupport::Concern

  class_methods do

    def enter_with_password(parms)
      rtn = nil
      return unless parms.present? &&
        parms[:username].present? &&
        parms[:password].present?

      username = parms[:username].presence

      password = parms[:password].presence
      user = User.find_for_database_authentication(email: username)
      (user.present? && user.valid_password?(password)) ? user : nil
    end

  end

end
