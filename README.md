# Personal Assistant

A native macOS app that keeps a kanban board with a calendar timeline
permanently visible on your screen as a floating panel, with notifications
for daily check-ins and upcoming deadlines.

## What's here

- **The panel** — on launch, the app opens a borderless floating panel (an
  `NSPanel`, not a normal window) that stays put on whichever desktop Space
  it was opened on — it doesn't follow you into other Spaces or bleed into
  other apps' full-screen mode, and it uses normal window layering (not
  always-on-top), so whichever app you actually click comes to front. Drag
  it by its header to reposition, or resize it by its edges (both are
  remembered across launches). Hide it via the eye-slash button or the menu
  bar icon; bring it back the same way.
- **Board** — kanban columns (Backlog/To Do/In Progress/Done), plus a
  computed **Deadline Missed** column for anything overdue and not done.
  Drag tasks between columns. Click a card or **New task** to add/edit/
  delete a task (title, notes, status, priority, start/due dates,
  recurrence, time estimate) in an in-place editor. Backlog tasks
  auto-promote to To Do once their deadline is within 3 days.
- **Timeline** — a calendar month grid showing tasks on their due date.
- **Done** — a flat list of every completed task.
- **Filters** — search, priority chips, a specific due-date filter, and a
  "No distraction" toggle that narrows the board to only today/tomorrow.
- **Appearance** — a System/Light/Dark toggle (segmented, SF Symbols) using
  system colors throughout, so both modes stay correct automatically.
- **Notifications** — a "check your tasks" reminder once per day (on
  launch and whenever the Mac wakes from sleep, naming what's actually due/
  overdue), and a per-task alert 24 hours before its due date with Snooze/
  Mark Done actions. Optionally syncs open tasks to a Reminders list too,
  so due-date alerts also show up on iPhone via iCloud. The app registers
  itself as a login item so it's actually running to catch the wake event.
- **Menu bar icon** (grid glyph) — toggles the panel's visibility if you
  want to hide it without quitting; there's also a Hide button on the panel
  itself.

All data is local — a plain JSON file at
`~/Library/Application Support/PersonalAssistant/tasks.json`. No accounts,
no network calls, no signing/provisioning requirements; the app is signed
"to run locally," so no Apple Developer account is needed.

### Why not a real WidgetKit desktop widget?

That was the original plan, but macOS won't trust a WidgetKit *app
extension* signed with a free personal Apple ID — confirmed by deep
diagnostics: no embedded provisioning profile gets generated even via a
genuine Xcode ⌘R, and PlugInKit (the system layer that offers widgets to
the desktop gallery) never picks up the extension, with or without one.
That's a hard requirement of a paid Apple Developer Program membership
($99/year), not something any amount of project configuration works around.

The floating panel gets you the same practical outcome — always visible on
your screen — without an extension at all, since it's just a regular
(non-extension) window.

### Why not SwiftData?

Also tried first. `ModelContext.insert()` hung indefinitely on this
project's Xcode 15.3 toolchain — confirmed with step-by-step logging
(execution stopped and never resumed) and reproduced even with the
database file wiped clean. Replaced with a plain `Codable` struct +
`TaskStore` that reads/writes a JSON file directly — simpler, and the
hang is gone.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj` is generated from `project.yml` and not checked in

## Build & run

```bash
./install.sh
```

This regenerates the project, builds a Release build, and installs it to
`/Applications/PersonalAssistant.app`, then launches it. Re-run it any time
you change the code. The panel appears near the top-right of your main
screen on launch; the menu bar grid icon toggles it.

The first launch will prompt for notification permission — allow it, or
the daily reminder and deadline alerts won't display.

### Verifying a UI change

A DEBUG-only screenshot tour walks Board/Timeline/Done and the task
editor, in both light and dark mode:

```bash
PA_SHOTS=/tmp/pa-shots /Applications/PersonalAssistant.app/Contents/MacOS/PersonalAssistant
```

Saves PNGs of the panel's own window to the given directory (no
screen-recording permission needed — it images its own window) and exits
with `SHOTS OK` on success.

### Why not just build & run from Xcode?

On this project's original dev machine (Xcode 15.3, build 15E204a), Xcode's
GUI crashes with an uncaught `NSInvalidArgumentException`
(`+[PBXProject _formatForMissingPreferredProjectFormatAttribute]:
unrecognized selector`) shortly after opening the project — reproduced
across several different project configurations, so it looks like a bug in
that specific Xcode build rather than anything in this project. Building
and running from the command line (what `install.sh` does) sidesteps the
GUI entirely and works fine. If you're on a newer Xcode, you likely won't
hit this — feel free to open `PersonalAssistant.xcodeproj` and use Xcode
normally; `generate.sh` (used by `install.sh`) still runs `xcodegen
generate` for you. Plain `Product > Run` (⌘R) works fine even on the buggy
Xcode build — the crash is specifically tied to opening the Signing &
Capabilities tab, so just avoid that.

## Project layout

```
KanbanApp/
  PersonalAssistantApp.swift @main entry point, menu bar icon
  AppDelegate.swift          owns the floating panel + notification setup
  FloatingPanel.swift        NSPanel subclass (normal layering, single-Space, resizable)
  DragHandle.swift           scoped window-drag support for the header
  ButtonStyles.swift         fullyClickable() hit-area helper
  Screenshots.swift          DEBUG screenshot verification tour
  NotificationManager.swift  daily reminder + 24h-before-deadline alerts
  RemindersSync.swift        optional iPhone sync via Reminders/iCloud
  LaunchAtLogin.swift        SMAppService login-item wrapper
  ContentView.swift          header, filter bar, board/timeline/done switch
  EditorState.swift          shared state for which task is being edited
  PanelState.swift           shared hidden/mode state
  Theme.swift                Motion, Tag/TagBadge, FilterChip, cardStyle, AppearanceToggle
  Views/
    BoardView.swift          kanban columns incl. Deadline Missed, drag & drop
    TimelineView.swift        calendar month view
    DoneListView.swift        completed tasks, plain rows
    TaskEditView.swift        add/edit/delete task form
    SettingsView.swift        launch-at-login, Reminders sync toggles
Shared/
  TaskItem.swift              Codable task model, recurrence rules
  TaskStore.swift             load/save task list to JSON, schedules notifications
  SharedStorage.swift          JSON file location
project.yml                  XcodeGen project spec
generate.sh                  xcodegen generate + Xcode-15.3-compat patch
install.sh                   build Release + install to /Applications + launch
```
