# Tessera (formerly Pilot): the object model, and how OS ideas map to the app

*2026-10-15. Based on Kaushik's direction: everything is an object, built from classes and parent classes, with dense information that only opens when you need it. The mockups (round 2) are at https://claude.ai/artifact/Ma6zBUdJJe4giqRNWHzF3r.*

## 1. Everything is an object

- **Every noun in Pilot is an object of some class.** That covers a set, a workout, a task, a note, a muscle, a person or a place.
- **Every name you see is a handle to its object.** A handle is underlined with dots, and tapping it opens the object page. Each object page has the same shape:
  1. **Path:** `/fitness/exercises/barbell-lift/bench-press`. This is the file-system view, and each segment can be tapped.
  2. **Class line:** `class BenchPress : BarbellLift · Trackable`.
  3. **Summary strip:** the 2–3 numbers that matter for this class. For an exercise these are the best estimated one-rep max (e1RM), the best set and the 90-day trend.
  4. **Properties:** inherited ones are marked ↑, and every value that refers to another object is itself a handle.
  5. **History:** the instances over time.
  6. **Subclasses and Linked from:** what this class has spawned, and the backlinks pointing to it.
  7. **Methods:** the actions the class defines, such as Log a set, Add to plan and Edit class.
- **Depth costs nothing until you ask for it.** The Today row says "Bench press 4×8 @82.5". One tap opens the Bench press page, a second tap opens Chest, and Chest then shows its weekly volume and every exercise that trains it.

## 2. Classes

```swift
// Sketch of the definition language. Users build classes visually,
// but there is also a code view.
class Thing { name: Text; icon: Symbol; tags: [Tag] }

class Exercise: Thing, Trackable {
  muscles: [Ref<Muscle>]
  equipment: Ref<Equipment>
  repRange: Range<Int> = 6...12
  rest: Duration = 2m
}
class StrengthExercise: Exercise { progression: Rule = .addWeight(2.5kg, when: .allSetsHitTop) }
class BarbellLift: StrengthExercise { equipment = .barbell; bar: Mass = 20kg }
class BenchPress: BarbellLift { muscles = [.chest, .triceps, .frontDelts]; repRange = 6...10; rest = 2m30s }

class Set: Thing {                       // one instance per logged set
  exercise: Ref<Exercise>
  weight: Mass; reps: Int; rpe: Number?
  computed e1RM = weight * (1 + reps / 30)   // Epley formula
}
class Workout: Thing, Schedulable, Timed { routine: Ref<Routine>?; children: [ExerciseEntry] }
class ExerciseEntry: Thing { exercise: Ref<Exercise>; children: [Set]; target: SetScheme }
```

- **Single inheritance, plus traits.** A class has one parent. Traits are interface-like and describe behavior that cuts across classes:
  - `Schedulable` gives an object a time, a place on the timeline, and a place in the scheduler.
  - `Timed` adds a start, an end and a duration.
  - `Trackable` gives it history, trends and records.
  - `Measurable` gives it units and goals.
- **Defaults are overridden down the chain.** `BenchPress` inherits `equipment` and `bar` from `BarbellLift`.
- **Composition is parent and child.** A Workout contains ExerciseEntries, and each ExerciseEntry contains Sets. Deleting the workout deletes its children.
- **References are typed links.** Backlinks are a query over those links, so "Linked from 14" is always correct.
- **Computed fields** use one small expression language. The same language drives filters, view conditions and automations.
- **Fields have stable IDs, never names.** Renaming a field never breaks anything.
- **The building blocks themselves are objects.** View blocks (row, card, ring, table, heatmap) and field kinds are classes in the system library. That is how a new app is "just" a few new classes plus the views that render them.

## 3. OS concepts, mapped to Pilot

| OS concept | In Pilot |
|---|---|
| **Kernel** | The core runtime: the object store, the class registry, the scheduler and the event bus. Apps never touch storage directly; they make "system calls" (typed actions). |
| **Processes** | A running app or mode. **Workout mode is a foreground process.** It takes over the screen and changes the environment to a dark, focused theme. |
| **Background processes** | Rest timers, focus sessions and a workout you minimized. Each one shows as a pill in the status strip and as a Live Activity on the Lock Screen. |
| **Scheduler** | Today and Plans. Items get time slices and priorities. The Now card is the one that is "on the CPU". |
| **Context switch** | Ready-to-Resume. When you leave a task, Pilot saves its state ("you were… next:"), the way a process control block saves registers. |
| **Virtual memory and paging** | Progressive disclosure. Each screen shows only the working set, and tapping a handle is a "page fault" that loads the detail. Nothing is lost by being hidden. |
| **File system** | The object graph. Paths become breadcrumbs. Links are like symlinks, and backlinks come free. Mounts are integrations: Apple Health is mounted at `/health`. |
| **Isolation and sandboxing** | Each area of life (Fitness, Work, Personal) has its own scope. Each app declares which classes it can read and write, and which ones the AI is allowed to see. |
| **IPC and syscalls** | Typed actions between apps. Finishing a workout writes a Set history, updates PRs and ticks the Today item. The same actions back Siri, Shortcuts and the Action button through App Intents. |
| **Shell** | The command bar: `log bench 82.5x8`, `open push day a`, `plan next week`, or plain language for the AI. |
| **Drivers** | HealthKit, the Apple Watch, the motion sensors and the calendar. |
| **Signals and interrupts** | Notifications, kept gentle: rule-based and quiet by default. |
| **Package manager** | Prebuilt apps ship as versioned packages (classes, views, actions). Your changes live as an overlay, so updates still apply underneath. |

## 4. What this means for the first builds

1. **Data model:** being reworked on your Mac now. It adds classes with parents, traits, typed links with backlinks, parent/child composition, and computed fields, with tests.
2. **A generic object page** that renders any class: path, class line, summary, properties, history, links and methods. Every app gets it for free.
3. **Training first:**
   - Today with the Push Day card.
   - Workout mode: big current set, plate math, quick steppers, a PR hint, rest timer with a Live Activity, and hold to log.
   - The Bench press object page.
   - Plans for week and month, weekly sets per muscle, and PRs.
4. **Class editor:** a visual editor, with a code view for you.
