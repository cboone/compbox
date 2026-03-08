# Design: Compbox Plugin

## Context

zsh's built-in completion display (menu-select from zsh/complist) renders candidates
inline below the prompt with no visual framing. This plugin replaces that display with
a bordered popup menu styled to match tmux's native menus: rounded corners, default
terminal colors, and a red-foreground highlight for the selected item.

The popup's content aligns horizontally with the insertion point on the command line,
so candidates sit directly below (or above) where they will be inserted. The border
sits one column to the left of the content to frame it.

Requires tmux (uses `tmux capture-pane` for screen save/restore).

### Target Environment

- zsh 5.9, tmux (tmux-256color)
- Existing completion config: `menu yes select`, `list-colors` with file-type colors,
  progressive `matcher-list`, caching enabled

### Visual Target (tmux menu styles)

- `menu-border-lines rounded`: `╭`, `╮`, `╰`, `╯`, `─`, `│`
- `menu-style default`: terminal default fg/bg
- `menu-selected-style bg=terminal,fg=red`: red text for selected item
- `menu-border-style default`: default-colored borders
- Non-selected candidates use terminal default colors
- Group dividers: `├────────────────┤` (tmux menu separator style)

---

## Architecture Overview

The plugin has two layers:

1. **Interception layer**: captures completion candidates from zsh's compsys by
   wrapping the `compadd` builtin (proven pattern from fzf-tab)
1. **Presentation layer**: renders a single-column bordered popup using ANSI
   escape sequences, handles navigation via `zle recursive-edit` with a
   temporary keymap, shows ghost text preview of the selected candidate on the
   command line, and restores the underlying screen region on exit

```text
Tab press
  -> cbx-complete (zle widget)
    -> read $POSTDISPLAY (autosuggestion) for initial selection hint
    -> original expand-or-complete
      -> _main_complete (hooked)
        -> compadd (wrapped, captures candidates)
    -> process candidates (group)
    -> determine initial selection (match autosuggestion if possible)
    -> save screen region (tmux capture-pane)
    -> render popup (ANSI escape sequences)
    -> set ghost text ($POSTDISPLAY) for selected candidate
    -> recursive-edit (navigation loop)
    -> restore screen, restore ghost text
    -> if accepted: _cbx-apply (insert selected match)
    -> if cancelled: no insertion, line unchanged
```

---

## 1. Interception Layer

### 1.1 Widget Binding

On plugin load (`cbx-enable`):

1. Save current Tab binding and create a frozen copy:
   `zle -A $orig_widget .cbx-orig-$orig_widget`
1. Bind Tab to `cbx-complete` in both emacs and viins keymaps
1. Hook `compadd` by defining a shell function named `compadd` that shadows the
   builtin; this function delegates to `-cbx-compadd` for capture and uses
   `builtin compadd` for the real builtin call
1. Hook `_main_complete` by wrapping it with `-cbx-complete`
1. Save and set `zstyle ':completion:*' list-grouped false` (handle grouping
   ourselves; the original value is restored by `cbx-disable`)

### 1.2 compadd Wrapper (`-cbx-compadd`)

Replaces the `compadd` builtin. On each call from a completion function:

1. Parse all compadd flags with `zparseopts` (same flags as fzf-tab)
1. Pass through immediately if `-O`, `-A`, or `-D` flags are present (query-mode
   calls) or if `IN_CBX` is unset
1. Capture candidates: `builtin compadd -A __hits -D __dscr "$@"`
1. Assign each captured candidate a stable integer `id`
1. Pack each candidate with metadata into `_cbx_compcap` array:
   - Format: `<id>\x02<display>\x02<metadata>` where metadata is NUL-delimited
     key-value pairs
   - Keys: `word`, `apre`, `hpre`, `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`,
     `group`, `realdir`, `args`
1. Also call `builtin compadd "$@"` to keep `compstate` bookkeeping correct

### 1.3 Candidate Data Structures

The popup tracks two related collections:

