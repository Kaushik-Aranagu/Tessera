# Backlog summary, items 141 to 192

Date: Oct 22, 2026, 7:25 PM PDT

Tier "none" means the item is not in the tiers of build-order-193.md (held, dropped, or a rule sheet). Item 145 is dropped by Kaushik; it is shown as held because it is not queued. Item 167 says "data and UI" in its sheet and is filed under data and architecture.

Item | Review switch | Lane | Tier | State
---- | ------------- | ---- | ---- | -----
141 | areasFold | UI and UX | none | held
142 | surfacesV2 | UI and UX | 2 | queued
143 | reviewV2 | UI and UX | 2 | queued
144 | whyNumbers | UI and UX | none | queued
145 | none (dropped) | UI and UX | none | held
146 | oneHands | UI and UX | none | queued
147 | occasions | UI and UX | none | queued
148 | makeAKind | AI | none | queued
149 | pagesV2 | UI and UX | 2 | queued
150 | pagesV2 | UI and UX | 2 | queued
151 | pagesV2 | UI and UX | 2 | queued
152 | pagesV2 | UI and UX | 2 | queued
153 | liveV2 | UI and UX | 1 | queued
154 | settingsV2 | UI and UX | 2 | queued
155 | shopV2 | UI and UX | 1 | queued
156 | focusV2 | UI and UX | 2 | queued
157 | planV2 | UI and UX | 2 | queued
158 | findV2 | data and architecture | 3 | queued
159 | weekReset | UI and UX | 3 | queued
160 | moneyMonthV2 | UI and UX | 1 | queued
161 | pantryLevelsV2 | UI and UX | 1 | queued
162 | routinesDayV2 | UI and UX | built | in review
163 | emptyStatesV2 | UI and UX | 3 | queued
164 | undoLogV2 | data and architecture | 1 | queued
165 | listsV2 | UI and UX | 2 | queued
166 | askPageV2 | AI | 3 | queued
167 | quietHoursV2 | data and architecture | 3 | queued
168 | weekThreadV2 | UI and UX | built | in review
169 | backupsV2 | data and architecture | 1 | queued
170 | tessQuietV2 | AI | 3 | queued
171 | none (rule sheet) | rule sheet | none | queued
172 | moneyAddV2 | UI and UX | 2 | queued
173 | repeatsV2 | data and architecture | 2 | queued
174 | noteTasksV2 | AI | 3 | queued
175 | none (rule sheet) | rule sheet | none | queued
176 | none stated (follows 162 and 168) | data and architecture | none | queued
177 | controlsV2 | UI and UX | 3 | queued
178 | voiceWriteV2 | AI | 3 | queued
179 | walledPageV2 | data and architecture | 1 | queued
180 | importV2 | data and architecture | 3 | queued
181 | notesWriteV2 | UI and UX | 3 | queued
182 | cookHandsFreeV2 | UI and UX | 3 | queued
183 | twinsV2 | data and architecture | 3 | queued
184 | soonSweepV2 | UI and UX | 3 | queued
185 | dinnerChooserV2 | UI and UX | 3 | queued
186 | weekMealsV2 | AI | 3 | queued
187 | awayV2 | UI and UX | 1 | queued
188 | none (rule sheet) | rule sheet | none | queued
189 | unitsV2 | data and architecture | 2 | queued
190 | notifyWordsV2 | UI and UX | 2 | queued
191 | spotlightV2 | data and architecture | 3 | queued
192 | none (rule sheet) | rule sheet | none | queued

Duplicates and overlaps:

- 164 undoLogV2 defines the one Undo, but 169 (restore), 172 (add a spend), 174 (note to tasks), 178 (voice route) and 180 (bring in) each write their own 10 minute Undo.
- 162 routinesDayV2 puts "Pause" and "Busy" at its foot, and 176 defines the same two as fields and actions; 176 has no switch of its own.
- 155 shopV2 and 161 pantryLevelsV2 both own the "To get" list and the lift back to in after a shop; 165 listsV2 also owns checking off items.
- 147 occasions and 187 awayV2 both write the trip Home line ("Trip, day 2 of 3." in 147, "Trip, day 2 of 3. Packing is done." in 187); 187 depends on 147.
- 143 reviewV2 (Review's week), 159 weekReset ("Plan the week" on Review), 160 moneyMonthV2 and 168 weekThreadV2 each frame a week; 1251 and 1275 are two open PRs for finish moments already specified in 139.
