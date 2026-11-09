class Api::V1::MessagesController < Api::V1::ResourcesController
  private

  def collection
    if params[:chat_id]
      Chat.visible.find(params[:chat_id]).messages
    elsif params[:employee_id]
      Employee.visible.find(params[:employee_id]).messages
    else
      Message.all
    end
  end

  def assign_parent(record)
    record.chat_id = params[:chat_id] if params[:chat_id]
    record.employee_id = params[:employee_id] if params[:employee_id]
  end

  def resource_params
    fields = action_name == "create" ? %i[employee_id chat_id body] : %i[body]
    payload.permit(*fields)
  end
end