```text
raw candidates
  Captured directly from wrapped `compadd` calls. Each candidate has a stable
  integer `id` and stores:
  - `display`
  - `word`
  - `group`
  - captured insertion state: `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`
  - `apre`, `hpre`, `realdir`
  - original `compadd` args

visible rows
  Derived from raw candidates for rendering. Each row stores:
  - `candidate_id` for selectable rows
  - row kind: `candidate`, `divider`, or `empty`
  - rendered text

popup state
  - raw candidate list
  - visible row list
  - selected visible-row index
  - viewport start
  - filter string
  - pending action: `accept` or `cancel`
  - saved `$POSTDISPLAY`
  - saved screen region
```

### 1.4 Selection Insertion (`_cbx-apply`)

Registered as a completion widget via `zle -C _cbx-apply complete-word _cbx-apply`.

For each selected candidate:

1. Read the selected row's stable `candidate_id`
1. Look up the captured candidate by id
1. Unpack metadata into an associative array
1. Restore `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX` to captured values
1. Call `builtin compadd` with original args + selected word

This lets zsh's own insertion machinery handle quoting, suffix management, and
prefix/suffix complexity correctly. Duplicate display strings and duplicate words
are supported because selection is id-based.

### 1.5 Edge Cases

| Case                | Behavior                                            |
| ------------------- | --------------------------------------------------- |
| No matches          | Skip popup, let zsh show its "no matches" warning   |
| Single match        | Auto-insert without showing popup                   |
| Unambiguous prefix  | Insert common prefix, show popup on next Tab        |
| Approximate matches | Strip `(#a1)` glob flags from PREFIX, add `-U` flag |

### 1.6 Suppressing Built-in menu-select

After `_main_complete` runs and candidates are captured:

```zsh
compstate[list]=
compstate[insert]=
```

This is the intended mechanism for preventing zsh's built-in completion display
from activating while still letting normal completion generation proceed.

This behavior must be validated against:

- no matches
- single match
- unambiguous prefix insertion
- repeated Tab presses with multiple matches

---

## 2. Presentation Layer

### 2.1 Popup Positioning

**Horizontal anchor**:

- The first character of popup content aligns with the insertion point on the
  command line, meaning the start of the word being completed.
- The left border sits one column to the left of the content.
- The insertion point column is derived from the DSR cursor column minus the
  display width of the current completion prefix (the text between the start of
  the word and the cursor). In zle terms: `cursor_col - ${(m)#PREFIX}`. This
  accounts for multi-byte and wide characters via the `(m)` flag.

**Cursor position source**:

- Primary approach: query the terminal with Device Status Report (DSR) via
  `\e[6n` and parse the returned `row;col`.
- DSR is a feasibility checkpoint for v1 because terminal reads inside ZLE and
  tmux may be timing-sensitive.

**Vertical placement**:

```text
space_below = LINES - cursor_row
space_above = cursor_row - 1

if menu_height <= space_below:
    popup opens below the prompt line
elif menu_height <= space_above:
    popup opens above, bottom edge adjacent to the prompt line
else:
    pick larger region, clamp menu_height, enable scrolling
```

**Horizontal overflow**:

- If the popup would exceed `$COLUMNS`, shift it left until the right border fits.
- In overflow cases, content alignment is best-effort rather than exact.

**Fallback**:

- If DSR fails or times out for an invocation, skip popup rendering and fall
  back to normal completion behavior for that keypress.

### 2.2 Layout

**Layout**: single-column only in v1.

**Width**: determined by the longest visible row content plus padding and
borders. Clamped to `COLUMNS`.

**Height**: `min(total_rows, MAX_VISIBLE)` plus borders and an optional status
line. `MAX_VISIBLE` defaults to 16.

**Descriptions**: when present, render them right-aligned in dim text within the
single column.

### 2.3 Group Dividers

When completions have multiple groups (from `compadd -X`), separate them with
horizontal divider lines matching tmux's menu separator style. No group label
text is displayed.

```text
╭────────────────────────╮
│ src/                   │
│ lib/                   │
│ docs/                  │
├────────────────────────┤
│ /usr/local/bin/        │
│ /opt/homebrew/bin/     │
╰────────────────────────╯
```

