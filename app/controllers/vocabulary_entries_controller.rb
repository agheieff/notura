class VocabularyEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vocabulary_entry, only: [:show]
  before_action :set_language, only: [:index]
  
  def index
    @vocabulary_entries = VocabularyEntry.all
    
    # Filter by language if specified
    @vocabulary_entries = @vocabulary_entries.by_language(@language.id) if @language
    
    # Filter by word class if specified
    @vocabulary_entries = @vocabulary_entries.by_word_class(params[:word_class]) if params[:word_class].present?
    
    # Filter by difficulty if specified
    @vocabulary_entries = @vocabulary_entries.by_difficulty(params[:difficulty]) if params[:difficulty].present?
    
    # Search by text if query provided
    @vocabulary_entries = @vocabulary_entries.search_text(params[:query]) if params[:query].present?
    
    # Filter by tags if specified
    @vocabulary_entries = @vocabulary_entries.with_tags(params[:tags]) if params[:tags].present?
    
    # Paginate results
    @vocabulary_entries = @vocabulary_entries.page(params[:page]).per(20)
  end
  
  def show
    # Find the user's vocabulary entry if it exists
    @user_vocabulary_entry = current_user.user_vocabulary_entries.find_by(vocabulary_entry: @vocabulary_entry)
  end
  
  private
  
  def set_vocabulary_entry
    @vocabulary_entry = VocabularyEntry.find(params[:id])
  end
  
  def set_language
    @language = Language.find(params[:language_id]) if params[:language_id].present?
  end
end