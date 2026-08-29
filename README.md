# Kanban Timeline

A native macOS app that keeps a kanban board with a calendar timeline
permanently visible on your screen as a floating panel, with notifications
for daily check-ins and upcoming deadlines.

## What's here

- **The panel** — on launch, the app opens a borderless floating panel (an
  `NSPanel`, not a normal window) that stays above other windows on
  whichever desktop Space it was opened on — it doesn't follow you into
  other Spaces or bleed into other apps' full-screen mode, and it doesn't
  steal focus from whatever else you're doing. Drag it by its toolbar
  header to reposition. Click the **collapse** button to shrink it to a
  small pill (open-task count, due-today count); tap the pill to expand
  back.
- **Board** — kanban columns (Backlog/To Do/In Progress/Done), drag tasks
  between them. Click a card or **New Task** to add/edit/delete a task
  (title, notes, status, priority, start/due dates) in an in-place editor.
- **Timeline** — a calendar month grid showing tasks on their due date.
- **Appearance** — a System/Light/Dark toggle (sun/moon icon in the
  toolbar) with a hand-tuned color palette per mode (`Theme.swift`) rather
  than relying on generic system grays.
- **Notifications** — a "check your tasks" reminder once per day (on
  launch and whenever the Mac wakes from sleep), and a per-task alert 24
  hours before its due date. The app registers itself as a login item so
  it's actually running to catch the wake event.
- **Menu bar icon** (grid glyph) — toggles the panel's visibility if you
  want to hide it without quitting.

All data is local — a plain JSON file at
`~/Library/Application Support/KanbanTimeline/tasks.json`. No accounts, no
network calls, no signing/provisioning requirements; the app is signed "to
run locally," so no Apple Developer account is needed.

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
`/Applications/KanbanTimeline.app`, then launches it. Re-run it any time
you change the code. The panel appears near the top-right of your main
screen on launch; the menu bar grid icon toggles it.

The first launch will prompt for notification permission — allow it, or
the daily reminder and deadline alerts won't display.

### Why not just build & run from Xcode?

On this project's original dev machine (Xcode 15.3, build 15E204a), Xcode's
GUI crashes with an uncaught `NSInvalidArgumentException`
(`+[PBXProject _formatForMissingPreferredProjectFormatAttribute]:
unrecognized selector`) shortly after opening the project — reproduced
across several different project configurations, so it looks like a bug in
that specific Xcode build rather than anything in this project. Building
and running from the command line (what `install.sh` does) sidesteps the
GUI entirely and works fine. If you're on a newer Xcode, you likely won't
hit this — feel free to open `KanbanTimeline.xcodeproj` and use Xcode
normally; `generate.sh` (used by `install.sh`) still runs `xcodegen
generate` for you. Plain `Product > Run` (⌘R) works fine even on the buggy
Xcode build — the crash is specifically tied to opening the Signing &
Capabilities tab, so just avoid that.

## Project layout

```
KanbanApp/
  KanbanTimelineApp.swift   @main entry point, menu bar icon
  AppDelegate.swift          owns the floating panel + notification setup
  FloatingPanel.swift        NSPanel subclass (floating, single-Space, collapsible)
  DragHandle.swift           scoped window-drag support for the toolbar header
  NotificationManager.swift  daily reminder + 24h-before-deadline alerts
  ContentView.swift          toolbar, board/timeline switch, compact pill, appearance toggle
  EditorState.swift          shared state for which task is being edited
  PanelState.swift           shared collapsed/expanded state
  Theme.swift                light/dark color palette
  Views/
    BoardView.swift          kanban columns, drag & drop
    TimelineView.swift       calendar month view
    TaskEditView.swift       add/edit/delete task form
Shared/
  TaskItem.swift              Codable task model
  TaskStore.swift             load/save task list to JSON, schedules notifications
  SharedStorage.swift          JSON file location
project.yml                  XcodeGen project spec
generate.sh                  xcodegen generate + Xcode-15.3-compat patch
install.sh                   build Release + install to /Applications + launch
```