Dividers use `├` and `┤` to connect with the side borders and `─` to fill.
Dividers are non-selectable; arrow navigation skips over them. When there is
only one group (or no groups), no divider is shown.

### 2.4 Rendering Pipeline

All output is collected into a single buffer before printing.

Initial render:

1. Draw border and dividers
1. Draw visible candidate rows
1. Draw status line if needed
1. Apply selected-row highlight with red foreground

Redraw behavior:

- Selection movement repaints only the previously selected row, the newly
  selected row, ghost text, and status line if needed
- Filter changes trigger a full popup content redraw within the existing frame

**Flicker mitigation**:

- Hide cursor (`\e[?25l`) before rendering, show after (`\e[?25h`)
- Never clear the full screen; only overwrite specific cells
- Batch all escape sequences into one `printf '%b'` call per render pass

### 2.5 Scroll Indicators

When the candidate list exceeds the visible viewport:

- `▲` centered in the top border when content exists above
- `▼` in the status line when content exists below
- Status line shows `[selected/total]` right-aligned
- When filtering is active, the status line shows `filter: ...` before the count

```text
╭──────────── ▲ ───────────╮
│ lib/                     │
│ docs/                    │
│ test/                    │
│              ▼   [5/20]  │
╰──────────────────────────╯
```

### 2.6 Navigation via recursive-edit

Create a temporary keymap (`_cbx_menu`) with all navigation keys bound to
handler widgets, then enter `zle recursive-edit`.

| Key                  | Action                                              |
| -------------------- | --------------------------------------------------- |
| `Up` / `Down`        | Move selection, scroll if needed                    |
| `Tab`                | Cycle forward through selectable candidates         |
| `Shift-Tab`          | Cycle backward                                      |
| `Enter`              | Accept selected candidate                           |
| `Escape`             | Cancel (dismiss popup, no insertion)                |
| Printable characters | Append to filter, refilter candidates, reset to top |
| `Backspace`          | Delete last filter character                        |

Both accept and cancel exit recursive-edit via `zle send-break`, differentiating
through the `_cbx_state` variable. This avoids accidentally executing the command
line (which `accept-line` would do).

While the popup is open, printable keys (including space) are consumed by the
popup filter and do not modify the real command line buffer.

**Cleanup guarantees**:

On any exit from recursive-edit (accept, cancel, or interrupt):

1. Restore saved screen region
1. Restore saved `$POSTDISPLAY`
1. Remove temporary keymap
1. Show cursor (`\e[?25h`)

If `SIGINT` (Ctrl-C) exits recursive-edit, treat it as a cancel: run the same
cleanup sequence, insert nothing.

If `SIGWINCH` (terminal resize) occurs during the popup, dismiss the popup
immediately: run the cleanup sequence and fall back to `zle reset-prompt` to
redraw cleanly at the new terminal dimensions. Do not attempt to resize or
reposition the popup in v1.

### 2.7 Type-to-Filter

Typing narrows the candidate list via case-insensitive substring matching.

- Fixed-size popup (dimensions computed once on open, not resized during filtering)
- Selection and scroll reset to 0 on each filter change
- Filter string displayed in status line: `filter: ma  [1/2]`
- Empty filter result shows "no matches" in the content area
- Backspace on empty filter is a no-op (stays in browsing state)

### 2.8 Ghost Text Preview

On popup open:

- Save the current value of `$POSTDISPLAY`

While the popup is open, the selected candidate's completion suffix is shown as
dim text after the cursor on the command line, using `$POSTDISPLAY`.

- User typed `git re`, selection is `rebase`: ghost shows `base` after cursor
- User typed `ls` (empty prefix), selection is `src/`: ghost shows `src/`
- On each selection change (arrow/tab), update `$POSTDISPLAY` and call `zle -R`

On popup close:

- Restore the saved `$POSTDISPLAY` value on both accept and cancel before exiting
  the popup state

This avoids permanently clobbering ghost text owned by other widgets or plugins.

### 2.9 Autosuggestion-Aware Initial Selection

