# Design: zsh-completion-menu Plugin

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
- Group dividers: `├────────────────┤` (tmux menu separator style)

---

## Architecture Overview

The plugin has two layers:

1. **Interception layer**: captures completion candidates from zsh's compsys by
   wrapping the `compadd` builtin (proven pattern from fzf-tab)
1. **Presentation layer**: renders a bordered popup using ANSI escape sequences,
   handles navigation via `zle recursive-edit` with a temporary keymap, shows
   ghost text preview of the selected candidate on the command line

```text
Tab press
  -> zcm-complete (zle widget)
    -> read $POSTDISPLAY (autosuggestion) for initial selection hint
    -> original expand-or-complete
      -> _main_complete (hooked)
        -> compadd (wrapped, captures candidates)
    -> process candidates (colorize, group)
    -> determine initial selection (match autosuggestion if possible)
    -> save screen region (tmux capture-pane)
    -> render popup (ANSI escape sequences)
    -> set ghost text ($POSTDISPLAY) for selected candidate
    -> recursive-edit (navigation loop)
    -> restore screen, clear ghost text
    -> _zcm-apply (insert selected match)
```

---

## 1. Interception Layer

### 1.1 Widget Binding

On plugin load (`zcm-enable`):

1. Save current Tab binding and create a frozen copy:
   `zle -A $orig_widget .zcm-orig-$orig_widget`
1. Bind Tab to `zcm-complete` in both emacs and viins keymaps
1. Hook `compadd` by replacing it with `-zcm-compadd`
1. Hook `_main_complete` by wrapping it with `-zcm-complete`
1. Set `zstyle ':completion:*' list-grouped false` (handle grouping ourselves)

### 1.2 compadd Wrapper (`-zcm-compadd`)

Replaces the `compadd` builtin. On each call from a completion function:

1. Parse all compadd flags with `zparseopts` (same flags as fzf-tab)
1. Pass through immediately if `-O`, `-A`, or `-D` flags are present (query-mode
   calls) or if `IN_ZCM` is unset
1. Capture candidates: `builtin compadd -A __hits -D __dscr "$@"`
1. Pack each candidate with metadata into `_zcm_compcap` array:
   - Format: `<display>\x02<metadata>` where metadata is NUL-delimited key-value pairs
   - Keys: `word`, `apre`, `hpre`, `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`,
     `group`, `realdir`, `args`
1. Also call `builtin compadd "$@"` to keep `compstate` bookkeeping correct

### 1.3 Candidate Data Structure

```text
_zcm_compcap (array): each element is:
  <display_text>\x02<\0>\0key1\0val1\0key2\0val2...\0word\0<actual_word>

_zcm_groups (unique array): group description strings in order
```

### 1.4 Selection Insertion (`_zcm-apply`)

Registered as a completion widget via `zle -C _zcm-apply complete-word _zcm-apply`.

For each selected candidate:

1. Find matching entry in `_zcm_compcap`
1. Unpack metadata into an associative array
1. Restore `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX` to captured values
1. Call `builtin compadd` with original args + selected word

This lets zsh's own insertion machinery handle quoting, suffix management, and
prefix/suffix complexity correctly.

### 1.5 Edge Cases

| Case                | Behavior                                                   |
| ------------------- | ---------------------------------------------------------- |
| No matches          | Skip popup, let zsh show its "no matches" warning          |
| Single match        | Auto-insert without showing popup                          |
| Unambiguous prefix  | Insert common prefix, show popup on next Tab               |
| Directory descent   | Accept selection, re-trigger completion (loop in widget)    |
| Approximate matches | Strip `(#a1)` glob flags from PREFIX, add `-U` flag        |

### 1.6 Suppressing Built-in menu-select

After `_main_complete` runs and candidates are captured:

```zsh
compstate[list]=
compstate[insert]=
```

This prevents zsh's built-in completion display from activating.

---

## 2. Presentation Layer

### 2.1 Popup Positioning

**Content alignment**: the first character of menu content aligns horizontally
with the insertion point on the command line (the start of the word being
completed). The border `│` and its padding sit one column to the left.

**Vertical**: query cursor position via Device Status Report (`\e[6n`).

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

**Horizontal overflow**: if the popup would exceed `$COLUMNS`, shift it left
until the right border fits. Content alignment is best-effort in this case.

### 2.2 Layout

**Width**: determined by longest candidate + description + padding + borders.
Clamped to `COLUMNS`.

**Height**: `min(total_rows, MAX_VISIBLE)` + borders + optional status line.
`MAX_VISIBLE` defaults to 16.

**Columns**: single-column when descriptions are present. Multi-column (auto-fit)
when descriptions are absent.

