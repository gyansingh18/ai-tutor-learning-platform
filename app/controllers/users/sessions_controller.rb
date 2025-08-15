class Users::SessionsController < Devise::SessionsController
  # Disable Turbo for sign out to ensure proper page refresh
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    
    # Force a full page reload after sign out
    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other }
      format.json { head :no_content }
      format.turbo_stream { redirect_to root_path, status: :see_other }
    end
  end
end
