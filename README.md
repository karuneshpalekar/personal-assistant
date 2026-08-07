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
./generate.sh
open KanbanTimeline.xcodeproj
```

`generate.sh` runs `xcodegen generate` and then patches the project's
`objectVersion`. XcodeGen 2.46+ writes the Xcode 16+ project format
(`objectVersion = 77`), which crashes older Xcode (15.x) as soon as you open
a target's Signing & Capabilities tab
(`+[PBXProject _formatForMissingPreferredProjectFormatAttribute]:
unrecognized selector`). The project doesn't use any features that require
the newer format, so the script downgrades it to `56`. If you're on Xcode 16+
you can just run `xcodegen generate` directly instead.

Then in Xcode:
1. Select the `KanbanTimeline` scheme.
2. Build & run (`Cmd+R`) — no signing setup needed. The app has no dock icon
   or window at launch — look for the grid icon in the menu bar.
3. To add the widget: right-click the desktop → Edit Widgets → find
   "Kanban Timeline" → drag it onto the desktop.

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
