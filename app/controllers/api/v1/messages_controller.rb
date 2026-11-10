class Api::V1::MessagesController < Api::V1::ResourcesController
  private

  def filtered(records)
    records = text_filter(records, :body)
    records = %i[employee_id chat_id].reduce(records) { |scope, field| id_filter(scope, field) }
    return records unless params.key?(:read)
    raise ArgumentError, "read must be true or false" unless %w[true false].include?(params[:read])
    membership = Membership.visible.find(positive_id(:membership_id))
    messages = records.where(chat_id: membership.chat_id).where.not(employee_id: membership.employee_id)
    if params[:read] == "true"
      membership.last_read_at ? messages.where("created_at <= ?", membership.last_read_at) : messages.none
    else
      membership.last_read_at ? messages.where("created_at > ?", membership.last_read_at) : messages
    end
  end

  def collection
    if request.path_parameters[:chat_id]
      Chat.visible.find(params[:chat_id]).messages
    elsif request.path_parameters[:employee_id]
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
