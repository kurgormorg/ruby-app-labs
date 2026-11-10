require "test_helper"

class FiltersTest < ActionDispatch::IntegrationTest
  setup do
    @anna = Employee.create!(name: "Anna", email: "anna@filters.test", department: "Engineering")
    @ivan = Employee.create!(name: "Ivan", email: "ivan@filters.test", department: "HR")
    @chat = Chat.create!(name: "Development", kind: "group")
    @channel = Chat.create!(name: "News", kind: "channel")
    @member = Membership.create!(employee: @anna, chat: @chat, role: "owner", muted: true)
    @reader = Membership.create!(employee: @ivan, chat: @chat)
    @message = Message.create!(employee: @anna, chat: @chat, body: "Release 100%_ready")
    @reply = Message.create!(employee: @ivan, chat: @chat, body: "Confirmed")
  end

  test "employee and chat filters combine and ignore case" do
    get "/v1/employees", params: { name: "ANN", department: "engine", email: "filters.test" }
    assert_response :ok
    assert_equal [@anna.id], response.parsed_body["employees"].pluck("id")
    get "/v1/employees", params: { name: "Anna", department: "HR" }
    assert_empty response.parsed_body["employees"]
    get "/v1/chats", params: { name: "new", kind: "channel" }
    assert_equal [@channel.id], response.parsed_body["chats"].pluck("id")
  end

  test "text filters escape SQL patterns and exclude deleted records" do
    get "/v1/messages", params: { body: "%_", employee_id: @anna.id, chat_id: @chat.id }
    assert_response :ok
    assert_equal [@message.id], response.parsed_body["messages"].pluck("id")
    get "/v1/employees", params: { name: "' OR 1=1 --" }
    assert_empty response.parsed_body["employees"]
    @anna.mark_deleted!
    get "/v1/employees", params: { name: "Anna" }
    assert_empty response.parsed_body["employees"]
  end

  test "membership filters handle false and combine within nested routes" do
    get "/v1/memberships", params: { muted: "false", role: "member", employee_id: @ivan.id }
    assert_equal [@reader.id], response.parsed_body["memberships"].pluck("id")
    get "/v1/chats/#{@chat.id}/memberships", params: { muted: "true", role: "owner" }
    assert_equal [@member.id], response.parsed_body["memberships"].pluck("id")
    get "/v1/chats/#{@channel.id}/messages", params: { body: "Release" }
    assert_empty response.parsed_body["messages"]
  end

  test "read and unread filters refer to the supplied member only" do
    get "/v1/messages", params: { read: "false", membership_id: @reader.id }
    assert_equal [@message.id], response.parsed_body["messages"].pluck("id")
    get "/v1/messages", params: { read: "true", membership_id: @reader.id }
    assert_empty response.parsed_body["messages"]
    @reader.mark_read!
    get "/v1/messages", params: { read: "true", membership_id: @reader.id }
    assert_equal [@message.id], response.parsed_body["messages"].pluck("id")
    get "/v1/messages", params: { read: "false", membership_id: @reader.id }
    assert_empty response.parsed_body["messages"]
    get "/v1/messages", params: { read: "false", membership_id: @member.id }
    assert_equal [@reply.id], response.parsed_body["messages"].pluck("id")
  end

  test "malformed filter values return 400 instead of 500" do
    [ ["/v1/messages", { read: "true" }],
      ["/v1/messages", { employee_id: "abc" }],
      ["/v1/messages", { chat_id: "999999999999999999999999" }],
      ["/v1/employees", { name: ["Anna"] }],
      ["/v1/chats", { kind: "invalid" }],
      ["/v1/memberships", { muted: "maybe" }] ].each do |path, filters|
      get path, params: filters
      assert_response :bad_request
    end
  end

  test "serializers use the required library and preserve the field whitelist" do
    assert EmployeeSerializer < ActiveModel::Serializer
    get "/v1/employees/#{@anna.id}"
    assert_response :ok
    assert_equal %w[bio deleted department email id name], response.parsed_body.keys.sort
    assert_equal @anna.id, response.parsed_body["id"]
  end
end
