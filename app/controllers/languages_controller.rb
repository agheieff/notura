class LanguagesController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_language, only: [:show]
  
  def index
    @languages = Language.available.order(:name)
  end

  def show
    @profile = current_user.account.profile
    @profile_language = @profile.profile_languages.find_by(language: @language)
    @is_learning = @profile_language.present? && @profile_language.learning_active?
    @is_native = @profile_language.present? && @profile_language.is_native?
  end
  
  private
  
  def set_language
    @language = Language.find(params[:id])
  end
end
