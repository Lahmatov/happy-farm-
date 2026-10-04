---
name: mobile-game-ui
description: Layout, safe areas, touch targets and screen flow for the iPhone farm UI in Flutter. Use when building or changing any screen or HUD.
---

# Mobile game UI (Flutter, iPhone)

Adapted from `game-ui-ux` in [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) (Apache-2.0).

- **Layout:** anchors and flex (`Align`, `Row`, `Expanded`, `LayoutBuilder`), never absolute pixel positions. The farm grid sizes from available width.
- **Safe area:** wrap HUD in `SafeArea` (notch, Dynamic Island, home indicator). The game canvas may go edge to edge; controls may not.
- **Touch targets:** at least 44x44 pt (Apple HIG). Plots and shop items must be comfortably tappable on an iPhone SE-size screen.
- **Test sizes:** iPhone SE (375x667), a current Pro (393x852), a Pro Max, portrait and landscape if supported. Look at each; do not assume.
- **Screen flow as a stack:** `Navigator` push/pop for shop, friends, settings. Bottom sheets for quick actions (pick a seed for a plot).
- **HUD from state, not polling:** coins, XP and level come from a state object (`ChangeNotifier`/`ValueNotifier`) that updates when a server response arrives. No per-frame reads of game state.
- **Feedback:** every action gives immediate visual response (coin pop, harvest bounce, error shake) before the server round trip finishes, then reconciles with the response.
- **Text:** use `MediaQuery.textScaler`-aware layouts; strings externalised (the game is Russian first, keep English possible).
