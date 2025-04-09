class LanguageGoal < ApplicationRecord
  belongs_to :profile_language
  belongs_to :topic
  
  validates :target_level, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :target_date, presence: true
  validates :profile_language_id, uniqueness: { scope: :topic_id, message: "already has a goal for this topic" }
  
  validate :future_target_date
  
  scope :active, -> { where('target_date >= ?', Date.today) }
  scope :completed, -> { where('target_date < ?', Date.today) }
  scope :by_target_date, -> { order(target_date: :asc) }
  
  private
  
  def future_target_date
    if target_date.present? && target_date < Date.today
      errors.add(:target_date, "must be in the future")
    end
  end
end
