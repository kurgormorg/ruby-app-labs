class Apply < ApplicationRecord
  belongs_to :job
  belongs_to :geek
  validates :job_id, :geek_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :read, :invited, inclusion: { in: [true, false] }
  validates_associated :job, :geek
end
