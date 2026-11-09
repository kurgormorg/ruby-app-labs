class Employee < ApplicationRecord
  include SoftDeletable
  has_many :memberships, dependent: :restrict_with_exception
  has_many :chats, through: :memberships
  has_many :messages, dependent: :restrict_with_exception
  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :name, :email, :department, presence: true
  validates :name, :department, length: { maximum: 120 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :bio, length: { maximum: 5000 }

  private

  def soft_delete_children
    memberships.visible.find_each(&:mark_deleted!)
    messages.visible.find_each(&:mark_deleted!)
  end
end
