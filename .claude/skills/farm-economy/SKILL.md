---
name: farm-economy
description: Balancing the farm game's economy and progression - crop values, levels, plot prices, stealing. Use when changing server/src/catalog.ts or any rule that moves coins or XP.
---

# Farm economy

Source of truth: `server/src/catalog.ts`. Rules mirror the classic Happy Farm loop: plant, wait, harvest, earn, level up, unlock more.

- **Profit per crop** = `yieldCount * sellPrice - seedPrice`. It must be positive for every crop, and profit per hour should rise with unlock level so progression feels rewarding.
- **Two play styles must both work:** short crops (radish, 1 min) reward active players; long crops (corn, 2 h) reward players who check twice a day. Neither should dominate hourly profit by a wide margin.
- **Start state:** 200 coins and 6 plots must let a new player complete a few cycles within the first 5 minutes without a dead end (never allow a state with no coins and nothing planted: radish seeds must stay affordable).
- **Stealing:** capped total share (50%) and one theft per thief per plot, so owners always keep most of the crop. Changing the numbers needs a test for the cap.
- **Level curve:** `xpForLevel(l) = 50 * l^2`. Check that unlock levels are reachable at the expected play time.
- **Changing a number:** update the test that encodes the old value, and state the before/after profit per hour in the PR description.
- **No real-money surfaces** are added without an explicit decision from the owner.