**Description alignment**: right-aligned within the row, rendered in dim text
(`\e[2m`).

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

Three-stage pipeline, all output collected into a single buffer before printing:

1. **Box chrome**: draw border characters at computed position
1. **Content fill**: write candidates into content cells with list-colors applied
1. **Selection highlight**: red foreground (`\e[31m`) on the selected item

**Flicker mitigation**:

- Hide cursor (`\e[?25l`) before rendering, show after (`\e[?25h`)
- Never clear the full screen; only overwrite specific cells
- Batch all escape sequences into one `printf '%b'` call
- Differential redraw: on selection movement, only repaint the old and new
  selection rows

### 2.5 Scroll Indicators

When the candidate list exceeds the visible viewport:

- `▲` centered in the top border when content exists above
- `▼` in the status line when content exists below
- Status line shows `[selected/total]` right-aligned

```text
╭──────────── ▲ ───────────╮
│ lib/                     │
│ docs/                    │
│ test/                    │
│              ▼   [5/20]  │
╰──────────────────────────╯
```

### 2.6 Navigation via recursive-edit

Create a temporary keymap (`_zcm_menu`) with all navigation keys bound to
handler widgets, then enter `zle recursive-edit`.

| Key                      | Action                                              |
| ------------------------ | --------------------------------------------------- |
| `Up` / `Down`            | Move selection, scroll if needed                    |
| `Left` / `Right`         | Column navigation (multi-column) or no-op           |
| `Tab`                    | Cycle forward through candidates                    |
| `Shift-Tab`              | Cycle backward                                      |
| `Enter`                  | Accept selected candidate                           |
| `Escape`                 | Cancel (dismiss popup, no insertion)                 |
| `Ctrl-O`                 | Accept and infer next (directory descent)            |
| Printable characters     | Append to filter, refilter candidates, reset to top  |
| `Backspace`              | Delete last filter character                        |

Both accept and cancel exit recursive-edit via `zle send-break`, differentiating
through the `_zcm_state` variable. This avoids accidentally executing the command
line (which `accept-line` would do).

### 2.7 Type-to-Filter

Typing narrows the candidate list via case-insensitive substring matching.

- Fixed-size popup (dimensions computed once on open, not resized during filtering)
- Selection and scroll reset to 0 on each filter change
- Filter string displayed in status line: `filter: ma  [1/2]`
- Empty filter result shows "no matches" in the content area
- Backspace on empty filter is a no-op (stays in browsing state)

### 2.8 Ghost Text Preview

While the popup is open, the selected candidate's completion suffix is shown
as dim text after the cursor on the command line, using `$POSTDISPLAY`.

- User typed `git re`, selection is `rebase`: ghost shows `base` after cursor
- User typed `ls ` (empty prefix), selection is `src/`: ghost shows `src/`
- On each selection change (arrow/tab), update `$POSTDISPLAY` and call `zle -R`
- On cancel (Escape): clear `$POSTDISPLAY`; zsh-autosuggestions will reassert
  its own suggestion via its `zle-line-pre-redraw` hook
- On accept (Enter): clear `$POSTDISPLAY`; the real insertion happens via
  `_zcm-apply`

zsh-autosuggestions is suppressed during the popup by our ownership of
`$POSTDISPLAY`. No explicit disable is needed; we simply overwrite the variable.

### 2.9 Autosuggestion-Aware Initial Selection

Before opening the popup, read `$POSTDISPLAY` to capture zsh-autosuggestions'
current suggestion. Extract the next word (the completion target) and search the
candidate list for a match. If found, set the initial selection index so the
popup opens with that candidate highlighted and scrolled into view.

