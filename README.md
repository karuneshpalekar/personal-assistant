# Kanban Timeline

A native macOS app that keeps a kanban board with a switchable calendar/Gantt
timeline permanently visible on your screen, plus a menu bar icon for
quick show/hide.

## What's here

- **KanbanApp** — the app. On launch it opens a borderless floating panel
  (an `NSPanel`, not a normal window) that stays above other windows, on
  every Space, and doesn't steal focus from whatever else you're doing —
  drag it anywhere by its background. It shows the kanban board (drag
  tasks between columns) and a timeline view (calendar month grid or Gantt
  bars, toggle between them). The menu bar icon (grid glyph) toggles the
  panel's visibility if you want to hide it.
- **Shared** — `TaskItem` (a plain `Codable` struct) and `TaskStore`, which
  loads/saves the task list as JSON in
  `~/Library/Application Support/KanbanTimeline/tasks.json`.

All data is local — no accounts, no network calls, no signing/provisioning
requirements. The app is signed "to run locally," so no Apple Developer
account is needed.

### Why not a real WidgetKit desktop widget?

That was the original plan, but macOS won't trust a WidgetKit *app
extension* signed with a free personal Apple ID — confirmed by deep
diagnostics: no embedded provisioning profile gets generated even via a
genuine Xcode ⌘R, and PlugInKit (the system layer that offers widgets to
the desktop gallery) never picks up the extension, with or without one.
That's a hard requirement of a paid Apple Developer Program membership
($99/year), not something any amount of project configuration works around.

The floating panel above gets you the same practical outcome — always
visible on your screen — without an extension at all, since it's just a
regular (non-extension) window.

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
you change the code. The floating board panel appears near the top-right
of your main screen on launch; the menu bar grid icon toggles it.

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
  AppDelegate.swift          creates/owns the floating panel at launch
  FloatingPanel.swift        NSPanel subclass (floating, all-Spaces, draggable)
  ContentView.swift          Board/Timeline mode switcher
  EditorState.swift          shared state for which task is being edited
  Views/
    BoardView.swift          kanban columns, drag & drop
    TimelineView.swift       calendar + Gantt views
    TaskEditView.swift       add/edit/delete task form
Shared/
  TaskItem.swift              Codable task model
  TaskStore.swift             load/save task list to JSON
  SharedStorage.swift          JSON file location
project.yml                  XcodeGen project spec
generate.sh                  xcodegen generate + Xcode-15.3-compat patch
install.sh                   build Release + install to /Applications + launch
```

## Roadmap

- [ ] Custom/renameable kanban columns
- [ ] Due-date notifications
- [ ] Remember/restore panel position and size across launches
- [ ] Launch at login
