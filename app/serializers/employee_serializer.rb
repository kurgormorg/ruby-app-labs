class EmployeeSerializer < ApplicationSerializer
  attributes :id, :name, :email, :department, :bio, :deleted
end
