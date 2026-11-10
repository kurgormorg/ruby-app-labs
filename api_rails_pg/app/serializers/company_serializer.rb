class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name, :location, :deleted
end
