class Chat < ApplicationRecord
  include SoftDeletable
  has_many :memberships, dependent: :restrict_with_exception
  has_many :employees, through: :memberships
  has_many :messages, dependent: :restrict_with_exception
  validates :name, presence: true, length: { maximum: 120 }
  validates :kind, inclusion: { in: %w[group channel] }
  validates :description, length: { maximum: 5000 }

  private

  def soft_delete_children
    memberships.visible.find_each(&:mark_deleted!)
    messages.visible.find_each(&:mark_deleted!)
  end
end
