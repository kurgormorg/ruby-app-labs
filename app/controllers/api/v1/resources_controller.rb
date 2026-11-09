class Api::V1::ResourcesController < ApplicationController
  def index
    render_collection(collection.visible.order(:id))
  end

  def show
    render_record(collection.visible.find(params[:id]))
  end

  def create
    record = collection.new(resource_params)
    assign_parent(record)
    record.save!
    render_record(record, status: :created)
  end

  def update
    record = collection.visible.find(params[:id])
    record.update!(resource_params)
    render_record(record)
  end

  def destroy
    record = collection.find(params[:id])
    was_deleted = record.deleted?
    record.mark_deleted!
    render json: { deleted_record: serialize(record), already_deleted: was_deleted, status: "success" }
  end
  alias_method :mark_deleted, :destroy

  private

  def model_class
    self.class.name.demodulize.delete_suffix("Controller").singularize.constantize
  end

  def collection
    model_class.all
  end

  def serialize(record)
    "#{record.class.name}Serializer".constantize.new(record).as_json
  end

  def render_record(record, status: :ok)
    render json: serialize(record), status: status
  end

  def render_collection(records, key: controller_name)
    render json: { key => records.map { |record| serialize(record) } }
  end

  def payload
    key = model_class.model_name.param_key
    params[key].is_a?(ActionController::Parameters) ? params[key] : params
  end

  def assign_parent(record); end
end
