class Topic < ApplicationRecord
  belongs_to :parent, class_name: 'Topic', optional: true
  has_many :children, class_name: 'Topic', foreign_key: 'parent_id', dependent: :nullify
  has_many :language_goals, dependent: :destroy
  
  validates :name, presence: true
  validates :difficulty_level, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  
  scope :root_topics, -> { where(parent_id: nil) }
  scope :by_difficulty, -> { order(difficulty_level: :asc) }
  
  before_save :set_default_difficulty
  
  def root?
    parent_id.nil?
  end
  
  def leaf?
    children.none?
  end
  
  def ancestors
    return [] if root?
    
    parent.ancestors + [parent]
  end
  
  def full_path
    ancestors.map(&:name).push(name).join(' > ')
  end
  
  private
  
  def set_default_difficulty
    self.difficulty_level ||= 1
  end
end
