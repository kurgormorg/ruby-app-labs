# Rails + PostgreSQL: практические задания, часть 1

API сервиса вакансий из методички: компании, вакансии, соискатели и отклики. Ruby 3.4, Rails 8.1, PostgreSQL. Только API, без интерфейса и авторизации.

## Запуск на Windows

Из папки `api_rails_pg` в PowerShell:

```powershell
./setup.ps1
./rails.ps1 server
```

Нужны Ruby, установленные гемы из Gemfile и PostgreSQL (`initdb`, `pg_ctl`) в PATH. Если гемов ещё нет, сначала выполнить `bundle install` без `--local`.

`setup.ps1` создаёт отдельный локальный кластер `.local-postgres` на `127.0.0.1:5434`, роль `api_admin` с паролем `api_admin` и правами SUPERUSER, CREATEDB, CREATEROLE по заданию. Создаются и мигрируются базы `api_rails_pg_development`, `api_rails_pg_test`, `api_rails_pg_production`. Повторный запуск `setup.ps1` перезагружает учебные данные development.

Пароль хранится в исключённом из Git `config/secrets.yml`; образец — `config/secrets.yml.example`. В Rails 8 файл читается через `config_for(:secrets)`. Подключение можно переопределить переменными `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`. Production использует пароль из `PGPASSWORD`.

Остановить локальную базу: `pg_ctl -D .local-postgres stop`. Запустить её повторно: `ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'script/bootstrap_database.rb')"`.

## Запросы

Адрес API: `http://localhost:3000/v1`. Параметры передаются в строке запроса или плоским JSON с `Content-Type: application/json`.

Для `companies`, `jobs`, `geeks`, `applies` есть стандартные GET списка, GET `/:id`, POST, PUT/PATCH `/:id`, DELETE `/:id`.

| Запрос | Назначение |
| --- | --- |
| GET /companies?name=MoGo&location=New%20York | Фильтр компаний |
| GET /jobs?name=React&place=Remote | Фильтр вакансий |
| GET /geeks?name=Mike&stack=Sinatra%20React | Фильтр соискателей |
| GET /applies?job_id=1&geek_id=1&read=true&invited=true | Фильтр откликов; каждый параметр необязателен |
| GET /companies/4/jobs | Вакансии компании; поддерживается вложенный CRUD |
| GET /companies/4/applies | Отклики на все вакансии компании |
| GET /jobs/1/applies | Отклики на вакансию; поддерживается вложенный CRUD |
| GET /geeks/1/applies | Отклики соискателя; поддерживается вложенный CRUD |
| GET /jobs/1/geeks | Откликнувшиеся соискатели |
| GET /jobs/1/invited_geeks | Приглашённые соискатели |
| GET /geeks/1/jobs | Вакансии, на которые откликнулся соискатель |
| GET /geeks/1/invited_jobs | Вакансии с приглашением |
| GET /geeks/1/companies | Компании, куда откликнулся соискатель |
| PUT /geeks/1/resume | Обновление резюме: `{"resume":"Ruby developer"}` |
| PUT /applies/1/mark_read | Отметка прочтения |
| PUT /applies/1/invite | Приглашение на собеседование |
| PUT /companies/4/mark_deleted | Логическое удаление компании |

DELETE вакансии выставляет `deleted=true`, сохраняя запись и отклики. DELETE компании, соискателя или отклика удаляет запись физически; связанные зависимые записи удаляются через ассоциации. Логическое удаление компании выполняется отдельным `mark_deleted`, как в главе 7. Помеченные записи остаются доступны для проверки признака `deleted`.

Списки возвращаются в ключах `companies`, `jobs`, `geeks`, `applies`. JobSerializer показывает `name`, `place`, `company_id`, как в методичке; POST вакансии дополнительно возвращает ID и даты, как в её примере. Остальные сериализаторы включают ID и предметные поля без дат. Ошибки: HTTP 404 с JSON для отсутствующей записи/маршрута, HTTP 422 с `errors` для некорректных данных, HTTP 201 при создании.

## Проверка практических заданий

```powershell
./rails.ps1 test
./rails.ps1 zeitwerk:check
./rails.ps1 runner script/console_checks.rb
./rails.ps1 console
```

В консоли: `company = Company.find(4)`, `company.jobs`, `company.jobs.find(6)`.

Для браузера: `/v1/companies`, `/v1/companies/4`, `/v1/companies/4/jobs`, `/v1/companies/4/jobs/6`, `/v1/jobs`. В примере методички `/companies/4/jobs/2` вакансия принадлежит другой компании, поэтому корректный результат здесь 404.

В Postman импортировать `postman/rails_pg.postman_collection.json`. В коллекции есть GET из методички, CRUD всех моделей, запрос с ошибкой валидации и логическое удаление с повторным вызовом. Запускать коллекцию последовательно после `./rails.ps1 db:seed`; запросы используют переменные ID созданных записей. После проверки восстановить исходные данные той же командой.

В RubyMine открыть эту папку, выбрать Ruby SDK и запуск Rails на порту 3000. Для подключения Database: PostgreSQL, host `127.0.0.1`, port `5434`, user/password `api_admin`, database `api_rails_pg_development`. Нажать Test Connection. Файл `public/favicon.ico` добавлен.

В seeds загружаются 4 компании, 7 вакансий, 9 соискателей и 4 отклика. Поле `resume` заполнено текстом согласно типу модели вместо boolean из примера. Ассоциации `belongs_to :job` и `belongs_to :geek` записаны в единственном числе; опечатки маршрутов из методички исправлены.
