class GeekSerializer < ActiveModel::Serializer
  attributes :id, :name, :stack, :resume
end
