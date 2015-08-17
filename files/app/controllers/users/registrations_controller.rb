class Users::RegistrationsController < Devise::RegistrationsController

  respond_to :json

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?


    if resource.persisted?

      #bd doorkeeper
      access_token = resource.create_access_token
      access_token_hash = Doorkeeper::OAuth::TokenResponse.new(access_token).body

      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)

        respond_with access_token_hash,
          location: after_sign_up_path_for(resource),
          status: 201
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private
  def sign_up_params
    params.require(:registration).permit(:email, :password, :password_confirmation)
  end
end
