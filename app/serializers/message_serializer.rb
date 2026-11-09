class MessageSerializer < ApplicationSerializer
  ATTRIBUTES = %i[id employee_id chat_id body created_at updated_at deleted].freeze
end
