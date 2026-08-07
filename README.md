# Kanban Timeline

A native macOS menu bar app for managing tasks on a kanban board, with a
switchable calendar/Gantt timeline view — plus a desktop widget that shows
your upcoming tasks at a glance.

## What's here

- **KanbanApp** — the menu bar app (`MenuBarExtra`). Click the icon in the
  menu bar to open the panel: kanban board (drag tasks between columns) and
  a timeline view (calendar month grid or Gantt bars, toggle between them).
- **KanbanWidget** — a WidgetKit extension. Add it as a desktop widget
  (small/medium/large) to see your next few upcoming tasks without opening
  the app.
- **Shared** — SwiftData model (`TaskItem`) and the shared persistence layer.
  Both targets read/write the same SQLite file in
  `~/Library/Application Support/KanbanTimeline/`, so the widget always
  reflects what's in the app.

All data is local — no accounts, no network calls. Neither target is
sandboxed and both are signed "to run locally" (`CODE_SIGN_IDENTITY: -`), so
no Apple Developer account is required — App Groups (the sandboxed way to
share data between an app and its extensions) need a paid Apple Developer
Program membership, which this project intentionally avoids.

## Requirements

- macOS 14 (Sonoma) or later — desktop widgets require macOS 14+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj` is generated from `project.yml` and not checked in

## Build & run

```bash
./install.sh
```

This regenerates the project, builds a Release build, and installs it to
`/Applications/KanbanTimeline.app`, then launches it. Re-run it any time
you change the code. Look for the grid icon in the menu bar — the app has
no dock icon or window at launch.

To add the desktop widget: right-click the desktop → Edit Widgets → find
"Kanban Timeline" → drag it onto the desktop. (It only shows up in the
widget gallery once the app has been launched at least once from a stable
path, which is why `install.sh` puts it in `/Applications` rather than
leaving it in Xcode's DerivedData build folder.)

### Why not just build & run from Xcode?

On this project's original dev machine (Xcode 15.3, build 15E204a), Xcode's
GUI crashes with an uncaught `NSInvalidArgumentException`
(`+[PBXProject _formatForMissingPreferredProjectFormatAttribute]:
unrecognized selector`) shortly after opening the project — reproduced
across several different project configurations (with/without App Groups,
with/without a signing Team, with matched/mismatched `objectVersion`), so
it looks like a bug in that specific Xcode build rather than anything in
this project. Building and running from the command line (what
`install.sh` does) sidesteps the GUI entirely and works fine. If you're on
a newer Xcode, you likely won't hit this — feel free to open
`KanbanTimeline.xcodeproj` and use Xcode normally; `generate.sh` (used by
`install.sh`) still runs `xcodegen generate` for you.

You can still use Xcode's editor for writing code (autocomplete, jump-to-
definition, etc. all work fine) — just build/run via `./install.sh` in a
terminal instead of pressing Cmd+R, and avoid the Signing & Capabilities tab.

## Project layout

```
KanbanApp/            menu bar app target
  KanbanTimelineApp.swift   MenuBarExtra scene entry point
  ContentView.swift         Board/Timeline mode switcher
  Views/
    BoardView.swift         kanban columns, drag & drop
    TimelineView.swift      calendar + Gantt views
    TaskEditView.swift      add/edit/delete task sheet
KanbanWidget/          WidgetKit extension target
  KanbanWidgetBundle.swift
  KanbanWidget.swift        TimelineProvider + widget views
Shared/                shared between both targets
  TaskItem.swift            SwiftData model
  SharedStorage.swift        shared store file location
  PersistenceController.swift  shared ModelContainer
project.yml            XcodeGen project spec
```

## Roadmap

- [ ] Custom/renameable kanban columns
- [ ] Due-date notifications
- [ ] Menu bar icon badge for overdue tasks
- [ ] Light/dark themed widget accent colors
