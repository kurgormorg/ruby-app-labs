require "test_helper"

class MessengerApiTest < ActionDispatch::IntegrationTest
  setup do
    @anna = Employee.create!(name: "Anna", email: "anna@test.example", department: "IT")
    @ivan = Employee.create!(name: "Ivan", email: "ivan@test.example", department: "IT")
    @chat = Chat.create!(name: "Development", kind: "group")
    @other_chat = Chat.create!(name: "HR", kind: "channel")
    @member = Membership.create!(employee: @anna, chat: @chat, role: "owner")
    @other_member = Membership.create!(employee: @ivan, chat: @chat)
    @message = Message.create!(employee: @anna, chat: @chat, body: "Hello")
  end

  test "CRUD for employees validates and serializes data" do
    post "/v1/employees", params: { name: "Maria", email: "MARIA@test.example", department: "HR" }, as: :json
    assert_response :created
    id = response.parsed_body.fetch("id")
    assert_equal "maria@test.example", response.parsed_body["email"]
    assert_not response.parsed_body.key?("created_at")
    get "/v1/employees/#{id}"
    assert_response :ok
    put "/v1/employees/#{id}", params: { employee: { bio: "Recruiter" } }, as: :json
    assert_response :ok
    assert_equal "Recruiter", response.parsed_body["bio"]
    get "/v1/employees"
    assert_equal 3, response.parsed_body["employees"].length
    delete "/v1/employees/#{id}"
    assert_response :ok
    assert Employee.find(id).deleted?
    get "/v1/employees/#{id}"
    assert_response :not_found
  end

  test "CRUD for chats and membership data" do
    post "/v1/chats", params: { name: "New chat", kind: "channel" }, as: :json
    assert_response :created
    id = response.parsed_body.fetch("id")
    patch "/v1/chats/#{id}", params: { description: "News" }, as: :json
    assert_response :ok
    assert_equal "News", response.parsed_body["description"]
    get "/v1/chats/#{id}"
    assert_response :ok
    get "/v1/chats"
    assert_equal 3, response.parsed_body["chats"].size
    post "/v1/chats/#{id}/memberships", params: { employee_id: @anna.id, role: "member" }, as: :json
    assert_response :created
    member_id = response.parsed_body.fetch("id")
    put "/v1/memberships/#{member_id}", params: { muted: true }, as: :json
    assert_response :ok
    assert_equal true, response.parsed_body["muted"]
    get "/v1/memberships/#{member_id}"
    assert_response :ok
    get "/v1/memberships"
    assert_equal 3, response.parsed_body["memberships"].size
    delete "/v1/memberships/#{member_id}"
    assert_response :ok
    assert Membership.find(member_id).deleted?
    delete "/v1/chats/#{id}"
    assert_response :ok
    assert Chat.find(id).deleted?
  end

  test "nested message CRUD fixes chat and author identifiers" do
    post "/v1/chats/#{@chat.id}/messages", params: { chat_id: @other_chat.id, employee_id: @ivan.id, body: "New" }, as: :json
    # The route parent always takes precedence, including a conflicting JSON attribute.
    assert_response :created
    id = response.parsed_body.fetch("id")
    assert_equal @chat.id, Message.find(id).chat_id
    put "/v1/chats/#{@chat.id}/messages/#{id}", params: { body: "Edited", employee_id: @anna.id }, as: :json
    assert_response :ok
    assert_equal "Edited", Message.find(id).body
    assert_equal @ivan.id, Message.find(id).employee_id
    get "/v1/chats/#{@chat.id}/messages/#{id}"
    assert_response :ok
    delete "/v1/chats/#{@chat.id}/messages/#{id}"
    assert_response :ok
    assert Message.find(id).deleted?
  end

  test "nested identifiers cannot access another chat message or member" do
    get "/v1/chats/#{@other_chat.id}/messages/#{@message.id}"
    assert_response :not_found
    delete "/v1/chats/#{@other_chat.id}/memberships/#{@member.id}"
    assert_response :not_found
    assert_not @member.reload.deleted?
  end

  test "collections and associations follow employees and chats" do
    get "/v1/chats/#{@chat.id}/messages"
    assert_equal [@message.id], response.parsed_body["messages"].pluck("id")
    get "/v1/chats/#{@other_chat.id}/messages"
    assert_empty response.parsed_body["messages"]
    get "/v1/employees/#{@anna.id}/chats"
    assert_equal [@chat.id], response.parsed_body["chats"].pluck("id")
    get "/v1/chats/#{@chat.id}/employees"
    assert_equal [@anna.id, @ivan.id], response.parsed_body["employees"].pluck("id")
    get "/v1/employees/#{@anna.id}/messages"
    assert_equal [@message.id], response.parsed_body["messages"].pluck("id")
    get "/v1/chats/#{@chat.id}/memberships"
    assert_equal 2, response.parsed_body["memberships"].size
  end

  test "invalid records return 422 without writing to database" do
    assert_no_difference "Message.count" do
      post "/v1/messages", params: { body: "Missing associations" }, as: :json
      assert_response :unprocessable_entity
      assert response.parsed_body.fetch("errors").key?("chat_id")
    end
    post "/v1/employees", params: { name: "", email: "bad", department: "" }, as: :json
    assert_response :unprocessable_entity
    post "/v1/chats", params: { name: "Bad", kind: "unknown" }, as: :json
    assert_response :unprocessable_entity
    put "/v1/memberships/#{@member.id}", params: { role: "admin", muted: nil }, as: :json
    assert_response :unprocessable_entity
    put "/v1/messages/#{@message.id}", params: { body: "x" * 10001 }, as: :json
    assert_response :unprocessable_entity
    assert_equal "Hello", @message.reload.body
  end

  test "nonmember cannot send and deleted parents cannot be used" do
    post "/v1/messages", params: { chat_id: @other_chat.id, employee_id: @anna.id, body: "No membership" }, as: :json
    assert_response :unprocessable_entity
    @ivan.mark_deleted!
    post "/v1/memberships", params: { chat_id: @other_chat.id, employee_id: @ivan.id }, as: :json
    assert_response :unprocessable_entity
  end

  test "duplicate active memberships rejected and rejoining allowed" do
    post "/v1/memberships", params: { chat_id: @chat.id, employee_id: @anna.id }, as: :json
    assert_response :unprocessable_entity
    delete "/v1/memberships/#{@member.id}"
    post "/v1/memberships", params: { chat_id: @chat.id, employee_id: @anna.id }, as: :json
    assert_response :created
    assert_equal 2, Membership.where(chat: @chat, employee: @anna).count
  end

  test "read state is individual excludes own messages and includes future messages" do
    get "/v1/memberships/#{@other_member.id}/unread_messages"
    assert_equal [@message.id], response.parsed_body["messages"].pluck("id")
    get "/v1/memberships/#{@member.id}/unread_messages"
    assert_empty response.parsed_body["messages"]
    put "/v1/memberships/#{@other_member.id}/mark_read"
    assert_response :ok
    assert_not_nil @other_member.reload.last_read_at
    get "/v1/memberships/#{@other_member.id}/unread_messages"
    assert_empty response.parsed_body["messages"]
    travel 1.second do
      new_message = Message.create!(chat: @chat, employee: @anna, body: "Later")
      get "/v1/memberships/#{@other_member.id}/unread_messages"
      assert_equal [new_message.id], response.parsed_body["messages"].pluck("id")
    end
    assert_nil @member.reload.last_read_at
  end

  test "chat soft deletion cascades preserves rows and is idempotent" do
    before = [Chat.count, Membership.count, Message.count]
    put "/v1/chats/#{@chat.id}/mark_deleted"
    assert_response :ok
    assert @chat.reload.deleted?
    assert @member.reload.deleted?
    assert @message.reload.deleted?
    assert_equal before, [Chat.count, Membership.count, Message.count]
    delete "/v1/chats/#{@chat.id}"
    assert_response :ok
    assert response.parsed_body["already_deleted"]
    get "/v1/chats/#{@chat.id}/messages"
    assert_response :not_found
    get "/v1/messages"
    assert_empty response.parsed_body["messages"]
    assert_not @anna.reload.deleted?
  end

  test "employee deletion cascades to authored messages and memberships" do
    delete "/v1/employees/#{@anna.id}"
    assert_response :ok
    assert @anna.reload.deleted?
    assert @member.reload.deleted?
    assert @message.reload.deleted?
    assert_not @chat.reload.deleted?
    get "/v1/chats/#{@chat.id}/employees"
    assert_equal [@ivan.id], response.parsed_body["employees"].pluck("id")
  end

  test "unknown routes and absent records produce JSON with HTTP 404" do
    get "/missing"
    assert_response :not_found
    assert_equal "no_route", response.parsed_body["status"]
    get "/v1/messages/999999"
    assert_response :not_found
    assert_equal "not_found", response.parsed_body["status"]
    assert_equal "application/json", response.media_type
  end
end
