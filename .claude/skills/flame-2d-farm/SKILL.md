---
name: flame-2d-farm
description: Building the 2D farm scene with Flutter and the Flame engine - components, tapping plots, sprites, animation, performance. Use when working on the game canvas in app/.
---

# Flame 2D farm scene

Flame is the 2D game engine for Flutter (`flame` package on pub.dev). Check the installed version in `app/pubspec.yaml` and the Flame docs before relying on an API: Flame's API has changed between major versions (for example `World` and `CameraComponent`).

- **Structure:** `FarmGame extends FlameGame`; a `World` holding a `PlotComponent` per plot (a `SpriteComponent`/`PositionComponent` with `TapCallbacks`); HUD in Flutter widgets via `GameWidget` overlays, not drawn in the canvas.
- **Taps:** mix `TapCallbacks` into `PlotComponent` and handle `onTapDown`. A tap sends a request, it does not change local state directly; the plot updates when the server answers (optimistic animation is fine, rollback on error).
- **Rendering from data:** a plot's visual stage is a pure function of `(cropId, plantedAt, readyAt, serverTime)`. Compute stages (seed, sprout, growing, ripe) from the fraction elapsed.
- **Update loop:** `update(dt)` runs every frame. Do not allocate, parse, or call the network there. Re-evaluate crop stage on a coarse timer (e.g. once a second), not every frame.
- **Assets:** load once in `onLoad` (`images.load`/sprite sheets), keep sprite sheets small, use one atlas for crops. Pre-cache before first frame.
- **Animation:** `SpriteAnimationComponent` for idle animals and ripe-crop sway; `Effect`s (move, scale, opacity) for harvest feedback.
- **Lifecycle:** pause the game when the app goes to background (`WidgetsBindingObserver`) and refresh the farm from the server on resume.
- **Performance budget:** target 60 fps on an older iPhone. Profile in profile mode on a device, not the simulator, before claiming performance.
- **Notifications:** schedule a local notification (`flutter_local_notifications`) for the earliest `readyAt`; iOS requires asking the user for permission first.