If no match is found (suggestion doesn't correspond to a completion candidate),
fall back to selecting the first candidate.

### 2.10 Screen Save and Restore

Use `tmux capture-pane -p -e -S <start> -E <end>` to capture the screen region
behind the popup with ANSI color escape sequences preserved. On popup close,
restore by writing captured lines back to the same positions.

### 2.11 list-colors Support

Read colors from `zstyle ':completion:*:default' list-colors`, falling back to
`$LS_COLORS`. Parse into two maps:

- **Mode-based**: `di`, `ln`, `ex`, `so`, `pi`, `bd`, `cd`, `su`, `sg`, `tw`, `ow`
- **Extension-based**: `*.zsh=...`, `*.tar.gz=...`

For file-type candidates (those with `realdir` metadata), resolve colors by
statting the file and matching mode, then falling back to extension matching.

Selected item highlight (red fg) overrides list-colors for the selected row.

---

## 3. File Organization

```text
zsh-completion-menu/
  zsh-completion-menu.plugin.zsh    # entry point: sources lib, calls zcm-enable
  lib/
    zcm-enable.zsh                  # plugin activation (save bindings, install hooks)
    zcm-disable.zsh                 # plugin deactivation (restore everything)
    zcm-complete.zsh                # top-level Tab widget, orchestrates the flow
    -zcm-compadd.zsh                # compadd wrapper (candidate capture)
    -zcm-complete.zsh               # hooked _main_complete replacement
    -zcm-apply.zsh                  # selection insertion completion widget
    -zcm-generate-complist.zsh      # candidate processing, colorizing, grouping
    position.zsh                    # cursor query (DSR), popup placement algorithm
    layout.zsh                      # width/height/column calculation
    render.zsh                      # box drawing, content filling, differential redraw
    navigate.zsh                    # state machine, selection movement, scroll
    keymap.zsh                      # temporary keymap, handler widgets, recursive-edit
    filter.zsh                      # type-to-filter logic
    screen.zsh                      # screen save/restore (tmux capture-pane)
    ghost.zsh                       # $POSTDISPLAY management, autosuggestion read
    colors.zsh                      # list-colors parsing, LS_COLORS, color lookup
```

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
1. **tmux-only**: uses `tmux capture-pane` for pixel-perfect screen save/restore;
   non-tmux support deferred (would require `zle reset-prompt` fallback with
   imperfect restore of content above the prompt)
1. **Content-aligned positioning**: menu text aligns with the insertion point on
   the command line, not the cursor or border edge
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

| Risk                                         | Mitigation                                                       |
| -------------------------------------------- | ---------------------------------------------------------------- |
| DSR response corrupted by simultaneous input  | Read char-by-char with timeout; unlikely during widget execution |
| Wide (CJK) characters break column alignment  | Use `${(m)#string}` for display width calculation                |
| tmux capture-pane coordinate mismatch         | Verify `pane_height` vs `$LINES`, adjust for status bars         |
| recursive-edit + send-break side effects      | Test thoroughly; this is the approach fzf-tab validates          |
| Performance with 1000+ candidates             | Only render visible rows (max 16); O(n) filter is fast enough    |
| $POSTDISPLAY conflicts with autosuggestions   | We own $POSTDISPLAY during popup; autosuggestions reasserts on close via its zle-line-pre-redraw hook |
| Autosuggestion word extraction is ambiguous   | Simple first-word extraction from $POSTDISPLAY; fall back to first candidate on failure |

---

## 6. Verification Plan

### Manual Testing

1. **Basic file completion**: `ls <Tab>` in a directory with mixed file types.
   Verify popup content aligns with insertion point, rounded borders, file-type
   colors from list-colors, red highlight on selected item.
1. **Ghost text**: while popup is open, verify dim suffix text appears after
   cursor. Navigate with arrows; ghost text updates to match selection.
1. **Autosuggestion pre-selection**: type `git ` with zsh-autosuggestions showing
   a history suggestion (e.g., `commit`). Press Tab. Verify the popup opens with
   `commit` highlighted instead of the first item.
1. **Command completion with descriptions**: `git <Tab>`. Verify descriptions
   are right-aligned and dimmed.
1. **Group dividers**: `cd <Tab>` to see grouped directories. Verify `├───┤`
   divider lines between groups, no label text, dividers are not selectable.
1. **Type-to-filter**: open popup, type characters, verify list narrows. Backspace
   to widen. Verify filter string shown in status line.
1. **Scroll**: complete in a directory with many files. Verify scroll indicators
   appear, viewport follows selection.
1. **Above-cursor placement**: move prompt to bottom of terminal. Tab to complete.
   Verify popup appears above the prompt line.
1. **Screen restore**: complete, then cancel with Escape. Verify the terminal
   content behind the popup is perfectly restored (tmux capture-pane).
1. **Autosuggestion restore on cancel**: after Escape, verify zsh-autosuggestions
   resumes showing its ghost text.
1. **Directory descent**: complete a directory name, press Ctrl-O, verify
   completion continues inside that directory.
1. **Single match**: complete an unambiguous prefix. Verify auto-insertion without
   popup.
1. **Content alignment**: complete after a long path (`cat src/components/<Tab>`).
   Verify menu content aligns with the character after the last `/`.

### Edge Cases

1. Cursor at column 1: popup left-aligned, border at column 1
1. Cursor near right edge: popup shifts left to stay within terminal
1. Very long candidate names: truncated to fit terminal width
1. Empty completion list: no popup, zsh's "no matches" message shown
1. Rapid arrow key presses: no visual artifacts or input lag
1. Autosuggestion has no suggestion: popup opens with first candidate selected
