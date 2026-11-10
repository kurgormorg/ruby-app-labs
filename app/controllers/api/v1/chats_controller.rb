class Api::V1::ChatsController < Api::V1::ResourcesController
  def employees
    chat = Chat.visible.find(params[:id])
    render_collection(Employee.visible.where(id: chat.memberships.visible.select(:employee_id)).order(:id), key: :employees)
  end

  private

  def filtered(records)
    exact_filter(text_filter(records, :name), :kind, allowed: %w[group channel])
  end

  def resource_params
    payload.permit(:name, :kind, :description)
  end
end