Before opening the popup, read `$POSTDISPLAY` to capture zsh-autosuggestions'
current suggestion. Extract the next word (the completion target) and search the
candidate list for a match. Use the same normalization used for row rendering.
If a single match is found, set the initial selection index so the popup opens
with that candidate highlighted and scrolled into view.

If no unambiguous match is found, fall back to selecting the first selectable
candidate.

### 2.10 Screen Save and Restore

Use `tmux capture-pane -p -e -S <start> -E <end>` to capture the rows behind the
popup, preserving ANSI styling.

On popup close:

1. For each captured screen row, move the cursor to that row's left edge
1. Reprint the preserved line content for that row
1. Redraw the prompt line as needed via `zle -R`

Notes:

- v1 assumes restore is row-based, not a full framebuffer reconstruction
- Wrapped lines and wide characters must be tested carefully
- If exact restore proves unreliable for a case, prefer falling back to a prompt
  redraw rather than leaving visual corruption

### 2.11 Color Model

v1 uses terminal default colors for all non-selected rows and a red foreground
for the selected row, matching tmux menu styling.

Support for `list-colors`, `$LS_COLORS`, and file-type-specific colorization is
deferred.

---

## 3. File Organization

```text
compbox/
  compbox.plugin.zsh                # entry point: sources lib, calls cbx-enable
  lib/
    cbx-enable.zsh                  # plugin activation (save bindings, install hooks)
    cbx-disable.zsh                 # plugin deactivation (restore everything)
    cbx-complete.zsh                # top-level Tab widget, orchestrates the flow
    -cbx-compadd.zsh                # compadd wrapper (candidate capture)
    -cbx-complete.zsh               # hooked _main_complete replacement
    -cbx-apply.zsh                  # selection insertion completion widget
    -cbx-generate-complist.zsh      # candidate processing and grouping
    position.zsh                    # cursor query (DSR), popup placement algorithm
    render.zsh                      # box drawing, content filling, differential redraw
    navigate.zsh                    # state machine, selection movement, scroll
    keymap.zsh                      # temporary keymap, handler widgets, recursive-edit
    filter.zsh                      # type-to-filter logic
    screen.zsh                      # screen save/restore (tmux capture-pane)
    ghost.zsh                       # $POSTDISPLAY management, autosuggestion read
```

**Loading strategy**: all `lib/` files are sourced eagerly by the plugin entry
point. The interception layer files must be loaded at plugin init time since they
install hooks. The presentation layer files could be lazy-loaded on first Tab
press if startup time proves to be a concern, but eager loading is simpler and
sufficient for v1.

---

## 4. Key Design Decisions

1. **compadd interception over custom completion engine**: reuses all existing
   completion functions and configuration rather than reimplementing candidate
   generation
1. **compadd interception over proxy PTY**: runs in-process with direct access
   to all metadata; avoids process synchronization, zpty timing bugs, and ANSI
   parsing complexity (see conversation notes for full analysis)
1. **recursive-edit over blocking read loop**: works within zle's event model
   correctly, no busy-waiting or async complexity
1. **tmux-only**: uses `tmux capture-pane` for character-perfect screen save/restore;
   non-tmux support deferred (would require `zle reset-prompt` fallback with
   imperfect restore of content above the prompt)
1. **Stable candidate ids**: selection and apply are keyed by captured candidate
   id, not display text, so duplicate labels are handled correctly
1. **Content-aligned positioning**: menu text aligns with the insertion point on
   the command line, not the cursor or border edge
1. **DSR with safe fallback**: exact popup placement uses DSR when available; if
   it fails for an invocation, fall back to normal completion behavior
1. **Group dividers over group headers**: tmux-style `├───┤` separators between
   groups; no label text, keeping the menu compact
1. **Ghost text via $POSTDISPLAY**: shows selected candidate suffix as dim text
   on the command line during navigation; naturally suppresses zsh-autosuggestions
1. **Autosuggestion-aware initial selection**: pre-selects the candidate matching
   zsh-autosuggestions' suggestion when the menu opens
1. **send-break to exit recursive-edit**: avoids the risk of `accept-line`
   accidentally executing the command line
