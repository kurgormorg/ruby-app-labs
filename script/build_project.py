from pathlib import Path
import json, struct, zlib

ROOT = Path(__file__).resolve().parents[1]
def put(path, text):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text.lstrip('\n'), encoding='utf-8')

put('config/database.yml', '''
default: &default
  adapter: postgresql
  encoding: unicode
  host: <%= ENV.fetch("PGHOST", "127.0.0.1") %>
  port: <%= ENV.fetch("PGPORT", 5433) %>
  username: <%= ENV.fetch("PGUSER", "messenger_admin") %>
  password: <%= ENV["PGPASSWORD"] || (Rails.root.join("config/secrets.yml").exist? ? Rails.application.config_for(:secrets).dig(:database, :password) : nil) %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>
development:
  <<: *default
  database: corporate_messenger_development
test:
  <<: *default
  database: corporate_messenger_test
production:
  <<: *default
  database: corporate_messenger_production
''')
put('config/secrets.yml.example', '''
# Скопировать в secrets.yml только при необходимости совместимости с методичкой.
# Rails 8 получает пароль из PGPASSWORD в database.yml; secrets.yml не загружается.
development:
  database:
    password: <%= ENV["PGPASSWORD"] %>
test:
  database:
    password: <%= ENV["PGPASSWORD"] %>
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
''')
put('db/migrate/20261110000001_create_messenger.rb', '''
class CreateMessenger < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :department, null: false
      t.text :bio
      t.timestamps
    end
    add_index :employees, :email, unique: true
    create_table :chats do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "group"
      t.text :description
      t.timestamps
    end
    create_table :memberships do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.string :role, null: false, default: "member"
      t.boolean :muted, null: false, default: false
      t.datetime :last_read_at
      t.timestamps
    end
    create_table :messages do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :messages, [:chat_id, :created_at]
  end
end
''')
put('db/migrate/20261110000002_add_soft_deletion.rb', '''
class AddSoftDeletion < ActiveRecord::Migration[8.1]
  def change
    %i[employees chats memberships messages].each do |table|
      add_column table, :deleted, :boolean, null: false, default: false
      add_index table, :deleted
    end
    add_index :memberships, [:employee_id, :chat_id], unique: true,
      where: "deleted = false", name: "unique_active_chat_membership"
  end
end
''')
put('app/models/concerns/soft_deletable.rb', '''
module SoftDeletable
  extend ActiveSupport::Concern
  included do
    scope :visible, -> { where(deleted: false) }
    validates :deleted, inclusion: { in: [true, false] }
  end

  def mark_deleted!
    transaction do
      unless deleted?
        soft_delete_children
        # update_columns avoids unrelated validation failures on historical records.
        update_columns(deleted: true, updated_at: Time.current)
      end
    end
  end

  private

  def soft_delete_children; end
end
''')
put('app/models/employee.rb', '''
class Employee < ApplicationRecord
  include SoftDeletable
  has_many :memberships, dependent: :restrict_with_exception
  has_many :chats, through: :memberships
  has_many :messages, dependent: :restrict_with_exception
  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :name, :email, :department, presence: true
  validates :name, :department, length: { maximum: 120 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :bio, length: { maximum: 5000 }

  private

  def soft_delete_children
    memberships.visible.find_each(&:mark_deleted!)
    messages.visible.find_each(&:mark_deleted!)
  end
end
''')
put('app/models/chat.rb', '''
class Chat < ApplicationRecord
  include SoftDeletable
  has_many :memberships, dependent: :restrict_with_exception
  has_many :employees, through: :memberships
  has_many :messages, dependent: :restrict_with_exception
  validates :name, presence: true, length: { maximum: 120 }
  validates :kind, inclusion: { in: %w[group channel] }
  validates :description, length: { maximum: 5000 }

  private

  def soft_delete_children
    memberships.visible.find_each(&:mark_deleted!)
    messages.visible.find_each(&:mark_deleted!)
  end
end
''')
put('app/models/membership.rb', '''
class Membership < ApplicationRecord
  include SoftDeletable
  belongs_to :employee
  belongs_to :chat
  validates :employee_id, :chat_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :role, inclusion: { in: %w[owner member] }
  validates :muted, inclusion: { in: [true, false] }
  validates :employee_id, uniqueness: { scope: :chat_id, conditions: -> { visible } }, unless: :deleted?
  validates_associated :employee, :chat
  validate :parents_are_visible

  def unread_messages
    relation = chat.messages.visible.where.not(employee_id: employee_id)
    last_read_at ? relation.where("created_at > ?", last_read_at) : relation
  end

  def mark_read!
    update!(last_read_at: Time.current)
  end

  private

  def parents_are_visible
    errors.add(:employee, "is deleted") if employee&.deleted?
    errors.add(:chat, "is deleted") if chat&.deleted?
  end
end
''')
put('app/models/message.rb', '''
class Message < ApplicationRecord
  include SoftDeletable
  belongs_to :employee
  belongs_to :chat
  validates :body, presence: true, length: { maximum: 10000 }
  validates :employee_id, :chat_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates_associated :employee, :chat
  validate :author_is_active_member, on: :create
  validate :parents_are_visible

  private

  def author_is_active_member
    unless Membership.visible.exists?(employee_id: employee_id, chat_id: chat_id)
      errors.add(:employee, "must be a member of this chat")
    end
  end

  def parents_are_visible
    errors.add(:employee, "is deleted") if employee&.deleted?
    errors.add(:chat, "is deleted") if chat&.deleted?
  end
end
''')
put('app/serializers/application_serializer.rb', '''
# Explicit whitelist using Rails' built-in ActiveModel JSON serialization.
class ApplicationSerializer
  def initialize(record)
    @record = record
  end

  def as_json(*)
    @record.serializable_hash(only: self.class::ATTRIBUTES)
  end
end
''')
for model, attrs in {
    'Employee': ['id','name','email','department','bio','deleted'],
    'Chat': ['id','name','kind','description','deleted'],
    'Membership': ['id','employee_id','chat_id','role','muted','last_read_at','deleted'],
    'Message': ['id','employee_id','chat_id','body','created_at','updated_at','deleted'],
}.items():
    put(f'app/serializers/{model.lower()}_serializer.rb', f'''class {model}Serializer < ApplicationSerializer
  ATTRIBUTES = %i[{' '.join(attrs)}].freeze
end
''')
put('app/controllers/application_controller.rb', '''
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
''')
put('app/controllers/api/v1/resources_controller.rb', '''
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
''')
put('app/controllers/api/v1/employees_controller.rb', '''
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
''')
put('app/controllers/api/v1/chats_controller.rb', '''
class Api::V1::ChatsController < Api::V1::ResourcesController
  def employees
    chat = Chat.visible.find(params[:id])
    render_collection(Employee.visible.where(id: chat.memberships.visible.select(:employee_id)).order(:id), key: :employees)
  end

  private

  def resource_params
    payload.permit(:name, :kind, :description)
  end
end
''')
put('app/controllers/api/v1/memberships_controller.rb', '''
class Api::V1::MembershipsController < Api::V1::ResourcesController
  def mark_read
    membership = collection.visible.find(params[:id])
    membership.mark_read!
    render_record(membership)
  end

  def unread_messages
    membership = collection.visible.find(params[:id])
    render_collection(membership.unread_messages.order(:id), key: :messages)
  end

  private

  def collection
    if params[:chat_id]
      Chat.visible.find(params[:chat_id]).memberships
    elsif params[:employee_id]
      Employee.visible.find(params[:employee_id]).memberships
    else
      Membership.all
    end
  end

  def assign_parent(record)
    record.chat_id = params[:chat_id] if params[:chat_id]
    record.employee_id = params[:employee_id] if params[:employee_id]
  end

  def resource_params
    fields = action_name == "create" ? %i[employee_id chat_id role muted] : %i[role muted]
    payload.permit(*fields)
  end
end
''')
put('app/controllers/api/v1/messages_controller.rb', '''
class Api::V1::MessagesController < Api::V1::ResourcesController
  private

  def collection
    if params[:chat_id]
      Chat.visible.find(params[:chat_id]).messages
    elsif params[:employee_id]
      Employee.visible.find(params[:employee_id]).messages
    else
      Message.all
    end
  end

  def assign_parent(record)
    record.chat_id = params[:chat_id] if params[:chat_id]
    record.employee_id = params[:employee_id] if params[:employee_id]
  end

  def resource_params
    fields = action_name == "create" ? %i[employee_id chat_id body] : %i[body]
    payload.permit(*fields)
  end
end
''')
put('config/routes.rb', '''
Rails.application.routes.draw do
  root "application#index"
  get "up" => "rails/health#show"
  scope module: :api do
    namespace :v1, defaults: { format: :json } do
      resources :employees do
        member do
          get :chats
          put :mark_deleted
        end
        resources :memberships, :messages, only: [:index, :show, :create]
      end
      resources :chats do
        member do
          get :employees
          put :mark_deleted
        end
        resources :messages
        resources :memberships
      end
      resources :messages do
        put :mark_deleted, on: :member
      end
      resources :memberships do
        member do
          put :mark_deleted
          put :mark_read
          get :unread_messages
        end
      end
    end
  end
  match "*path", to: "application#catch_404", via: :all
end
''')
put('db/seeds.rb', '''
# Repeatable seeds: update demo records without removing unrelated records.
ApplicationRecord.transaction do
  employees = [
    ["Анна Смирнова", "anna@company.test", "Разработка", "Backend-разработчик"],
    ["Иван Петров", "ivan@company.test", "Разработка", "Frontend-разработчик"],
    ["Мария Соколова", "maria@company.test", "HR", "Кадровые вопросы"],
    ["Алексей Волков", "alex@company.test", "Поддержка", "Техническая поддержка"]
  ].map do |name, email, department, bio|
    employee = Employee.find_or_initialize_by(email: email)
    employee.update!(name: name, department: department, bio: bio, deleted: false)
    employee
  end
  chats = [["Общий", "group"], ["Разработка", "group"], ["Объявления", "channel"]].map do |name, kind|
    chat = Chat.find_or_initialize_by(name: name)
    chat.update!(kind: kind, description: "Учебный корпоративный чат: #{name}", deleted: false)
    chat
  end
  chats.each do |chat|
    employees.each_with_index do |employee, index|
      member = Membership.visible.find_or_initialize_by(chat: chat, employee: employee)
      member.update!(role: index.zero? ? "owner" : "member", muted: false)
    end
  end
  chats.each do |chat|
    ["Добро пожаловать в чат #{chat.name}!", "Обсудим задачи на неделю."].each_with_index do |body, index|
      Message.visible.find_or_create_by!(chat: chat, employee: employees[index], body: body)
    end
  end
end
puts "Seed data: #{Employee.visible.count} employees, #{Chat.visible.count} chats, #{Membership.visible.count} memberships, #{Message.visible.count} messages"
''')
put('script/console_checks.rb', '''
# ruby bin/rails runner script/console_checks.rb
chat = Chat.visible.find_by!(name: "Общий")
puts "Chat: #{chat.name}"
puts "Employees: #{chat.employees.where(memberships: { deleted: false }).visible.pluck(:name).join(', ')}"
puts "Messages: #{chat.messages.visible.pluck(:body).inspect}"
message = chat.messages.visible.first!
puts "Nested find: #{chat.messages.visible.find(message.id).body}"
puts "Author: #{message.employee.name}"
puts "Unread for first member: #{chat.memberships.visible.first!.unread_messages.count}"
''')

# Small code-generated favicon: white chat bubble on blue, no bitmap generation needed.
pixels = bytearray()
for y in range(32):
    pixels.append(0)
    for x in range(32):
        bubble = (5 <= x <= 26 and 7 <= y <= 22) or (8 <= x <= 13 and 22 <= y <= 26 and x-8 <= 26-y)
        pixels.extend((255,255,255,255) if bubble else (37,99,235,255))
def chunk(kind, data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
png = b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',32,32,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(pixels))+chunk(b'IEND',b'')
(ROOT/'public/favicon.ico').write_bytes(struct.pack('<HHH',0,1,1)+struct.pack('<BBBBHHII',32,32,0,0,1,32,len(png),22)+png)
print('Messenger project files created.')
