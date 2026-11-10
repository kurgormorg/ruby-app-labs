from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
items = []

def request(name, method, path, status=200, body=None, extra=()):
    tests = [f"pm.test('HTTP {status}', () => pm.response.to.have.status({status}));",
             "pm.test('JSON response', () => pm.expect(pm.response.headers.get('Content-Type')).to.include('application/json'));", *extra]
    req = {"method": method, "header": [], "url": "{{base_url}}" + path}
    if body is not None:
        req['header'] = [{"key": "Content-Type", "value": "application/json"}]
        req['body'] = {"mode": "raw", "raw": json.dumps(body, ensure_ascii=False), "options": {"raw": {"language": "json"}}}
    items.append({"name": name, "request": req, "event": [{"listen": "test", "script": {"type": "text/javascript", "exec": tests}}]})

def save(var):
    return [f"pm.collectionVariables.set('{var}', pm.response.json().id);"]

request('API доступен', 'GET', '/')
for resource in ['employees', 'chats', 'memberships', 'messages']:
    request('Все записи: ' + resource, 'GET', '/v1/' + resource,
            extra=[f"pm.test('Collection', () => pm.expect(pm.response.json().{resource}).to.be.an('array'));"])
request('Создать сотрудника', 'POST', '/v1/employees', 201,
        {'name': 'Тестовый сотрудник', 'email': 'first.{{run_id}}@company.test', 'department': 'Разработка', 'bio': 'Тест API'}, save('employee_id'))
request('Создать второго сотрудника', 'POST', '/v1/employees', 201,
        {'name': 'Второй сотрудник', 'email': 'second.{{run_id}}@company.test', 'department': 'HR'}, save('second_employee_id'))
request('Создать чат', 'POST', '/v1/chats', 201, {'name': 'Чат {{run_id}}', 'kind': 'group'}, save('chat_id'))
request('Добавить владельца', 'POST', '/v1/chats/{{chat_id}}/memberships', 201,
        {'employee_id': '{{employee_id}}', 'role': 'owner'}, save('membership_id'))
request('Добавить второго участника', 'POST', '/v1/memberships', 201,
        {'employee_id': '{{second_employee_id}}', 'chat_id': '{{chat_id}}'}, save('second_membership_id'))
request('Отправить сообщение', 'POST', '/v1/chats/{{chat_id}}/messages', 201,
        {'employee_id': '{{employee_id}}', 'body': 'Первое сообщение'}, save('message_id'))
for singular in ['employee', 'chat', 'membership', 'message']:
    plural = singular + 's'
    request('Найти: ' + singular, 'GET', f'/v1/{plural}/{{{{{singular}_id}}}}')
for label, path in [
    ('Сообщения чата', '/v1/chats/{{chat_id}}/messages'),
    ('Участия в чате', '/v1/chats/{{chat_id}}/memberships'),
    ('Сотрудники чата', '/v1/chats/{{chat_id}}/employees'),
    ('Чаты сотрудника', '/v1/employees/{{employee_id}}/chats'),
    ('Сообщения сотрудника', '/v1/employees/{{employee_id}}/messages'),
    ('Участия сотрудника', '/v1/employees/{{employee_id}}/memberships'),
    ('Одно сообщение в чате', '/v1/chats/{{chat_id}}/messages/{{message_id}}'),
]:
    request(label, 'GET', path)
request('Изменить сотрудника', 'PUT', '/v1/employees/{{employee_id}}', body={'bio': 'Обновлено'})
request('Изменить чат', 'PUT', '/v1/chats/{{chat_id}}', body={'description': 'Обновлено'})
request('Отключить уведомления', 'PUT', '/v1/memberships/{{membership_id}}', body={'muted': True})
request('Изменить сообщение', 'PUT', '/v1/messages/{{message_id}}', body={'body': 'Исправленное сообщение'})
request('Ошибка: отсутствует chat_id', 'POST', '/v1/messages', 422,
        {'employee_id': '{{employee_id}}', 'body': 'Ошибка'}, ["pm.test('Validation errors', () => pm.expect(pm.response.json().errors).to.have.property('chat_id'));"])
request('Ошибка: пустое сообщение', 'POST', '/v1/chats/{{chat_id}}/messages', 422,
        {'employee_id': '{{employee_id}}', 'body': ''})
request('Ошибка: повторное участие', 'POST', '/v1/memberships', 422,
        {'employee_id': '{{employee_id}}', 'chat_id': '{{chat_id}}'})
request('Ошибка: неправильный email', 'POST', '/v1/employees', 422,
        {'name': 'Test', 'email': 'invalid', 'department': 'IT'})
request('Ошибка: неизвестный маршрут', 'GET', '/unknown', 404)
request('Ошибка: запись не существует', 'GET', '/v1/messages/999999999', 404)
request('Непрочитанные сообщения второго участника', 'GET', '/v1/memberships/{{second_membership_id}}/unread_messages',
        extra=["pm.test('One unread message', () => pm.expect(pm.response.json().messages.length).to.eql(1));"])
