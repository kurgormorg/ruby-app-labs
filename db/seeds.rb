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
