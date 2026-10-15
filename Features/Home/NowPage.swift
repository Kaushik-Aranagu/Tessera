import SwiftUI

/// TODAY: the day stroke, the one current thing as the hero, hold to finish, a short "Later" window and, when a
/// workout is running, one quiet line to get back to it. Grouping is by space and type alone.
struct NowPage: View {
    /// Pages Home to a sibling (used by the empty state).
    var onShow: (HomeSpatialView.Page) -> Void = { _ in }

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finishes = 0

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let lanes = HomeData.lanes(model, now: now)
        let schedule = model.schedule(around: now)
        let current = model.currentTask(around: now)
        let upcoming = HomeData.upcoming(schedule, excluding: current, now: now)

        VStack(alignment: .leading, spacing: 0) {
            HomeDayStrip(lanes: lanes)
                .entrance(0)
                .padding(.bottom, Theme.Spacing.l)

            hero(current, now: now)
                .padding(.bottom, Theme.Spacing.xl)

            if !upcoming.isEmpty {
                Text("Later")
                    .font(Theme.voice(size: 34))
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, Theme.Spacing.s)
                    .entrance(4)
                LaterWindow(items: upcoming)
                    .entrance(5)
            }

            Spacer(minLength: 0)
        }
        .sensoryFeedback(.success, trigger: finishes)
    }

    // MARK: Hero

    @ViewBuilder
    private func hero(_ task: ScheduleItem?, now: Date) -> some View {
        if let task {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(Self.contextLine(task, now: now))
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .contentTransition(.opacity)
                    .entrance(1)

                ZStack(alignment: .topLeading) {
                    Button {
                        model.open(.object(task.id))
                    } label: {
                        HeroText(text: task.title) { $0 }
                            .foregroundStyle(Theme.Colors.ink)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .modifier(ZoomSource(id: Route.object(task.id), namespace: namespace))
                    .accessibilityHint("Opens \(task.title)")
                    .id(task.id)
                    .transition(heroTransition)
                }
                .siblingParallax()
                .entrance(2, hero: true)
                .padding(.bottom, Theme.Spacing.l)

                HStack(alignment: .center, spacing: Theme.Spacing.l) {
                    PaintKey(action: { finish(task) }, label: { holding in
                        Text(holding ? "Keep holding" : "Hold to finish")
                            .textRole(.bodyStrong)
                    })
                    .frame(width: 220)
                    .accessibilityLabel("Finish \(task.title)")
                    .accessibilityHint("Touch and hold")
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        let lines = Self.timeLeft(task, now: AppClock.adjust(context.date))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lines.0)
                            Text(lines.1)
                        }
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .monospacedDigit()
                        .accessibilityElement(children: .combine)
                    }
                }
                .entrance(3)
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("Nothing else is planned today.")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    onShow(.review)
                } label: {
                    Text("Look back at the week →")
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .siblingParallax()
            .entrance(1)
        }
    }

    /// "now, until twenty to four" or "next, at half past five".
    static func contextLine(_ task: ScheduleItem, now: Date) -> String {
        task.start <= now
            ? "now, until \(SpokenTime.clock(task.end))"
            : "next, at \(SpokenTime.clock(task.start))"
    }

    /// ("14 MIN", "LEFT") while it runs, ("IN", "25 MIN") before it starts.
    static func timeLeft(_ task: ScheduleItem, now: Date) -> (String, String) {
        let isNow = task.start <= now
        let seconds = isNow ? task.end.timeIntervalSince(now) : task.start.timeIntervalSince(now)
        let minutes = max(Int((seconds / 60).rounded(.up)), 0)
        let amount = minutes >= 120 ? "\(minutes / 60) H" : "\(minutes) MIN"
        return isNow ? (amount, "LEFT") : ("IN", amount)
    }

    /// The next item writes itself in from the right: 18 pt of travel, blur 4 → 0, on the hero only.
    private var heroTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .modifier(
                active: HeroWriteIn(offset: 18, blur: 4, opacity: 0),
                identity: HeroWriteIn(offset: 0, blur: 0, opacity: 1)
            ),
            removal: .opacity
        )
    }

    private func finish(_ task: ScheduleItem) {
        finishes += 1
        withTesseraAnimation(.smooth(duration: 0.34), reduceMotion: reduceMotion) {
            model.finish(taskID: task.id)
        }
    }
}

private struct HeroWriteIn: ViewModifier {
    let offset: CGFloat
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Later window

/// A bounded window, 92 pt tall (about two rows), snapping per 50 pt row and fading out at the bottom. No
/// separators, no ruler.
private struct LaterWindow: View {
    let items: [ScheduleItem]

    static let rowHeight: CGFloat = 50
    static let height: CGFloat = 92

    var body: some View {
        let height = min(Self.height, Self.rowHeight * CGFloat(items.count))
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    LaterRow(item: item)
                        .frame(height: Self.rowHeight)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: height)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.6),
                    .init(color: .black.opacity(items.count > 2 ? 0 : 1), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Later, \(items.count) items")
    }
}

private struct LaterRow: View {
    let item: ScheduleItem
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        Button {
            model.open(.object(item.id))
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                PaintDab(color: item.isWorkout ? Theme.Colors.live : Theme.Colors.context, seed: item.title.count)
                Text(item.title)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.s)
                Text(Format.clock(item.start))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: Route.object(item.id), namespace: namespace))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(Format.clock(item.start))")
        .accessibilityHint("Opens \(item.title)")
    }
}
