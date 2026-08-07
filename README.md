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
  Both targets read/write the same store via an **App Group** container, so
  the widget always reflects what's in the app.

All data is local — no accounts, no network calls.

## Requirements

- macOS 14 (Sonoma) or later — desktop widgets require macOS 14+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj` is generated from `project.yml` and not checked in

## Build & run

```bash
xcodegen generate
open KanbanTimeline.xcodeproj
```

Then in Xcode:
1. Select the `KanbanTimeline` scheme.
2. Set your Development Team on both the `KanbanApp` and `KanbanWidgetExtension`
   targets (Signing & Capabilities) — required for App Group entitlements to work.
3. Build & run (`Cmd+R`). The app has no dock icon or window at launch — look
   for the grid icon in the menu bar.
4. To add the widget: right-click the desktop → Edit Widgets → find
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
  AppGroup.swift             App Group container id/URL
  PersistenceController.swift  shared ModelContainer
project.yml            XcodeGen project spec
```

## Roadmap

- [ ] Custom/renameable kanban columns
- [ ] Due-date notifications
- [ ] Menu bar icon badge for overdue tasks
- [ ] Light/dark themed widget accent colors
