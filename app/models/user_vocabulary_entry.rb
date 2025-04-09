class UserVocabularyEntry < ApplicationRecord
  belongs_to :user
  belongs_to :vocabulary_entry
  belongs_to :profile_language
  
  # Proficiency level (0-5)
  # 0: Unknown
  # 1: Seen
  # 2: Learning
  # 3: Familiar
  # 4: Known
  # 5: Mastered
  validates :proficiency_level, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  
  # Last reviewed timestamp
  validates :last_reviewed_at, presence: true
  
  # Next review date (based on spaced repetition algorithm)
  validates :next_review_at, presence: true
  
  # Review history in JSON format
  # [
  #   { "date": "2025-04-09", "result": "correct", "time_ms": 1200 },
  #   { "date": "2025-04-12", "result": "incorrect", "time_ms": 1500 }
  # ]
  serialize :review_history, JSON
  
  # Notes by user
  # Personal notes, mnemonics, etc.
  
  # User tags for personal organization
  serialize :user_tags, JSON
  
  # Scopes
  scope :due_for_review, -> { where("next_review_at <= ?", Time.current) }
  scope :by_proficiency, ->(level) { where(proficiency_level: level) }
  scope :by_profile_language, ->(profile_language_id) { where(profile_language_id: profile_language_id) }
  scope :with_user_tags, ->(tags) { 
    tags = Array(tags)
    where("user_tags @> ?", tags.to_json)
  }
  
  # Instance methods
  def due_for_review?
    next_review_at <= Time.current
  end
  
  def days_until_review
    [(next_review_at.to_date - Date.current).to_i, 0].max
  end
  
  def record_review(result, time_ms = nil)
    new_review = {
      date: Date.current.to_s,
      result: result.to_s,
      time_ms: time_ms
    }
    
    # Initialize review history if nil
    self.review_history ||= []
    
    # Add new review to history
    self.review_history << new_review
    
    # Update proficiency level based on result
    update_proficiency_level(result)
    
    # Calculate next review date using spaced repetition algorithm
    calculate_next_review_date
    
    # Update last reviewed timestamp
    self.last_reviewed_at = Time.current
    
    save
  end
  
  private
  
  def update_proficiency_level(result)
    case result.to_s
    when "correct"
      # Increase proficiency level, max 5
      self.proficiency_level = [self.proficiency_level + 1, 5].min
    when "hard"
      # Keep the same level
    when "incorrect"
      # Decrease proficiency level, min 1
      self.proficiency_level = [self.proficiency_level - 1, 1].max
    end
  end
  
  def calculate_next_review_date
    # Simple spaced repetition algorithm based on proficiency level
    # More sophisticated algorithms like SM-2 could be implemented here
    days_until_next_review = case proficiency_level
      when 0, 1 then 1    # Review new or difficult words the next day
      when 2 then 3       # Review after 3 days
      when 3 then 7       # Review after 1 week
      when 4 then 14      # Review after 2 weeks
      when 5 then 30      # Review after 1 month
    end
    
    self.next_review_at = Date.current + days_until_next_review.days
  end
end