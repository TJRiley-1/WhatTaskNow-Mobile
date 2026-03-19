# Whatnow — Project Guide

## What is this?
Whatnow is a task management app for people with ADHD and task paralysis. Users swipe through tasks one at a time instead of staring at an overwhelming list. Built with Flutter, backed by Supabase.

## Tech Stack
- **Frontend:** Flutter (Dart), Riverpod state management, GoRouter navigation
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Payments:** RevenueCat (IAP on iOS + Android)
- **Analytics:** TBD (evaluating PostHog)
- **Local DB:** Drift (offline support)
- **Ads:** Google AdMob (test IDs currently)

## Architecture
- `lib/models/` — Data models (Task, Profile, Group)
- `lib/providers/` — Riverpod providers (state management)
- `lib/screens/` — Screen widgets organised by feature
- `lib/widgets/` — Reusable widgets
- `lib/config/` — Theme, environment, ranks, ad config
- `lib/data/` — Drift database for offline cache
- `lib/router/` — GoRouter configuration
- `supabase/functions/` — Edge Functions
- `store/` — Store listing copy and privacy policy

## Brand
- **Name:** Whatnow
- **Domain:** whattasknow.com
- **Colour:** Purple #6750A4
- **Tagline:** "Stop overthinking. Start doing."
- **Bundle ID:** com.whatnow.app
- **IMPORTANT:** The swipe feature is called **"What Now?"** — never "What Next?". All UI text, class names, file names, and references must use "What Now?" / `WhatNow`.

## Pricing & Monetisation

### Model: Hard Paywall with Limited Free Fallback
**7-day trial → limited free with ads → premium subscription**

| Phase | Access | Ads |
|-------|--------|-----|
| Trial (7 days) | Full app — all features | No ads |
| Free (post-trial) | Task list + groups only | Banner ads |
| Premium | Full app — all features | No ads |

### Feature Split
- **Premium-gated:** What Now swipe, Timer
- **Always free:** Task list, Groups (join + create) — groups stay free to drive social/viral growth
- **Future premium perks:** Streak freezes (unlimited), home screen widgets, custom themes, advanced analytics

### Pricing (Single Tier)
| Plan | UK Price |
|------|----------|
| Monthly | £3.99 |
| Annual | £29.99 (~37% discount) |
| Lifetime | £59.99 (early adopter offer, may be removed later) |

- Positioned below Tiimo (£7.99/mo) and Finch (£4.99/mo)
- Localisation: set GBP base → Apple/Google auto-generate → manually review top 10 markets
- Lifetime reduces "subscription guilt" common with ADHD users

### Payment Infrastructure
- **Provider:** RevenueCat (`purchases_flutter` package)
- **Why not Stripe:** Apple requires IAP for digital goods in mobile apps; Stripe browser checkout would be rejected
- **Free tier:** RevenueCat is free up to $2,500/mo tracked revenue, then 1% revenue share
- **`is_premium` field:** stays as local cache; source of truth = RevenueCat entitlements

## Working Process
1. **Research first** — Every strategic decision gets researched with pros/cons before any code is written
2. **Discuss and align** — Present options to the user, get explicit agreement
3. **Implement** — Only after alignment, write code
4. **Verify** — Run `flutter analyze && flutter build apk --debug` after changes
5. **Update CLAUDE.md** — As decisions are made, document them here for future sessions

## Deep Research Findings (2026-03-15)

### Market Intelligence
- **Tiimo** (iPhone App of the Year 2025): visual timeline, AI co-planner, mood tracking — sets the bar for ADHD apps
- **Finch**: micro-goals + compassionate mechanics (no punishing streaks) — models emotional design
- **ADHD users have 40% higher app abandonment rates** — onboarding and first-session experience are make-or-break
- **Hard paywalls outperform soft freemium** (78% vs 45% trial starts) — current 20-task soft limit may underperform
- **Social features boost retention 40%**, engagement 35%, revenue 2.8x — groups feature is an asset
- **Streaks + milestones reduce 30-day churn by 35%** — gamification is essential, not optional
- **Simple single-tier pricing** reduces choice paralysis for ADHD users

