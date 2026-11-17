# Лабораторная 2 — Sinatra

Выполнены практические задания из файла «2 API Часть 2 Практическое занятие Разработка API с использованием фреймворка Sinatra.docx».

## Установка

Открыть терминал в папке `lab2`:

```powershell
bundle install
```

## Классический стиль

Код: `classic/my_sinatra.rb`. Прямой запуск:

```powershell
./run.ps1 classic
```

Или стандартной командой: `bundle exec ruby classic/my_sinatra.rb`.

Запуск того же приложения через `classic/config.ru`:

```powershell
./run.ps1 classic-rack
```

Стандартная команда: `bundle exec rackup -s puma -p 4567 classic/config.ru`.

Проверить GET `http://localhost:4567/`, `/hello/Peter`, `/friends`, `/api/v1/friends`. Приветствие и ответы совпадают с методичкой. Общий маршрут `/*` расположен последним, чтобы не перехватывать остальные запросы.

## Модульный стиль и маршруты

Код: `modular/my_sinatra.rb`, класс `MyAppModule::App < Sinatra::Base`. Расширение namespace зарегистрировано внутри класса. Сборка Rack — в `modular/config.ru`.

```powershell
./run.ps1 modular-rack
```

Прямой запуск: `./run.ps1 modular` или `bundle exec ruby modular/my_sinatra.rb`.

Все адреса начинаются с `http://localhost:4567`:

| GET | Результат |
| --- | --- |
| `/` | `Hello My Sinatra - Easy and Wide world!` |
| `/hello/Peter` | `Sinatra приветствует тебя, Peter!` |
| `/redirect` | HTTP 302 на `/hello/World`; браузер следует автоматически |
| `/players/football` | `football` — именованный параметр |
| `/players/performances/2016` | `["performances"] 2016` — splat и параметр year |
| `/meta/hello/12345/world` | `Hello, 12345!` — регулярное выражение |
| `/meta/hello/world` | `Hello, world!` |
| `/hello/world/1234` | `Hello, world!` |
| `/say/12345*/to/09876*` | `12345*09876*` — две маски |
| `/download/path/to/file.xml` | `["path/to/file", "xml"]` — путь и расширение |
| `/jobs`, `/jobs.json`, `/jobs.xml` | `Да, работает этот маршрут!` — необязательный формат |
| `/api/v1/friends` | `I don't know what is the ["friends"]. It's what you typed.` — namespace |
| `/friends` | Такой же ответ общего маршрута вне namespace |

Для современного Sinatra регулярное выражение содержит `.*` до и после `/hello/(\w+)`, чтобы работали длинные URL из примеров. Для `/hello/Peter` сначала срабатывает именованный маршрут, поскольку он определён раньше регулярного выражения.

## Заготовка Sinatra + PostgreSQL

Основной файл — `api_sinatra_postgres.rb`, классический стиль. Он подключает Sequel, sequel-seed, pg, JSON и загружает Ruby-файлы из `controllers`, `models`, `routes`. Каталоги `config`, `helpers`, `lib` также созданы. Корневой маршрут находится в `routes/root.rb`.

Используется локальный PostgreSQL первой лабораторной на `127.0.0.1:5434`, роль и пароль `api_admin`. Если он остановлен, из папки `lab2` запустить:

```powershell
pg_ctl -D ../api_rails_pg/.local-postgres -l ../api_rails_pg/log/postgres.log -o "-p 5434 -h 127.0.0.1" -w start
```

Создать отдельную базу и проверить подключение:

```powershell
bundle exec rake db:create db:check
./run.ps1
```

Открыть `http://localhost:4567/`. Ответ:

```text
Hi! I am api_sinatra_postgres!
```

Подключение задаётся в `config/database.rb`; для своего сервера скопировать `.env.example` в `.env` и изменить `DATABASE_URL`. Таблицы, модели предметной области и CRUD в этом документе ещё не задаются.

Перед переключением приложения остановить текущий сервер сочетанием Ctrl+C: все варианты используют порт 4567. Сервер Puma заменяет устаревшие Thin/WEBrick из примеров методички.

## Проверка и RubyMine

```powershell
./check.ps1
```

Проверяются 4 маршрута классического приложения, 14 маршрутов модульного, перенаправление с целевым ответом, корневой маршрут API и подключение к PostgreSQL. Отдельно проверен HTTP-запуск обоих демонстрационных приложений напрямую и через Rack, а также запуск заготовки API через Rack.

Для запросов из редактора есть `requests.http`. В Postman выбрать GET и вставить любой URL из таблицы; для таблицы запустить модульный вариант, для итогового API — `./run.ps1`.

Для запуска из RubyMine открыть `lab2` как проект, выбрать установленный Ruby SDK. В `.run` сохранены конфигурации Classic и Modular. Если IDE не подхватила их, Run → Edit Configurations → Ruby: Ruby script — `classic/my_sinatra.rb` или `modular/my_sinatra.rb`, Working directory — папка `lab2`, Ruby arguments — `-E UTF-8:UTF-8`. Затем Apply → OK → Run. Заготовку API запускать в терминале командой `./run.ps1`.
