# Neighbours

Friends list: add a neighbour by name (friendship is mutual), open their farm, steal from ripe
plots.

## Sub-features

- «Соседи» button in the bottom bar opens the list (AppBar «Соседи»).
- Empty state «Пока нет соседей. Добавьте друга по имени.».
- «Имя соседа» field + «Добавить»: unknown name «Игрок не найден», own name
  «Нельзя дружить с самим собой»; the text stays on failure.
- Rows: name, «Уровень N»; tapping opens the neighbour's farm (stealing, not mapped yet).

## How to get to it (user POV)

Signed in, tap «Соседи». A neighbour must exist: `registerViaApi(uniqueName('nb'))` in the arrange block.

## Driving it with e2e

`e2e/tests/friends.e2e.ts`. Locators: `getByTestId('open-friends')`,
`getByTestId('friend-name')` (field), `getByTestId('friend-add')` (button),
`getByText(<neighbour name>)`, `getByText('Уровень 1')`.

## Proof

The neighbour's row appears with «Уровень 1» and the field is cleared. Server: `GET /friends`
with either player's token lists the other (mutual).

## Charters

```
neighbours-add|ios|fuzzer|Starting on the neighbours screen of a new farm, add an unknown name, your own name, an empty name, the same neighbour twice, and a real neighbour; report wrong, missing, or English errors
```

## Gotchas

- A second player only exists if a test creates it over HTTP (`registerViaApi`); the database
  is empty on every run.
