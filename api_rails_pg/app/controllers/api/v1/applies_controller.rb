class Api::V1::AppliesController < ApplicationController
  before_action :set_apply, only: [:show, :update, :destroy, :mark_read, :invite]

  def index
    applies = apply_scope
    [:job_id, :geek_id, :read, :invited].each do |field|
      applies = applies.where(field => params[field]) if params.key?(field)
    end
    render_collection(:applies, applies)
  end

  def show
    render json: @apply
  end

  def create
    render json: apply_scope.create!(apply_params), status: :created
  end

  def update
    @apply.update!(apply_params)
    render json: @apply
  end

  def destroy
    @apply.destroy!
    render json: { deleted_apply: @apply.as_json(except: [:created_at, :updated_at]), code: 200, status: :success }
  end

  def mark_read
    @apply.update!(read: true)
    render json: @apply
  end

  def invite
    @apply.update!(invited: true)
    render json: @apply
  end

  private

  def apply_scope
    return Job.find(params[:job_id]).applies if params[:job_id]
    return Geek.find(params[:geek_id]).applies if params[:geek_id]
    Apply.all
  end

  def set_apply
    @apply = apply_scope.find(params[:id])
  end

  def apply_params
    fields = [:job_id, :geek_id, :read, :invited]
    fields.delete(:job_id) if params[:job_id] && request.path_parameters[:job_id]
    fields.delete(:geek_id) if params[:geek_id] && request.path_parameters[:geek_id]
    params.permit(*fields)
  end
end
