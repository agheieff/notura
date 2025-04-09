class ProfileLanguage < ApplicationRecord
  belongs_to :profile
  belongs_to :language
  has_many :language_goals, dependent: :destroy
  
  validates :profile_id, uniqueness: { scope: :language_id, message: "already has this language added" }
  
  before_save :set_default_values
  
  scope :native, -> { where(is_native: true) }
  scope :learning, -> { where(learning_active: true) }
  
  # Helper methods for goals access
  def active_goals
    language_goals.active.includes(:topic).by_target_date
  end
  
  def completed_goals
    language_goals.completed.includes(:topic).by_target_date
  end
  
  def goal_for_topic(topic)
    language_goals.find_by(topic: topic)
  end
  
  def update_proficiency(skill, level)
    return unless %i[reading writing listening speaking].include?(skill.to_sym)
    return unless (0..5).cover?(level.to_i)
    
    new_proficiency = proficiency_level.dup
    new_proficiency[skill.to_s] = level.to_i
    update(proficiency_level: new_proficiency)
  end
  
  private
  
  def set_default_values
    self.is_native ||= false
    self.learning_active ||= true
    self.proficiency_level ||= {
      reading: 0,
      writing: 0,
      listening: 0,
      speaking: 0
    }
  end
end
