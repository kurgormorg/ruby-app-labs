class ApplicationController < ActionController::API
  include ActionController::Serialization

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'No such record in Database; check params', status: :not_found }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render json: { errors: exception.record.errors, status: :unprocessable_entity }, status: 422
  end

  def catch_404
    render json: { error: 'No route matches; check routes', status: :no_route }, status: :not_found
  end

  private

  def render_collection(name, records)
    render json: { name => ActiveModelSerializers::SerializableResource.new(records).as_json }
  end
end
