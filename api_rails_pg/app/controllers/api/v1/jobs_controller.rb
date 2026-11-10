class Api::V1::JobsController < ApplicationController
  before_action :set_job, only: [:show, :update, :destroy, :geeks, :invited_geeks]

  def index
    jobs = job_scope
    jobs = jobs.where(name: params[:name]) if params[:name]
    jobs = jobs.where(place: params[:place]) if params[:place]
    render_collection(:jobs, jobs)
  end

  def show
    render json: @job
  end

  def create
    render json: job_scope.create!(job_params).as_json, status: :created
  end

  def update
    @job.update!(job_params)
    render json: @job
  end

  def destroy
    @job.update!(deleted: true)
    render json: { deleted_job: @job.as_json(except: [:created_at, :updated_at]), code: 200, status: :success }
  end

  def geeks
    render_collection(:geeks, @job.geeks.distinct)
  end

  def invited_geeks
    render_collection(:geeks, @job.geeks.where(applies: { invited: true }).distinct)
  end

  private

  def job_scope
    params[:company_id] ? Company.find(params[:company_id]).jobs : Job.all
  end

  def set_job
    @job = job_scope.find(params[:id])
  end

  def job_params
    params[:company_id] ? params.permit(:name, :place) : params.permit(:name, :place, :company_id)
  end
end