### Design Trends (2025-2026)
- Glassmorphism / liquid glass effects
- Earthy/refined green palettes (shifting away from pure purple)
- Gesture-first navigation (swipe-heavy — aligns well with Whatnow's swipe UX)
- Skeleton/shimmer loading screens (not spinners)
- Micro-animations and haptic feedback for dopamine hits

### Current App Gaps (by severity)

**CRITICAL — blocks store acceptance or causes crashes**
1. Zero widget/integration tests — store reviewers may reject; no regression safety net
2. No App Tracking Transparency (ATT) — iOS will reject with AdMob
3. No GDPR consent flow — legal requirement for UK/EU users
4. No crash reporting — flying blind in production

**HIGH — significantly hurts retention/conversion**
5. No onboarding flow at all — users land in empty task list
6. No notification/reminder system — ADHD users need external prompts
7. No haptic feedback or micro-animations — missing dopamine reinforcement
8. Timer progress lost on app kill — frustrating for core feature
9. No skeleton/shimmer loading screens — feels broken on slow connections
10. All strings hardcoded — no localisation possible
11. No accessibility (font scaling, screen readers, contrast ratios)

**MEDIUM — expected for quality apps**
12. No deep linking / universal links
13. No pagination (task list will degrade with many tasks)
14. No autofocus on form fields
15. No page transition animations
16. No force-update mechanism for breaking changes
17. No feature flags for gradual rollout

### Store Keywords & ASO
- **Primary (high intent):** ADHD planner, ADHD task manager, task paralysis, executive function, focus timer
- **Secondary (broader reach):** to do list ADHD, daily planner, simple task manager, one task at a time, mindful productivity
- **Long-tail (low competition):** task overwhelm help, ADHD friendly app, neurodivergent planner, decision fatigue app
- **Avoid:** "productivity" (saturated), "todo list" (dominated by Todoist/TickTick), "habit tracker" (different category)
- Apple keyword field (100 chars): `ADHD,planner,task paralysis,focus,timer,executive function,neurodivergent,simple,one task`
- Google Play: include "ADHD" and "task" in title + short description
- **Apple subtitle** (30 chars): "ADHD-Friendly Task Manager"

### Streak & Widget Concepts

**Compassionate streak mechanics (Finch-style):**
- Daily streak: complete ≥1 task to maintain
- Compassionate miss handling: "You missed yesterday — that's okay! Your streak is paused, not lost."
- Freeze days: 2 free/month (premium gets unlimited)
- Milestones: 7/30/100/365-day badges with celebration animations
- Weekly summary: Sunday evening notification with task count and top category

**Home screen widgets (`home_widget` package):**
- "Next Task" widget — shows next recommended task with tap-to-complete
- "Daily Streak" widget — flame icon + streak count
- "Progress Ring" widget — circular progress for daily goal
- Start with small (2×2) "Next Task" widget

### Event Driven Groups (Phase 1 IMPLEMENTED 2026-03-19)
Two group types now live: **Event Driven** (premium-only creation) and **Friends & Family** (free).
- **Core mechanics (done):** group task pool, task claiming, admin assignment, status visibility, role-based permissions (admin/member)
- **Status flow:** Unassigned → Claimed → In Progress → Done
- **Use cases:** party planning, household chores, team projects, ADHD accountability partners
- **Technical:** `group_tasks` table with RLS, `group_members` with roles, `get_group_leaderboard` RPC (parameterised period/metric), `sync_group_task_to_user` RPC, group tasks sync to personal task list
- **Phase 2 remaining:** deep links, push notifications, realtime subscriptions, activity feed, advanced admin controls

### Price Localisation
- Set GBP base price, use Apple/Google automatic localisation, manually review top 10 markets
- Key markets: UK (home), US (largest English market), EU (GDPR territory), India/Brazil/SEA (high growth, low price sensitivity)
- RevenueCat handles per-country pricing natively via App Store / Play Store price tiers

---

## App Launch Checklist (Strategic Phase)

### Testing & Quality (build confidence first)
- [ ] Widget tests for core flows (add/edit/complete task, swipe card)
- [ ] Integration tests with Patrol
- [ ] Sentry crash reporting
- [ ] CI/CD with GitHub Actions (analyze, test, build on every PR)

### Product Strategy (decide first)
- [x] Paywall model — 7-day trial → limited free with ads → premium (What Now swipe + Timer gated)
- [x] RevenueCat for IAP (Stripe removed)
- [x] Price localisation — £3.99/mo, £29.99/yr, £59.99 lifetime; GBP base with auto-localisation

### Payment Implementation
- [ ] Set up RevenueCat account + configure products
- [ ] Add `purchases_flutter` to pubspec.yaml
- [ ] Rewrite premium_provider.dart to use RevenueCat entitlements
- [ ] Redesign premium_screen.dart as paywall with trial messaging
- [ ] Remove stripe-webhook edge function
- [ ] Configure products in App Store Connect + Google Play Console
- [ ] Implement trial expiry → limited free mode transition
- [ ] Add banner ads to post-trial free screens (task list, groups)

### User Experience (design second)
- [ ] Customer onboarding flow — screens, data collected, personalisation
- [ ] Paywall screen — placement, content, conversion design
- [ ] In-app dashboard — user metrics, streaks, progress visualisation

### Engagement & Retention (design alongside UX)
- [ ] Push notifications (FCM + `flutter_local_notifications`) — task reminders, daily nudges, streak alerts
- [ ] Haptic feedback + micro-animations — `HapticFeedback.lightImpact()` on swipe, confetti on completion
- [ ] Streaks & milestones gamification — compassionate (Finch-style), not punitive
- [ ] Shimmer loading screens — replace `CircularProgressIndicator` with shimmer placeholders
- [ ] Timer state persistence — save to local storage, restore on app resume

### Engagement Widgets
- [ ] "Next Task" home screen widget (`home_widget` package)
- [ ] "Daily Streak" home screen widget
- [ ] Compassionate streak mechanics (pause, don't punish)
- [ ] Streak freeze days (2 free/month, unlimited premium)
- [ ] Milestone badges (7/30/100/365 days)
- [ ] Weekly summary notification

### Compliance
- [ ] ATT for iOS (required for AdMob) — `app_tracking_transparency` package
- [ ] GDPR consent management — consent banner on first launch, gate analytics/ads on consent
- [ ] Health-adjacent disclaimers — ADHD is health-adjacent; may need store listing disclaimers

### Internationalisation
- [ ] Languages to support at launch
- [ ] Localisation implementation (Flutter intl/arb)
- [ ] Store listing translations

### Pricing & ASO
- [ ] Price localisation — set GBP base price, configure per-country pricing, review top 10 markets
- [ ] Store keyword optimisation — "ADHD planner", "task paralysis", "focus timer", "neurodivergent"
- [ ] Apple subtitle: "ADHD-Friendly Task Manager" (30 chars)

### Brand & Design
- [ ] App icon — professional design direction
- [ ] Store screenshots — curated with marketing copy and device frames
- [ ] Feature graphic (Android)

### Accessibility
- [ ] Screen reader / Semantics support — `Semantics` widgets, proper `labelText` on all inputs
- [ ] Dynamic font scaling — test at 1.0x through 2.0x, ensure no overflow
- [ ] WCAG AA contrast compliance

### Web Presence
- [ ] whattasknow.com landing page
- [ ] Privacy policy hosted on domain

### Infrastructure
- [ ] Analytics platform (PostHog — analytics + feature flags + A/B in one platform)
- [ ] AdMob real IDs
- [ ] Release signing (keystore + iOS certs)
- [ ] Flutter Flavors (dev/staging/prod environments with separate Supabase projects)
- [ ] Force update mechanism — `force_update_helper` or remote config check
- [ ] Feature flags — PostHog or Firebase Remote Config for gradual rollout
- [ ] Deep linking — universal links (iOS) + app links (Android) for group invites, shared tasks

### Release (last)
- [ ] Release builds (AAB + IPA)
- [ ] Store submissions
- [ ] RevenueCat live mode + verify entitlements

### Groups Expansion — Phase 1 (DONE 2026-03-19)
- [x] Database: `group_type`, `event_date`, `leaderboard_period`, `leaderboard_metric` on `groups`; `role`, `allow_task_assignment` on `group_members`; new `group_tasks` table with RLS; `group_task_id`/`group_id`/`group_name` on `tasks`
- [x] Models: `GroupType`, `LeaderboardPeriod`, `LeaderboardMetric` enums; `GroupMember` model; `GroupTask` model with status enum; `Task` now has `isGroupTask` getter
- [x] Providers: `groupMembersProvider`, `groupTasksProvider` (CRUD + 30s auto-refresh + sync RPC); leaderboard uses parameterised `get_group_leaderboard` RPC
- [x] Event Driven Groups: group detail screen (tasks/members tabs), add group task form, assign/claim/start/done flow, task sync to personal list
- [x] F&F Groups: configurable leaderboard period (weekly/monthly/quarterly) and metric (points/tasks/combined)
- [x] Group cards show type badge, route to detail (event) or leaderboard (F&F)
- [x] Create flow: type selection, premium gate on event group creation, period/metric config for F&F
- [x] Personal task integration: group badge on task cards + swipe cards; timer syncs completion to `group_tasks`
- [x] Invite sharing via `share_plus` package
- [x] Routes: `/group-detail`, `/add-group-task`

### Groups Expansion — Phase 2 (TODO)
- [ ] Deep links for group invites (universal links iOS + app links Android)
- [ ] Push notifications for group activity (task assigned, task completed, new member)
- [ ] Activity feed on group detail screen
- [ ] Advanced admin controls (edit group settings, transfer ownership)
- [ ] Real-time updates via Supabase realtime subscriptions (replace 30s polling)

## Key Decisions Log
_Update this section as decisions are made_

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-15 | Supabase for backend | Already in use, good free tier, auth + DB + edge functions |
| 2026-03-15 | ~~Stripe test mode set up~~ | Superseded — replaced by RevenueCat (2026-03-17) |
| 2026-03-15 | ~~20-task free limit~~ | Superseded — replaced by hard paywall model (2026-03-17) |
| 2026-03-17 | RevenueCat for IAP (remove Stripe) | Apple requires IAP for digital goods; Stripe browser checkout will be rejected. RevenueCat is free at current scale, handles receipts/lifecycle/localisation. |
| 2026-03-17 | Hard paywall: 7-day trial → limited free with ads → premium | Research: 78% trial start rate. Free fallback = task list + groups with ads. Premium gates What Now swipe + timer. Groups free for viral growth. |
| 2026-03-17 | £3.99/mo, £29.99/yr, £59.99 lifetime | Below competitors (Tiimo £7.99, Finch £4.99). Single tier reduces ADHD choice paralysis. Lifetime for subscription-anxious users. |
| 2026-03-19 | Groups Expansion Phase 1: Event Driven + F&F leaderboard | Two group types: Event Driven (premium-only creation, task pool with assign/claim) and Friends & Family (free, configurable leaderboard). Group tasks sync to personal list. Phase 2 = deep links, push notifications, realtime. |

### Research-Backed Recommendations (2026-03-15)

| Finding | Recommendation | Rationale |
|---------|---------------|-----------|
| Hard paywall > soft freemium | **DECIDED:** 7-day trial → limited free with ads → premium | 78% vs 45% trial starts; free fallback with ads retains users who aren't ready to pay |
| ADHD 40% higher abandonment | Prioritise onboarding above all else | First session must deliver a "wow" moment within 60 seconds |
| Streaks reduce churn 35% | Add streak system before launch | Non-punishing (Finch-style) — compassionate messaging on missed days |
| Social features 2.8x revenue | Leverage existing groups feature in marketing | Already built; highlight in store screenshots and onboarding |
| Sentry is industry standard | Use Sentry over Firebase Crashlytics | Better Dart support, source maps, breadcrumb trails, generous free tier |
| PostHog recommended | PostHog for analytics + feature flags + A/B | Single platform, open source, GDPR-friendly, replaces multiple tools |
