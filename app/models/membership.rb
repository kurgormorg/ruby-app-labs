class Membership < ApplicationRecord
  include SoftDeletable
  belongs_to :employee
  belongs_to :chat
  validates :employee_id, :chat_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :role, inclusion: { in: %w[owner member] }
  validates :muted, inclusion: { in: [true, false] }
  validates :employee_id, uniqueness: { scope: :chat_id, conditions: -> { visible } }, unless: :deleted?
  validates_associated :employee, :chat
  validate :parents_are_visible

  def unread_messages
    relation = chat.messages.visible.where.not(employee_id: employee_id)
    last_read_at ? relation.where("created_at > ?", last_read_at) : relation
  end

  def mark_read!
    update!(last_read_at: Time.current)
  end

  private

  def parents_are_visible
    errors.add(:employee, "is deleted") if employee&.deleted?
    errors.add(:chat, "is deleted") if chat&.deleted?
  end
end
