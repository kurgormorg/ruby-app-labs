class Api::V1::CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :update, :destroy, :mark_deleted, :applies]

  def index
    companies = Company.all
    companies = companies.where(name: params[:name]) if params[:name]
    companies = companies.where(location: params[:location]) if params[:location]
    render_collection(:companies, companies)
  end

  def show
    render json: @company
  end

  def create
    render json: Company.create!(company_params), status: :created
  end

  def update
    @company.update!(company_params)
    render json: @company
  end

  def destroy
    @company.destroy!
    render json: { deleted_company: @company.as_json(except: [:created_at, :updated_at]), code: 200, status: :success }
  end

  def mark_deleted
    if @company.deleted
      render json: { deleted_company: [], deleted_already: :not_modified }
    else
      @company.delete_company
      render json: { deleted_company: @company.as_json(except: [:created_at, :updated_at]), code: 200, status: :success }
    end
  end

  def applies
    render_collection(:applies, @company.applies)
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.permit(:name, :location)
  end
end
