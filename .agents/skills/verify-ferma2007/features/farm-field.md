# Farm field

The isometric farm: 24 plots (6 open at start), animal pens, and the HUD above it. Tapping a plot
does what its state allows.

## Sub-features

- Empty plot → seed list (bottom sheet): «Редис» 10 coins / 60 s, «Пшеница» 20 / 5 min, higher
  crops locked by level («Откроется на уровне N»).
- Growing plot → toast «Созреет через N с» (or «мин»).
- Ripe plot → harvest, toast «+N монет, +N опыта».
- Locked plot → «Купить грядку?» dialog for 500 coins.
- HUD: level star (`hud-level`), name (`hud-name`), coins (`hud-coins`), XP bar.

## How to get to it (user POV)

Sign in with a new name; the farm is the home screen.

## Driving it with e2e

`e2e/tests/farm.agent.e2e.ts`. The field is a Flame canvas with no accessibility nodes, so
plot taps are `agent.act` goals ('plant Редис on an empty plot', 'tap the plot where Редис is
growing'); the bottom sheet, dialog and toast are native and exact
(`screen.getByText('Редис')`, `getByText(/^Созреет через \d+ с$/)`). Pin outcomes on
`getByTestId('hud-coins')` (200 → 190 after radish). Live: `observe` shows the HUD and the
bottom bar only; take a screenshot to see plots.

## Proof

Coins drop by the seed price and the plot shows a sprout. Server: `GET /farm` with the
farmer's token lists the plot with `cropId: "radish"` and a `readyAt`.

## Charters

```
field-economy|ios|skeptic|Starting on a new farm, plant radish and wheat, wait for the radish and harvest it; cross-check coins, XP and level in the HUD against every price and reward shown
field-locked|ios|default|Starting on a new farm, tap locked plots and plots already planted, and try to buy a plot without enough coins; report missing or misleading messages
```

## Gotchas

- Plots are not in the accessibility tree; a locator for a plot does not exist. Use the agent
  or `tests/helpers.dart` coordinates in Flutter widget tests.
- The toast lives 2 s and ignores taps; `expect` polls, so assert it right after the act.
- Growth is server time: a radish is ripe 60 s after planting whatever the device clock says.
