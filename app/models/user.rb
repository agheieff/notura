class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  has_one :account, dependent: :destroy
  has_one :profile, through: :account
  has_many :user_vocabulary_entries, dependent: :destroy
  has_many :vocabulary_entries, through: :user_vocabulary_entries
  
  after_create :create_account
  
  def full_name
    [first_name, last_name].compact.join(' ')
  end
  
  def initials
    [first_name&.first, last_name&.first].compact.join('').upcase
  end
  
  # Get vocabulary entries due for review
  def vocabulary_due_for_review(profile_language_id = nil)
    entries = user_vocabulary_entries.due_for_review
    
    if profile_language_id.present?
      entries = entries.by_profile_language(profile_language_id)
    end
    
    entries
  end
  
  # Add a vocabulary entry to user's collection
  def add_vocabulary_entry(vocabulary_entry, profile_language, attributes = {})
    return false unless vocabulary_entry.is_a?(VocabularyEntry) && profile_language.is_a?(ProfileLanguage)
    
    # Check if the entry already exists
    existing_entry = user_vocabulary_entries.find_by(vocabulary_entry: vocabulary_entry)
    return existing_entry if existing_entry.present?
    
    # Create new user vocabulary entry
    user_vocabulary_entries.create(
      vocabulary_entry: vocabulary_entry,
      profile_language: profile_language,
      proficiency_level: attributes[:proficiency_level] || 0,
      notes: attributes[:notes],
      user_tags: attributes[:user_tags] || [],
      last_reviewed_at: Time.current,
      next_review_at: Time.current
    )
  end
  
  private
  
  def create_account
    build_account(email: email).save
    account.build_profile.save if account.profile.nil?
  end
end