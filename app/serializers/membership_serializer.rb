class MembershipSerializer < ApplicationSerializer
  ATTRIBUTES = %i[id employee_id chat_id role muted last_read_at deleted].freeze
end
