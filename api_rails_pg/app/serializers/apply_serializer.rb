class ApplySerializer < ActiveModel::Serializer
  attributes :id, :job_id, :geek_id, :read, :invited
end
