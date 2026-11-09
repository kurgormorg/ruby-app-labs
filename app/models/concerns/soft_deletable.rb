module SoftDeletable
  extend ActiveSupport::Concern
  included do
    scope :visible, -> { where(deleted: false) }
    validates :deleted, inclusion: { in: [true, false] }
  end

  def mark_deleted!
    transaction do
      unless deleted?
        soft_delete_children
        # update_columns avoids unrelated validation failures on historical records.
        update_columns(deleted: true, updated_at: Time.current)
      end
    end
  end

  private

  def soft_delete_children; end
end
