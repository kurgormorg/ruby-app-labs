class Message < ApplicationRecord
  include SoftDeletable
  belongs_to :employee
  belongs_to :chat
  validates :body, presence: true, length: { maximum: 10000 }
  validates :employee_id, :chat_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates_associated :employee, :chat
  validate :author_is_active_member, on: :create
  validate :parents_are_visible

  private

  def author_is_active_member
    unless Membership.visible.exists?(employee_id: employee_id, chat_id: chat_id)
      errors.add(:employee, "must be a member of this chat")
    end
  end

  def parents_are_visible
    errors.add(:employee, "is deleted") if employee&.deleted?
    errors.add(:chat, "is deleted") if chat&.deleted?
  end
end
