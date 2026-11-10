class Api::V1::ResourcesController < ApplicationController
  def index
    render_collection(filtered(collection.visible).order(:id))
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

  def filtered(records)
    records
  end

  def text_filter(records, field)
    return records unless params[field].present?
    value = params[field]
    raise ArgumentError, "#{field} must be a string" unless value.is_a?(String)
    column = records.klass.arel_table[field]
    records.where(column.matches("%#{ActiveRecord::Base.sanitize_sql_like(value)}%"))
  end

  def exact_filter(records, field, allowed: nil)
    return records unless params.key?(field)
    value = params[field]
    raise ArgumentError, "Invalid #{field}" unless value.is_a?(String) && value.present? && (!allowed || allowed.include?(value))
    records.where(field => value)
  end

  def boolean_filter(records, field)
    return records unless params.key?(field)
    value = params[field]
    raise ArgumentError, "#{field} must be true or false" unless %w[true false].include?(value)
    records.where(field => value == "true")
  end

  def positive_id(field)
    value = params[field].to_s
    raise ArgumentError, "#{field} must be a positive integer" unless value.match?(/\A[1-9][0-9]{0,17}\z/)
    value.to_i
  end

  def id_filter(records, field)
    params.key?(field) ? records.where(field => positive_id(field)) : records
  end

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
