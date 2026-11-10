class Company < ApplicationRecord
  has_many :jobs, dependent: :destroy
  has_many :applies, through: :jobs
  validates :name, :location, presence: true, length: { maximum: 255 }
  validates :deleted, inclusion: { in: [true, false] }

  def delete_company
    update!(deleted: true)
  end
end
