# Корпоративный мессенджер — Rails API + PostgreSQL

Практические задания глав 2–7 из «1 API Часть 1 — Rails + PG».
Тема: корпоративный мессенджер. Ruby 3.4, Rails 8.1, PostgreSQL 18.

## Запуск на Windows

Ruby, Bundler и PostgreSQL должны быть доступны в PATH.
Из папки проекта:

```powershell
.\setup.ps1
.\rails.ps1 server -b 127.0.0.1 -p 3000
```

API: http://127.0.0.1:3000. Favicon: `/favicon.ico`.
`rails.ps1` обходит ошибку Ruby при запуске из пути с кириллицей.
Bootsnap отключён, поскольку его нативный кеш не открывает этот путь.

Учебный кластер находится в `.local-postgres`, слушает только 127.0.0.1:5433
и не меняет существующий сервер на 5432. Подключение требует пароль (SCRAM-SHA-256).
Роль `messenger_admin` имеет LOGIN, SUPERUSER, CREATEDB, CREATEROLE, как в задании.
Её сгенерированный пароль хранится в исключённом из Git `config/secrets.yml`.
Там же отдельно хранится пароль администратора учебного кластера.
Базы: `corporate_messenger_development`, `corporate_messenger_test`,
`corporate_messenger_production`. Параметры подключения можно переопределить
через PGHOST, PGPORT, PGUSER, PGPASSWORD или DATABASE_URL.

Остановить/запустить учебный PostgreSQL:

```powershell
pg_ctl -D .local-postgres -m fast -w stop
pg_ctl -D .local-postgres -l log/postgresql.log -o "-h 127.0.0.1 -p 5433" -w start
```

## Практические задания по главам

| Глава | Файлы и команды |
|---|---|
| 2. API-проект и гемы | `config/application.rb` (`api_only = true`), `Gemfile`, `Gemfile.lock`, `config/puma.rb` (порт 3000) |
| 3. PostgreSQL, роль, три БД | `config/database.yml`, `script/bootstrap_database.rb`, `setup.ps1` |
| 3. Git и favicon | `.gitignore` исключает секреты и `.idea`; `public/favicon.ico`; для GitHub см. ниже |
| 4. Миграции и модели | `db/migrate`, `app/models`: Employee, Chat, Membership, Message |
| 4. Связи и валидация | `belongs_to`, `has_many`, `through`, presence, length, numericality, inclusion, uniqueness, validates_associated |
| 4. Начальные данные | `db/seeds.rb`: 4 сотрудника, 3 чата, 12 участий, 6 сообщений; повторная загрузка не дублирует демонстрационные данные |
| 4. Версионирование и маршруты | `config/routes.rb`, `app/controllers/api/v1` — `/v1/...` |
| 5. JSON, ошибки, CRUD | `application_controller.rb`, контроллеры API, `app/serializers`; ответы 200, 201, 404, 422 |
| 6. HTTP, консоль, Postman | `postman/corporate_messenger.postman_collection.json`, `script/console_checks.rb`, `test/integration/messenger_api_test.rb` |
| 7. Удаление без потери записей | отдельная миграция `AddSoftDeletion`, `SoftDeletable`, `DELETE` и `PUT .../mark_deleted` |

Отдельные команды:

```powershell
.\rails.ps1 db:migrate
.\rails.ps1 db:seed
.\rails.ps1 routes
.\rails.ps1 middleware
.\rails.ps1 console
.\rails.ps1 runner script/console_checks.rb
.\rails.ps1 db:test:prepare
.\rails.ps1 test
ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'script/check_database_auth.rb')"
```

Связи для проверки в консоли:

```ruby
chat = Chat.visible.find_by!(name: "Общий")
chat.messages.visible
chat.messages.visible.find(chat.messages.visible.first.id)
chat.memberships.visible
employee = Employee.visible.first
employee.messages.visible
employee.memberships.visible.first.unread_messages
```

## Маршруты

Для `/v1/employees`, `/v1/chats`, `/v1/memberships`, `/v1/messages`:
GET списка, POST создания; GET, PUT/PATCH, DELETE по `/:id`.
DELETE устанавливает `deleted = true`, повторное удаление возвращает
`already_deleted = true`; удалённые записи скрыты из чтения.
PUT `/:id/mark_deleted` делает то же самое.

