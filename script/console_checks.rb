# ruby bin/rails runner script/console_checks.rb
chat = Chat.visible.find_by!(name: "Общий")
puts "Chat: #{chat.name}"
puts "Employees: #{chat.employees.where(memberships: { deleted: false }).visible.pluck(:name).join(', ')}"
puts "Messages: #{chat.messages.visible.pluck(:body).inspect}"
message = chat.messages.visible.first!
puts "Nested find: #{chat.messages.visible.find(message.id).body}"
puts "Author: #{message.employee.name}"
puts "Unread for first member: #{chat.memberships.visible.first!.unread_messages.count}"
