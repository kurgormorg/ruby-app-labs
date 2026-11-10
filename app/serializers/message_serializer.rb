class MessageSerializer < ApplicationSerializer
  attributes :id, :employee_id, :chat_id, :body, :created_at, :updated_at, :deleted
end
