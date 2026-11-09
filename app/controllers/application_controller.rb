class ApplicationController < ActionController::API
  wrap_parameters false
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Record not found; check identifiers", status: "not_found" }, status: :not_found
  end
  rescue_from ActionController::ParameterMissing, ArgumentError do |error|
    render json: { error: error.message, status: "bad_request" }, status: :bad_request
  end
  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { errors: error.record.errors.to_hash, status: "validation_failed" }, status: :unprocessable_entity
  end
  rescue_from ActiveRecord::RecordNotUnique do
    render json: { error: "Record already exists", status: "conflict" }, status: :conflict
  end

  def catch_404
    render json: { error: "No route matches; check routes", status: "no_route" }, status: :not_found
  end

  def index
    render json: { name: "Corporate messenger API", version: "v1", resources: %w[employees chats memberships messages] }
  end
end