1. **Fixed popup size during filtering**: avoids the complexity of dynamic resize,
   border redraw, and re-saving screen regions
1. **No configuration**: styles hardcoded to match current tmux menu config;
   configurability is a future enhancement

---

## 5. Risks and Mitigations

| Risk                                         | Mitigation                                                                                                                                |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| DSR response corrupted by simultaneous input | Read char-by-char with timeout; unlikely during widget execution                                                                          |
| Wide (CJK) characters break column alignment | Use `${(m)#string}` for display width calculation                                                                                         |
| tmux capture-pane coordinate mismatch        | Verify `pane_height` vs `$LINES`, adjust for status bars                                                                                  |
| recursive-edit + send-break side effects     | Test thoroughly; this is the approach fzf-tab validates                                                                                   |
| Performance with 1000+ candidates            | Only render visible rows (max 16); O(n) filter is fast enough                                                                             |
| $POSTDISPLAY conflicts with other widgets    | Save and restore the pre-popup value on all exits                                                                                         |
| Autosuggestion word extraction is ambiguous  | Fall back to first selectable candidate on no match or multi-match                                                                        |
| SIGINT during popup leaves artifacts         | Treat as cancel; run full cleanup sequence on all exit paths                                                                              |
| Terminal resize during popup                 | Dismiss popup, run cleanup, fall back to `zle reset-prompt`                                                                               |
| Conflict with zsh-syntax-highlighting        | Syntax highlighting hooks into `zle-line-pre-redraw`; test that popup rendering and screen restore are not disrupted by highlight redraws |
| Conflict with zsh-vi-mode                    | vi-mode manipulates keymaps; test that the temporary `_cbx_menu` keymap is not clobbered or leaked                                        |

---

## 6. Verification Plan

### Must-Pass Manual Testing

1. **Basic file completion**: `ls <Tab>` in a directory with mixed file names.
   Verify popup content aligns with insertion point, rounded borders, default
   colors, and red highlight on selected item.
1. **Descriptions**: `git <Tab>`. Verify descriptions are right-aligned and
   rendered in dim text within the single-column layout.
1. **Single match**: complete an unambiguous prefix. Verify auto-insertion without
   popup.
1. **No matches**: complete a missing target. Verify no popup appears and zsh's
   normal warning is shown.
1. **Navigation**: verify `Up`, `Down`, `Tab`, and `Shift-Tab` move selection
   correctly and skip non-selectable divider rows.
1. **Accept**: press `Enter`. Verify the selected item is inserted correctly.
1. **Cancel and restore**: press `Escape`. Verify the popup disappears and the
   screen behind it is restored cleanly.
1. **Ghost text**: while popup is open, verify dim suffix text appears after
   cursor and updates as selection changes. On exit, verify prior `$POSTDISPLAY`
   state is restored.
1. **Autosuggestion pre-selection**: type `git` with zsh-autosuggestions showing
   a history suggestion (for example `commit`). Press Tab. Verify the popup opens
   with `commit` highlighted instead of the first item.
1. **Above-cursor placement**: move prompt to bottom of terminal. Tab to complete.
   Verify popup appears above the prompt line.
1. **Type-to-filter**: open popup, type characters, verify list narrows, status
   line shows the filter, and the real command line buffer is unchanged.

### Extended / Stress Testing

1. **Group dividers**: `cd <Tab>` to see grouped directories. Verify `├───┤`
   divider lines between groups, no label text, dividers are not selectable.
1. **Scroll**: complete in a directory with many files. Verify scroll indicators
   appear and the viewport follows selection.
1. **Cursor at column 1**: popup left-aligned, border at column 1.
1. **Cursor near right edge**: popup shifts left to stay within terminal.
1. **Very long candidate names**: rows truncate safely to fit terminal width.
1. **Rapid key presses**: repeated navigation does not leave visual artifacts or
   produce input lag.
1. **Wrapped lines and wide characters**: verify restore behavior remains correct.
1. **Autosuggestion has no suggestion**: popup opens with first selectable
   candidate selected.
