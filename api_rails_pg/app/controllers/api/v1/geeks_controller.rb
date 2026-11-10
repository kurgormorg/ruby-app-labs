class Api::V1::GeeksController < ApplicationController
  before_action :set_geek, only: [:show, :update, :destroy, :jobs, :invited_jobs, :companies, :resume]

  def index
    geeks = Geek.all
    geeks = geeks.where(name: params[:name]) if params[:name]
    geeks = geeks.where(stack: params[:stack]) if params[:stack]
    render_collection(:geeks, geeks)
  end

  def show
    render json: @geek
  end

  def create
    render json: Geek.create!(geek_params), status: :created
  end

  def update
    @geek.update!(geek_params)
    render json: @geek
  end

  def destroy
    @geek.destroy!
    render json: { deleted_geek: @geek.as_json(except: [:created_at, :updated_at]), code: 200, status: :success }
  end

  def jobs
    render_collection(:jobs, @geek.jobs.distinct)
  end

  def invited_jobs
    render_collection(:jobs, @geek.jobs.where(applies: { invited: true }).distinct)
  end

  def companies
    render_collection(:companies, @geek.companies.distinct)
  end

  def resume
    @geek.update!(params.permit(:resume))
    render json: @geek
  end

  private

  def set_geek
    @geek = Geek.find(params[:id])
  end

  def geek_params
    params.permit(:name, :stack, :resume)
  end
end
