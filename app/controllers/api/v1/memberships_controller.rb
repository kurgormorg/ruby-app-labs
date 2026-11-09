class Api::V1::MembershipsController < Api::V1::ResourcesController
  def mark_read
    membership = collection.visible.find(params[:id])
    membership.mark_read!
    render_record(membership)
  end

  def unread_messages
    membership = collection.visible.find(params[:id])
    render_collection(membership.unread_messages.order(:id), key: :messages)
  end

  private

  def collection
    if params[:chat_id]
      Chat.visible.find(params[:chat_id]).memberships
    elsif params[:employee_id]
      Employee.visible.find(params[:employee_id]).memberships
    else
      Membership.all
    end
  end

  def assign_parent(record)
    record.chat_id = params[:chat_id] if params[:chat_id]
    record.employee_id = params[:employee_id] if params[:employee_id]
  end

  def resource_params
    fields = action_name == "create" ? %i[employee_id chat_id role muted] : %i[role muted]
    payload.permit(*fields)
  end
end
