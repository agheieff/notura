class Account < ApplicationRecord
  belongs_to :user
  has_one :profile, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  after_create :create_profile
  
  private
  
  def create_profile
    build_profile.save
  end
end
