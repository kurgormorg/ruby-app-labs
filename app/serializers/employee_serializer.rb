class EmployeeSerializer < ApplicationSerializer
  ATTRIBUTES = %i[id name email department bio deleted].freeze
end