request('Фильтр сотрудников по email и отделу', 'GET', '/v1/employees?email=first.{{run_id}}&department=Разработка',
        extra=["pm.test('Filtered employee', () => pm.expect(pm.response.json().employees.map(x => x.id)).to.eql([Number(pm.collectionVariables.get('employee_id'))]));"])
request('Фильтр чатов по названию и типу', 'GET', '/v1/chats?name={{run_id}}&kind=group',
        extra=["pm.test('Filtered chat', () => pm.expect(pm.response.json().chats.map(x => x.id)).to.eql([Number(pm.collectionVariables.get('chat_id'))]));"])
request('Фильтр участий по роли и уведомлениям', 'GET', '/v1/memberships?chat_id={{chat_id}}&muted=false&role=member',
        extra=["pm.test('Filtered membership', () => pm.expect(pm.response.json().memberships.map(x => x.id)).to.eql([Number(pm.collectionVariables.get('second_membership_id'))]));"])
request('Поиск по тексту сообщения', 'GET', '/v1/chats/{{chat_id}}/messages?body=Исправленное',
        extra=["pm.test('Filtered message', () => pm.expect(pm.response.json().messages.map(x => x.id)).to.eql([Number(pm.collectionVariables.get('message_id'))]));"])
request('Фильтр непрочитанных', 'GET', '/v1/messages?read=false&membership_id={{second_membership_id}}',
        extra=["pm.test('Unread filter', () => pm.expect(pm.response.json().messages.length).to.eql(1));"])
request('Ошибочное значение фильтра', 'GET', '/v1/memberships?muted=maybe', 400)
request('Пометить прочитанными', 'PUT', '/v1/memberships/{{second_membership_id}}/mark_read')
request('Фильтр прочитанных', 'GET', '/v1/messages?read=true&membership_id={{second_membership_id}}',
        extra=["pm.test('Read filter', () => pm.expect(pm.response.json().messages.length).to.eql(1));"])
request('Проверить отсутствие непрочитанных', 'GET', '/v1/memberships/{{second_membership_id}}/unread_messages',
        extra=["pm.test('No unread messages', () => pm.expect(pm.response.json().messages).to.be.empty);"])
request('Мягкое удаление сообщения', 'DELETE', '/v1/messages/{{message_id}}',
        extra=["pm.test('Deleted flag', () => pm.expect(pm.response.json().deleted_record.deleted).to.eql(true));"])
request('Повторное удаление', 'DELETE', '/v1/messages/{{message_id}}',
        extra=["pm.test('Idempotent deletion', () => pm.expect(pm.response.json().already_deleted).to.eql(true));"])
request('Удалённое сообщение скрыто', 'GET', '/v1/messages/{{message_id}}', 404)
request('Второе сообщение для каскада', 'POST', '/v1/messages', 201,
        {'employee_id': '{{employee_id}}', 'chat_id': '{{chat_id}}', 'body': 'Каскадное удаление'}, save('cascade_message_id'))
request('Удаление участия', 'DELETE', '/v1/memberships/{{second_membership_id}}')
request('Удалённое участие скрыто', 'GET', '/v1/memberships/{{second_membership_id}}', 404)
request('Пометка чата deleted через PUT', 'PUT', '/v1/chats/{{chat_id}}/mark_deleted')
request('Чат скрыт', 'GET', '/v1/chats/{{chat_id}}', 404)
request('Сообщение удалено каскадом', 'GET', '/v1/messages/{{cascade_message_id}}', 404)
request('Участие удалено каскадом', 'GET', '/v1/memberships/{{membership_id}}', 404)
request('Повторное удаление чата через DELETE', 'DELETE', '/v1/chats/{{chat_id}}')
request('Удалить сотрудника', 'DELETE', '/v1/employees/{{employee_id}}')
request('Удалить второго сотрудника', 'DELETE', '/v1/employees/{{second_employee_id}}')
request('Удалённый сотрудник скрыт', 'GET', '/v1/employees/{{employee_id}}', 404)

collection = {
    'info': {'name': 'Корпоративный мессенджер — практические задания, главы 4–7',
             'schema': 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
             'description': 'Запускать всю коллекцию по порядку. Создаёт собственные тестовые записи и мягко удаляет их в конце. Главы 2–3: настройка проекта и БД.'},
    'variable': [{'key': 'base_url', 'value': 'http://127.0.0.1:3000'}],
    'event': [{'listen': 'prerequest', 'script': {'type': 'text/javascript', 'exec': [
        "if (pm.info.requestName === 'API доступен') pm.collectionVariables.set('run_id', Date.now().toString() + Math.random().toString(16).slice(2));"
    ]}}],
    'item': [{'name': 'Глава 6 — GET, POST, PUT, проверки ошибок', 'item': items[:33]},
             {'name': 'Главы 5–7 — прочтение и мягкое удаление', 'item': items[33:]}]
}
directory = root / 'postman'
directory.mkdir(exist_ok=True)
(directory/'corporate_messenger.postman_collection.json').write_text(json.dumps(collection, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Created Postman collection: {len(items)} requests.')
