# Later candidates: People and Home upkeep

For: Product lead (planning)
Date: 2026-10-15

Both are small. Upkeep is the safer first pick: a chore is a habit with an interval, so it reuses M3 habits almost as is. People is one class plus a derived "last talked" line, but it needs a contacts decision.

## People (personal CRM, minus the CRM)

**What the best apps do, and why people quit.** Clay and Dex sync contacts, LinkedIn and mail, then nudge you to "keep in touch". Monica is open source and private but every call and gift is typed by hand. UpHabit, Garden and Covve set a keep-in-touch interval per person and show who is overdue. Why people quit: entry is double work, "overdue: Mom, 3 weeks" turns friends into tickets, auto-enrichment feels creepy, and a subscription for an address book.

**Contacts access (iOS 18+).** The prompt now offers full or limited access; limited means the app sees only the contacts the user picks (`CNAuthorizationStatus.limited`, SwiftUI `contactAccessPicker`, `ContactAccessButton` to add more later). Birthday comes from `CNContact.birthday` when that key is fetched. It needs only an Info.plist usage string, no entitlement, so the free account works. Option zero: no access at all, birthday typed once.

**Smallest first version**
- Class `Person`: name, birthday (optional), contact id (optional), gift ideas (a List), links.
- Derived, never typed: "last mentioned" = newest note, task or Day log line that @mentions the person.
- Actions: add person, set birthday, add gift idea. Birthday makes a yearly dated task, one week and one day ahead.
- Grammar: `@Sam` in any note or task (creates Sam on first use), `Sam birthday 12 mar`, `gift Sam: climbing chalk bag`, `talked to @Sam`.

**First time, under 30 s:** in a task type `call @Mom`. Mom exists. Done. Later, `Mom birthday 4 jun` adds the dated task. No import screen.

**Where it shows**
- Now: on birthday morning, "Mom's birthday" with her gift list one tap away. A week ahead, only if the gift list is empty.
- What's running: not used.
- Day log: "Talked to Sam, Mom" from mentions. Nothing about who you did not talk to.

**Pitfalls**
1. Transactional feel. No keep-in-touch intervals, no overdue list, no scores. "Last mentioned 3 weeks ago" sits quietly on the person page only.
2. Mentions are not contact. A task "return @Sam's drill" counts. Label it "last mentioned", not "last talked", unless the phrase was `talked to`.
3. Duplicate names. `@Sam` with two Sams asks once, then remembers the latest pick.

## Home upkeep (chores, plants, bills)

**What the best apps do, and why people quit.** Tody shows a per-task "dirtiness" bar that fills from green to red over its interval; loved for "clean what needs it", but setup room by room is long. Sweepy adds rooms, points and a household score. BeTidy is a weekly checklist. Planta schedules watering per plant from species and light; users say rigid dates cause overwatering and the best features are paid. OurHome and Flatastic are family and flat-share rotas with points. (Centr is a fitness app; skipped.) Why people quit: after a holiday every bar is red at once, the setup before first use, points that feel like chores for adults, and due dates that ignore "I checked the soil, it's fine".

**Dirtiness meter vs due date.** The meter wins: it shows age, not failure, and nothing is ever "late". Use it as text, not a red bar: "watered 6 days ago, usually every 7".

**Smallest first version**
- Class `Chore`: name, interval (days), last done, place (optional), links. It is a habit with an interval (M3).
- Actions: done (resets), skip ("looked, fine": resets without counting), snooze 1 day, pause (holiday).
- Grammar: `watered plants`, `did laundry`, `paid rent`, `plants every 7d`, `plants fine` (skip).
- Bills are a chore with an amount; a Money spend can be linked later, not in v1.

**First time, under 30 s:** type `watered plants`. Feedback: "Logged. How often? 7d". One tap or ignore (default: learn from the next two times). No rooms, no catalog.

**Where it shows**
- Now: the single stalest chore past its interval drifts in, in grey: "Plants, 9 days". Never a list.
- What's running: not used (chores are instant).
- Day log: "Watered plants, did laundry".

**Pitfalls**
1. Holiday pile-up. Pause freezes all ages; after a gap of 5+ days with no logs, Now shows one item, not all.
2. Guilt colours and streaks. No red, no streak, no score. Count only: "3 chores this week".
3. Interval set-up fatigue. Allow no interval; learn the median gap after three logs.

## Yes/no for Kaushik

1. People: ask for Contacts access (limited picker) to read birthdays, or keep People typed by hand? Default if no answer: typed by hand, no prompt.
2. People: do any @mentions count as "last mentioned", with only `talked to` counting as "last talked"? Default: yes.
3. Upkeep: build on M3 habits (chore = habit with interval) rather than a new engine? Default: yes.

## Sources

- [Apple: Accessing the contact store](https://developer.apple.com/documentation/contacts/accessing-the-contact-store)
- [Apple: ContactAccessButton](https://developer.apple.com/documentation/contactsui/contactaccessbutton)
- [Apple: contactAccessPicker](https://developer.apple.com/documentation/swiftui/view/contactaccesspicker(ispresented:completionhandler:))
- [Dex: Monica review 2026](https://getdex.com/blog/monica-review/)
- [Dex reviews on Capterra](https://www.capterra.com/p/275020/Dex/reviews/)
- [Best personal CRM tools 2025](https://wavecnct.com/ja/blogs/the-6-best-personal-crm-tools-in-2025)
- [Tody on the App Store](https://apps.apple.com/us/app/-/id595339588)
- [Apartment Therapy: Tody review](https://www.apartmenttherapy.com/tody-cleaning-app-review-37282867)
- [Planta on the App Store](https://apple.co/3241Dmb)
