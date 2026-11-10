class MembershipSerializer < ApplicationSerializer
  attributes :id, :employee_id, :chat_id, :role, :muted, :last_read_at, :deleted
end
