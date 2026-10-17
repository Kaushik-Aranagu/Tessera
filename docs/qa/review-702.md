# Review #702 (head 3ea5185e): PASS (static; app run waits for the simulator)
- Slot: RestReceipt and the week-page picker both go through TessVoice.shared.say, the one slot (note replaced, older timer ignored by id). First launch: holds .seconds(4) with UNDO (new = 4 s); a picked change: default with an op = 10 s (change = 10 s); the failure line is plain, 4 s. say() gained `holds` only; other callers unchanged.
- First launch: writeFirstRestWeekday runs only inside `!demo, settingsAreReal`, once per install (defaults key), and its op is held in model.restReceipt, shown once and cleared; shows when session == nil, again on workout end (onChange), so it waits out a live workout.
- Demo: AppModel.isDemo guards both the launch write and the picker (demoDay in @State, never written). Picking the same day writes nothing.
- Band: modifier on RootView adds no view or frame; the sentence sits in ReviewView's column above Claude. No haptic added.
- Low: nothing in the app yet stretches UNDO to 10 s under VoiceOver (no isVoiceOverRunning anywhere), so the 4 s first-launch UNDO is short for a VoiceOver user; suggest holds = VoiceOver ? 10 : 4 in say().

## Delta 698dca84: PASS
Only RestDaySentence.swift: Any receipt "Rest day, any day." (no old string left in the repo); chooser is ViewThatFits(in: .horizontal) with a one-row HStack of eight static buttons and a two-row VStack fallback (Sun to Wed, Thu to Sat plus Any), same actions and accessibility labels through day(_:) and `any`; the local `day` renamed `rest`. No logic change in pick(), the demo guard or the slot. Low: the property name `any` shadows a contextual keyword; it compiles, but a name like anyButton reads safer.
