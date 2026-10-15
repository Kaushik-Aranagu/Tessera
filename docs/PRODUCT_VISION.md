# Tessera — Product Vision

Captured from Kaushik, 2026-10-15. Read this before designing any feature or changing the data model.

## Name
The app is **Tessera**. Its built-in personal assistant (on-device, Foundation Models) is **Tess**, a calm,
specific voice that follows the tone rules in the `tessera-design` skill.

## The core idea: everything is an object

Tessera is built the way a software engineer thinks: **classes, objects, inheritance and links**. Kaushik borrowed the
ideas from OOP and operating systems on purpose so he can compose new things himself.

- **Every noun is a linkable object.** "Bench Press" on a workout screen isn't just text. It's an object you can tap
  to open, and inside it are more objects you can tap: muscles, equipment, your personal records, history, technique
  notes, linked plans. You can keep drilling down.
- **Lots of information, shown only when needed** (progressive disclosure). The surface stays clean and the depth
  is one tap away. Don't spend screen space on low-value visuals: no full line graph for something that doesn't
  earn it.
- **Classes are user-definable and extensible.** Defining a new kind of thing (e.g. "Exercise", "Book", "Habit")
  means defining a class with properties. Classes can have **parent classes** (e.g. `Exercise` → `Barbell Lift` →
  `Bench Press`), so properties and behaviour are inherited.
- **The smallest units are objects too.** A set, a rep scheme or a measurement is a typed object, so everything
  composes.

### OS / kernel metaphors (design vocabulary, used where they clarify)
| Concept | In Tessera |
|---|---|
| Class / object / inheritance | Types, records, parent types with inherited fields |
| File system / paths | Every object has an address; breadcrumbs show where you are (`Fitness / Exercises / Bench Press`) |
| Links / pointers | Typed references between objects; backlinks ("used in 12 workouts") |
| Scheduling | Plans: day / week / month; Now / Next / Later is the scheduler's run queue |
| Processes / sessions | Workout mode is a live "process" with its own state, shown in a Live Activity |
| Isolation | Domains (fitness, reading, work…) don't leak into each other unless linked |
| Virtual memory | Show a light summary; page in the details on demand |

## First domain: training

- **Log workouts** quickly: exercises → sets (weight × reps, RPE, rest) with smart defaults from last time.
- **Show sets well**: compact, scannable set tables; progression versus last session at a glance.
- **Plans**: day, week and month plans, made from template workouts.
- **Personal records** per exercise (1RM estimate, best set, volume), surfaced inside the exercise object.
- **Workout mode**: a focused live logging screen with rest timer, next set, Live Activity on the Lock Screen,
  and HealthKit workout saving.

## Visual feedback so far (on the mockups)
- Mixing the three directions is the plan.
- The "sky" / day-arc element takes too much space for too little useful information. Drop it or shrink it.
- Cards need more substance and better hierarchy, not decoration.
- The type needs to be better (more character, better hierarchy).

## Data model (implemented in `Core/`)
| Vision | Type | Notes |
|---|---|---|
| Class | `ClassDef` | single inheritance via `parent`; `traits` (schedulable, timed, trackable, measurable) inherited like interfaces; semantic `colorRole` |
| Property | `FieldDef` | stable `id` (storage key) + `key` (for expressions) + renamable `name`; kinds: text, number, bool, date, duration, mass, choice, ref, refList, classRef, computed, richText; `overridesFieldID` lets a subclass change an inherited default |
| Object | `ObjectRecord` | `values` JSON keyed by field id; composition via `parent`/`children` (Workout → Exercise Entry → Set); soft delete |
| Link | `ObjectLink` | rows for ref/refList/classRef fields, so backlinks are relationships, not JSON scans |
| Engine | `ClassResolver`, `ObjectStore`, `Expression` | effective fields, defaults, computed values (`weight * (1 + reps / 30)`), typed links, backlinks, ancestors |
| Built-ins | `SystemCatalog` | Thing → Activity → Exercise → Strength Exercise → Barbell Lift → Bench Press; Muscle, Equipment, Workout, Exercise Entry, Set (e1RM), Plan, Task, Note. Deterministic ids so devices seed identically before CloudKit sync |

Bench Press is a **class**. A logged set is an instance of `Set`, a child of an `Exercise Entry` whose `exercise`
classRef points at Bench Press, so "Bench Press → used in N workouts" is a backlink query plus walking up to the workout.
