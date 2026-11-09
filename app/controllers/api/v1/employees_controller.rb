class Api::V1::EmployeesController < Api::V1::ResourcesController
  def chats
    employee = Employee.visible.find(params[:id])
    render_collection(Chat.visible.where(id: employee.memberships.visible.select(:chat_id)).order(:id), key: :chats)
  end

  private

  def resource_params
    payload.permit(:name, :email, :department, :bio)
  end
end
