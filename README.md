# Happy Farm

Клон «Счастливой фермы» (ВКонтакте, 2010-е) для iPhone.

- `server/` — сервер (Node 22, без зависимостей, SQLite). Запуск: `cd server && npm start`, тесты: `npm test`.
- `app/` — клиент на Flutter (iOS). *Пока не создан.*

## API

`POST /register {name}` → `{token, farm}`; дальше заголовок `Authorization: Bearer <token>`.

| Метод | Путь | Описание |
|---|---|---|
| GET | `/catalog` | Список культур |
| GET | `/farm` | Моя ферма |
| POST | `/plant {plot, cropId}` | Посадить |
| POST | `/harvest {plot}` | Собрать урожай |
| POST | `/unlock-plot` | Купить новую грядку |
| GET/POST | `/friends` | Друзья / добавить `{name}` (дружба взаимная) |
| GET | `/friends/:id/farm` | Ферма друга |
| POST | `/friends/:id/steal {plot}` | Украсть у друга (по 10%, максимум 50% с грядки, один раз на вора) |

Время роста считается на сервере, клиенту доверять нельзя.
