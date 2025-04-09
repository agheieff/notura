class Profile < ApplicationRecord
  belongs_to :account
  has_many :profile_languages, dependent: :destroy
  has_many :languages, through: :profile_languages
  
  validates :username, uniqueness: true, allow_blank: true
  
  before_save :set_default_preferences
  
  # Helper methods for language access
  def native_languages
    profile_languages.native.includes(:language).map(&:language)
  end
  
  def learning_languages
    profile_languages.learning.includes(:language).map(&:language)
  end
  
  def language_proficiency(language_code)
    language = languages.find_by(code: language_code)
    profile_languages.find_by(language: language)&.proficiency_level
  end
  
  private
  
  def set_default_preferences
    self.preferences ||= {
      ui_theme: 'light',
      notifications_enabled: true,
      daily_goal_reminder: true
    }
  end
end
