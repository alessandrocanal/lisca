class ProfileController < LockController

  def show
    respond_to do |format|
      format.json {
        render json: current_user
      }
    end
  end
end
