class UserVocabularyEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_vocabulary_entry, only: [:show, :update, :record_review]
  before_action :set_vocabulary_entry, only: [:create]
  before_action :set_profile_language, only: [:index, :create]
  
  def index
    @user_vocabulary_entries = current_user.user_vocabulary_entries
    
    # Filter by profile language if specified
    @user_vocabulary_entries = @user_vocabulary_entries.by_profile_language(@profile_language.id) if @profile_language
    
    # Filter by proficiency level if specified
    @user_vocabulary_entries = @user_vocabulary_entries.by_proficiency(params[:proficiency_level]) if params[:proficiency_level].present?
    
    # Filter by due for review
    @user_vocabulary_entries = @user_vocabulary_entries.due_for_review if params[:due_for_review].present?
    
    # Filter by user tags if specified
    @user_vocabulary_entries = @user_vocabulary_entries.with_user_tags(params[:user_tags]) if params[:user_tags].present?
    
    # Paginate results
    @user_vocabulary_entries = @user_vocabulary_entries.page(params[:page]).per(20)
  end
  
  def show
  end
  
  def create
    # Check if entry already exists for this user and vocabulary entry
    @user_vocabulary_entry = current_user.user_vocabulary_entries.find_by(vocabulary_entry: @vocabulary_entry)
    
    if @user_vocabulary_entry
      redirect_to user_vocabulary_entry_path(@user_vocabulary_entry), notice: 'This word is already in your vocabulary.'
      return
    end
    
    # Create new user vocabulary entry
    @user_vocabulary_entry = current_user.user_vocabulary_entries.new(user_vocabulary_entry_params)
    @user_vocabulary_entry.vocabulary_entry = @vocabulary_entry
    @user_vocabulary_entry.profile_language = @profile_language
    @user_vocabulary_entry.last_reviewed_at = Time.current
    @user_vocabulary_entry.next_review_at = Time.current
    
    if @user_vocabulary_entry.save
      redirect_to user_vocabulary_entry_path(@user_vocabulary_entry), notice: 'Word added to your vocabulary.'
    else
      redirect_to vocabulary_entry_path(@vocabulary_entry), alert: 'Failed to add word to your vocabulary.'
    end
  end
  
  def update
    if @user_vocabulary_entry.update(user_vocabulary_entry_params)
      redirect_to user_vocabulary_entry_path(@user_vocabulary_entry), notice: 'Vocabulary entry updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end
  
  # POST /user_vocabulary_entries/:id/record_review
  def record_review
    result = params[:result]
    time_ms = params[:time_ms]
    
    unless %w[correct hard incorrect].include?(result)
      redirect_to user_vocabulary_entry_path(@user_vocabulary_entry), alert: 'Invalid review result.'
      return
    end
    
    if @user_vocabulary_entry.record_review(result, time_ms)
      redirect_to user_vocabulary_entry_path(@user_vocabulary_entry), notice: 'Review recorded.'
    else
      redirect_to user_vocabulary_entry_path(@user_vocabulary_entry), alert: 'Failed to record review.'
    end
  end
  
  private
  
  def set_user_vocabulary_entry
    @user_vocabulary_entry = current_user.user_vocabulary_entries.find(params[:id])
  end
  
  def set_vocabulary_entry
    @vocabulary_entry = VocabularyEntry.find(params[:vocabulary_entry_id])
  end
  
  def set_profile_language
    if params[:profile_language_id].present?
      @profile_language = current_user.profile.profile_languages.find(params[:profile_language_id])
    end
  end
  
  def user_vocabulary_entry_params
    params.require(:user_vocabulary_entry).permit(:proficiency_level, :notes, user_tags: [])
  end
end