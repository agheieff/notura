class ProfileLanguagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_language, only: [:create]
  before_action :set_profile_language, only: [:update, :destroy]
  
  def create
    @profile = current_user.account.profile
    @profile_language = @profile.profile_languages.build(profile_language_params)
    @profile_language.language = @language
    
    if @profile_language.save
      redirect_to language_path(@language), notice: "Language added to your profile."
    else
      redirect_to language_path(@language), alert: "Error: #{@profile_language.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @profile_language.update(profile_language_params)
      redirect_to language_path(@profile_language.language), notice: "Language settings updated."
    else
      redirect_to language_path(@profile_language.language), alert: "Error: #{@profile_language.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    language = @profile_language.language
    @profile_language.destroy
    redirect_to languages_path, notice: "Language removed from your profile."
  end
  
  private
  
  def set_language
    @language = Language.find(params[:language_id])
  end
  
  def set_profile_language
    @profile_language = current_user.account.profile.profile_languages.find(params[:id])
  end
  
  def profile_language_params
    params.require(:profile_language).permit(:is_native, :learning_active, proficiency_level: {})
  end
end
