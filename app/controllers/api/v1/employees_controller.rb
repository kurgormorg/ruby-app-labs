class Api::V1::EmployeesController < Api::V1::ResourcesController
  def chats
    employee = Employee.visible.find(params[:id])
    render_collection(Chat.visible.where(id: employee.memberships.visible.select(:chat_id)).order(:id), key: :chats)
  end

  private

  def filtered(records)
    %i[name department email].reduce(records) { |scope, field| text_filter(scope, field) }
  end

  def resource_params
    payload.permit(:name, :email, :department, :bio)
  end
end
