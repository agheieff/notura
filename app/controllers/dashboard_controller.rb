class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @profile = current_user.account.profile
    @learning_languages = @profile.learning_languages
    @native_languages = @profile.native_languages
  end
end