| Метод | Путь | Результат |
|---|---|---|
| GET | `/v1/chats/:id/employees` | Сотрудники чата |
| GET | `/v1/employees/:id/chats` | Чаты сотрудника |
| GET/POST | `/v1/chats/:chat_id/messages` | Сообщения чата / отправка сообщения |
| GET/PUT/PATCH/DELETE | `/v1/chats/:chat_id/messages/:id` | Сообщение именно этого чата |
| GET/POST | `/v1/chats/:chat_id/memberships` | Участия в чате / добавление участника |
| GET/PUT/PATCH/DELETE | `/v1/chats/:chat_id/memberships/:id` | Участие именно в этом чате |
| GET/POST | `/v1/employees/:employee_id/messages` | Сообщения сотрудника / отправка |
| GET/POST | `/v1/employees/:employee_id/memberships` | Участия сотрудника / вступление |
| GET | `/v1/memberships/:id/unread_messages` | Чужие сообщения после last_read_at |
| PUT | `/v1/memberships/:id/mark_read` | Обновить время прочтения участника |

JSON можно передавать плоским объектом или под ключом модели.
Автор и чат сообщения задаются при создании, при редактировании изменяется только body.
Автор должен быть действующим участником чата. Активное участие уникально для пары
сотрудник–чат. После выхода можно вступить снова. При удалении чата мягко удаляются
сообщения и участия; при удалении сотрудника — его сообщения и участия.
Прочтение хранится отдельно для каждого участника и не учитывает его собственные сообщения.

Фильтры списков можно комбинировать:

| Ресурс | Параметры |
|---|---|
| `/v1/employees` | `name`, `department`, `email` — поиск части строки без учёта регистра |
| `/v1/chats` | `name` — поиск, `kind=group` или `kind=channel` |
| `/v1/messages` | `body` — поиск, `employee_id`, `chat_id`, `read=true/false` вместе с `membership_id` |
| `/v1/memberships` | `employee_id`, `chat_id`, `role=owner/member`, `muted=true/false` |

Например: `/v1/employees?name=анна&department=разработка`,
`/v1/chats/1/messages?body=задачи`,
`/v1/messages?read=false&membership_id=2`.
Прочтение определяется относительно указанного участия, собственные сообщения исключаются.
Фильтры действуют и на списки сообщений/участий во вложенных маршрутах.
Неправильные значения фильтров возвращают HTTP 400.

Это учебный REST API по заданию: идентификатор сотрудника передаётся явно;
вход в систему, проверка прав пользователя, WebSocket и интерфейс не входят в работу.

## Postman

Импортировать JSON из `postman`, затем запустить всю коллекцию по порядку
через Collection Runner. `base_url` по умолчанию `http://127.0.0.1:3000`.
56 запросов создают собственные записи, проверяют CRUD, фильтрацию, ошибки, прочтение
и мягкое удаление. Идентификаторы сохраняются автоматически.
Для запуска через Newman:

```powershell
npm exec --yes --package=newman -- newman run postman/corporate_messenger.postman_collection.json
```

В RubyMine открыть именно каталог `web_api_pg` и выбрать Ruby SDK
`D:\Ruby34-x64\bin\ruby.exe` в настройках Ruby SDK and Gems.
В `.run` сохранены конфигурации `Messenger API` (порт 3000) и `Messenger Tests`.
Их точки входа обходят проблему кириллицы в пути. Перед запуском выполнить `setup.ps1`.
В `.idea/dataSources.xml` подготовлено локальное подключение к PostgreSQL:
127.0.0.1, порт 5433, база corporate_messenger_development, пользователь messenger_admin.
Для Test Connection ввести пароль из `config/secrets.yml`; при запросе IDE загрузить JDBC-драйвер.
Пароль в конфигурацию IDE и Git не записывается. SDK и Test Connection нужно подтвердить в интерфейсе IDE.
Для встроенного HTTP-клиента использовать `requests.http`.
Регистрация в Postman и настройка личного RubyMine выполняются в пользовательских аккаунтах.

## GitHub

Репозиторий задания: https://github.com/kurgormorg/ruby-app-labs.
Локальная ветка — `main`. Проверка подключения и отправка следующих изменений:

```powershell
git remote -v
git push -u origin main
```

Секреты, локальные БД и журналы не публикуются.

При адаптации примеров использована официальная документация:
[Rails API](https://guides.rubyonrails.org/api_app.html),
[валидации Active Record](https://guides.rubyonrails.org/active_record_validations.html).
Сериализаторы наследуются от `ActiveModel::Serializer` из гема
`active_model_serializers` и объявляют поля через `attributes`, как в методичке.
Ошибки возвращают настоящий
HTTP-статус, а вложенный маршрут проверяет принадлежность записи родителю.
