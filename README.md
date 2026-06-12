# Legacy Heroes

A semi-AFK **generational idle RPG** for mobile, built with **Flutter + Flame**.

You begin with a single hero who fights, trains, explores, and collects loot —
mostly while you're away. Heroes age, earn renown, and eventually retire or
fall. When that happens you choose an **heir**, who inherits a share of their
ancestor's power, traits, and heirlooms. Over many generations you aren't just
leveling a character — you're building a **family dynasty**.

> "This is not just my hero. This is my family."

This repository implements the **Phase 1 MVP** from the game plan, with the
architecture laid out so V2/V3 features and Firebase sync slot in cleanly.

---

## Running the game

Flutter is **not** preinstalled in this cloud container, so the project ships as
source. On a machine with the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.3+) installed:

```bash
# 1. Generate the native platform folders (android/ios/web/…). This reads the
#    app name from pubspec.yaml and does NOT touch lib/ or assets/.
flutter create .

# 2. Fetch dependencies.
flutter pub get

# 3. Run on a device, emulator, or the web.
flutter run            # mobile
flutter run -d chrome  # quick desktop/browser preview
```

The first launch auto-creates a founding hero and starts the idle loop.

### Fast pacing for testing the legacy loop

The signature generational hand-off is normally slow (the plan suggests
1 in-game year per 24h). To make it reachable in a single play session, the MVP
uses **1 year per 10 minutes** of real time. Change
`GameConstants.realSecondsPerGameYear` in
`lib/core/constants/game_constants.dart` to `86400` for production pacing.

---

## What's implemented (MVP)

Core loop (plan §2, §3, §7):

- **Hero system** — 5 classes (Warrior, Ranger, Mage, Paladin, Blacksmith),
  stats, level/XP, power formula, traits, equipment.
- **Idle activities** — 5 quests (Training → Demon Gate boss) with duration,
  recommended power, risk/skulls, success chance, and loot tiers.
- **Offline rewards** — accrual capped at 4h, with the "watch ad to double"
  welcome-back placement.
- **Leveling & equipment** — equip/unequip across 7 slots; loot drops and
  heirlooms.
- **Aging → retirement/death → heir selection → next generation** — the
  emotional core. Heirs inherit power %, traits, and heirlooms.
- **Family Tree** — every hero is preserved forever as a memorial portrait.
- **Daily rewards**, **shop**, **rewarded-ad placements** (simulated).

Signature visuals (Visual & Flame plan):

- The home screen is a **full-screen Flame world**, not a Material dashboard:
  a twilight village with an animated hero by a campfire, fireflies, embers,
  parallax hills, and a family banner.
- A modular **scene system** — `VillageScene`, `TrainingScene`,
  `DungeonScene`, `BossScene`, `LegacyScene` — that the world swaps between as
  the hero's activity changes.
- Reusable fantasy widgets: `FantasyButton`, `ParchmentPanel`,
  `ResourceCounter`, `QuestCard`, `ItemFrame`, `TraitSeal`, `HeroPortrait`.
- Reward "juice": gold-burst FX, parchment ceremony dialogs, a golden Legacy
  scene for the heir hand-off.

All visuals are **code-generated placeholders** drawn so real PNG/SVG/Lottie
assets can replace them later (drop them in `assets/images/…` and swap the
component internals).

---

## Project structure

```
lib/
  main.dart                 # boot: load catalog, run app
  app/                      # app shell, theme, palette
  core/
    constants/              # all balance/tuning numbers (GameConstants)
    services/               # save, ads, analytics, catalog (data loader)
    utils/                  # formatters, rng
  features/                 # domain + data per feature (clean layering, plan §8)
    hero/  activities/  equipment/  family/
  state/                    # GameState + GameController (Riverpod) — the engine
  game/                     # Flame: LegacyGame, scenes/, components/, effects
  ui/
    screens/                # home (hosts the Flame world), equipment, family, shop
    overlays/               # HUD + quest board, rewards, offline, heir, daily
    widgets/                # reusable fantasy UI
assets/data/                # heroes, activities, items, traits (JSON, easy to balance)
```

State flows one way: **Riverpod owns game logic**, the Flutter layer watches it
and calls `LegacyGame.sync(...)` to tell the world which scene to show; overlays
trigger FX via method calls. See `lib/state/game_controller.dart`.

---

## Roadmap (from the plan)

- **V2:** marriage & multiple children, rare bloodline traits, boss raids,
  guilds, seasonal events, hero diary, legendary heirlooms.
- **V3:** PvP dynasty ranking, global boss, kingdom building, pets, battle pass.
- **Backend (plan §9–§12):** Firebase Auth (anon → Google/Apple), Firestore
  cloud save, Functions for reward validation & anti-cheat, Analytics,
  Crashlytics. Service seams already exist (`SaveService`, `AnalyticsService`).

### Enabling AdMob (rewarded ads)

Ads run in **simulated** mode by default (`SimulatedAdService`) so the full
reward loop is playable with no setup. To ship real ads:

1. Uncomment `google_mobile_ads` in `pubspec.yaml`, run `flutter pub get`.
2. Add your AdMob **App ID** meta-data to `AndroidManifest.xml` and
   `Info.plist` (the GMA SDK auto-initializes and crashes on launch if it's
   missing — this is why it ships disabled).
3. Call `MobileAds.instance.initialize()` in `main()`.
4. Implement a real `AdService` (load/show `RewardedAd`) and override
   `adServiceProvider` in `lib/state/providers.dart`.

Test with Google's test ad unit IDs during development.
