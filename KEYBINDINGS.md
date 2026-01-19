# Neovim Keybindings Reference

> Leader key: `<Space>`

---

# Part 1: Vim for Beginners

If you're new to Vim, start here. This section explains how Vim works from the ground up.

## Why is Vim So Weird?

Every other editor works like this: you type, text appears. Simple.

Vim is different. When you open Vim and start typing, nothing happens (or worse, random things happen). That's because Vim has **modes**.

**Why?** Because Vim was designed for *editing* code, not just *writing* it. You spend most of your time reading, navigating, and changing existing code. Vim optimizes for that.

The payoff: once you learn Vim, you can edit text faster than you ever thought possible, and your hands never leave the keyboard.

---

## The 4 Modes You Need to Know

Vim has different modes for different tasks. Think of them like gears in a car.

### 1. Normal Mode (Default)
- **What it's for:** Navigating and manipulating text
- **How you know you're in it:** No `-- INSERT --` at the bottom
- **How to get here:** Press `Escape` (or `jj` with our config)

This is where you spend most of your time. Keys don't type letters—they execute commands.

### 2. Insert Mode
- **What it's for:** Actually typing text
- **How you know you're in it:** `-- INSERT --` at the bottom
- **How to get here:** Press `i` from Normal mode
- **How to leave:** Press `Escape` (or `jj`)

This works like a normal editor. Type and text appears.

### 3. Visual Mode
- **What it's for:** Selecting text
- **How you know you're in it:** `-- VISUAL --` at the bottom
- **How to get here:** Press `v` from Normal mode
- **How to leave:** Press `Escape`

Like holding Shift and using arrow keys, but better.

### 4. Command Mode
- **What it's for:** Running commands (save, quit, search/replace)
- **How you know you're in it:** Cursor is at the bottom after `:`
- **How to get here:** Press `:` from Normal mode
- **How to leave:** Press `Escape` or `Enter` (to run command)

---

## Survival Guide: How to Not Get Stuck

Memorize these. They will save you.

| Situation | Solution |
|-----------|----------|
| I'm stuck and don't know what mode I'm in | Press `Escape` a few times. You're now in Normal mode. |
| I want to type text | Press `i` to enter Insert mode, then type |
| I want to stop typing and go back | Press `Escape` (or `jj`) |
| I want to save | Press `Escape`, then type `:w` and press `Enter` |
| I want to quit | Press `Escape`, then type `:q` and press `Enter` |
| I want to save and quit | Press `Escape`, then type `:wq` and press `Enter` |
| I want to quit without saving | Press `Escape`, then type `:q!` and press `Enter` |
| I made a mistake and want to undo | Press `Escape`, then press `u` |
| I undid too much and want to redo | Press `Escape`, then press `Ctrl+r` |
| Everything is broken and I want out | Press `Escape`, then type `:qa!` and press `Enter` |

---

## The Vim Language: Verb + Noun

Here's the secret to Vim: it's a language. Once you learn the grammar, you can combine words to make sentences.

### The Grammar

```
[count] + [verb] + [modifier] + [noun]
```

- **Verb:** What you want to do (delete, change, yank/copy)
- **Modifier:** How to select (inside, around)
- **Noun:** What to act on (word, paragraph, quotes, brackets)
- **Count:** How many times (optional)

### The Verbs (Operators)

| Key | Verb | Mnemonic |
|-----|------|----------|
| `d` | Delete | **d**elete |
| `c` | Change (delete + enter insert mode) | **c**hange |
| `y` | Yank (copy) | **y**ank |
| `v` | Visual select | **v**isual |

### The Modifiers

| Key | Modifier | Meaning |
|-----|----------|---------|
| `i` | Inner | Inside the thing, not including delimiters |
| `a` | Around | The whole thing, including delimiters |

### The Nouns (Text Objects)

| Key | Noun | What it means |
|-----|------|---------------|
| `w` | Word | A word (letters, numbers, underscores) |
| `W` | WORD | A WORD (anything between spaces) |
| `s` | Sentence | A sentence |
| `p` | Paragraph | A paragraph (text between blank lines) |
| `"` | Double quotes | Text inside "quotes" |
| `'` | Single quotes | Text inside 'quotes' |
| `(` or `)` or `b` | Parentheses | Text inside (parentheses) |
| `{` or `}` or `B` | Braces | Text inside {braces} |
| `[` or `]` | Brackets | Text inside [brackets] |
| `<` or `>` | Angle brackets | Text inside <tags> |
| `t` | Tag | HTML/XML tag content |

### Putting It Together: Examples

| Command | Translation | What it does |
|---------|-------------|--------------|
| `dw` | **d**elete **w**ord | Delete from cursor to end of word |
| `diw` | **d**elete **i**nner **w**ord | Delete the word under cursor |
| `daw` | **d**elete **a**round **w**ord | Delete word + surrounding space |
| `ci"` | **c**hange **i**nner **"** | Delete text inside quotes, enter insert mode |
| `ca"` | **c**hange **a**round **"** | Delete text AND quotes, enter insert mode |
| `yi(` | **y**ank **i**nner **(** | Copy text inside parentheses |
| `dap` | **d**elete **a**round **p**aragraph | Delete the whole paragraph |
| `cit` | **c**hange **i**nner **t**ag | Change content inside HTML tag |
| `vaw` | **v**isual **a**round **w**ord | Select the word + space |
| `3dw` | **3** **d**elete **w**ord | Delete next 3 words |

### The Power of This System

Once you know the verbs and nouns, you can combine them freely:

- Know `d` (delete)? You now know `di"`, `daw`, `dip`, `dit`, etc.
- Learn a new noun like `p` (paragraph)? You now know `dip`, `cip`, `yip`, `vip`
- Learn a new verb like `>` (indent)? You now know `>ip`, `>i{`, etc.

**This is why Vim users are fast:** Instead of memorizing 100 separate shortcuts, you learn ~20 building blocks and combine them.

---

## Navigation: Moving Around

### Basic Movement

Forget arrow keys. Use these instead (your hands stay on home row):

```
     k
     ↑
 h ←   → l
     ↓
     j
```

| Key | Movement |
|-----|----------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |

**Tip:** `j` looks like a down arrow. That's how I remember it.

### Word Movement

| Key | Movement |
|-----|----------|
| `w` | Jump to start of next word |
| `b` | Jump back to start of previous word |
| `e` | Jump to end of word |

### Line Movement

| Key | Movement |
|-----|----------|
| `0` | Jump to beginning of line |
| `$` | Jump to end of line |
| `^` | Jump to first non-space character |

### File Movement

| Key | Movement |
|-----|----------|
| `gg` | Go to top of file |
| `G` | Go to bottom of file |
| `42G` | Go to line 42 |
| `Ctrl+d` | Page down (half screen) |
| `Ctrl+u` | Page up (half screen) |

### Search Movement

| Key | Action |
|-----|--------|
| `/text` | Search forward for "text" |
| `?text` | Search backward for "text" |
| `n` | Go to next search result |
| `N` | Go to previous search result |
| `*` | Search for word under cursor |
| `#` | Search backward for word under cursor |

---

## Editing: The Essentials

### Entering Insert Mode

| Key | Where cursor goes |
|-----|-------------------|
| `i` | Before cursor (insert) |
| `a` | After cursor (append) |
| `I` | Beginning of line |
| `A` | End of line |
| `o` | New line below |
| `O` | New line above |

### Deleting Without Insert Mode

| Key | What it deletes |
|-----|-----------------|
| `x` | Character under cursor |
| `dd` | Entire line |
| `D` | From cursor to end of line |

### The Dot Command: Your Best Friend

The `.` key repeats your last change. This is incredibly powerful.

**Example:** You want to delete 5 lines.
1. Press `dd` to delete one line
2. Press `.` four more times

**Example:** You want to add semicolons to multiple lines.
1. Press `A;` then `Escape` (append semicolon to end of line)
2. Move to next line with `j`
3. Press `.` to repeat
4. Repeat steps 2-3

---

## Copy, Cut, and Paste (Vim Style)

Vim calls these operations differently:

| Normal Term | Vim Term | Key |
|-------------|----------|-----|
| Copy | Yank | `y` |
| Cut | Delete | `d` |
| Paste | Put | `p` |

### How to Copy and Paste

**Copy a line:**
1. Press `yy` (yank line)
2. Move to where you want it
3. Press `p` (put after cursor) or `P` (put before cursor)

**Copy a word:**
1. Press `yiw` (yank inner word)
2. Move to where you want it
3. Press `p`

**Cut and paste:**
1. Press `dd` (delete line) or `diw` (delete word)
2. Move to where you want it
3. Press `p`

**Note:** When you delete something in Vim, it's automatically "copied" (yanked). So `dd` then `p` moves a line.

---

## Visual Mode: Selecting Text

Press `v` to enter Visual mode, then move to select text.

| Key | Selection type |
|-----|----------------|
| `v` | Character-wise selection |
| `V` | Line-wise selection |
| `Ctrl+v` | Block selection (columns) |

### Visual Mode Workflow

1. Press `v` to start selecting
2. Move with `h`, `j`, `k`, `l`, `w`, `b`, etc.
3. Do something with the selection:
   - `d` to delete
   - `y` to yank (copy)
   - `c` to change (delete + insert mode)
   - `>` to indent
   - `<` to outdent

### Shortcut: Selecting Text Objects

Instead of manually selecting, use text objects:

- `viw` - Select inner word
- `vi"` - Select inside quotes
- `vip` - Select inner paragraph
- `vi{` - Select inside braces

---

## Undo and Redo

| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl+r` | Redo |
| `.` | Repeat last change |

Vim has unlimited undo history. Press `u` as many times as you need.

---

## Your First Week Learning Path

### Day 1-2: Survival
- Use `h`, `j`, `k`, `l` to move (disable arrow keys if you're brave)
- Use `i` to enter insert mode, `Escape` to exit
- Use `:w` to save, `:q` to quit
- Use `u` to undo

### Day 3-4: Basic Editing
- Use `dd` to delete lines
- Use `yy` and `p` to copy/paste lines
- Use `o` and `O` to create new lines
- Use `A` to append at end of line

### Day 5-7: Text Objects
- Practice `ciw` (change inner word) - this is a game changer
- Practice `ci"` and `ci(` - change inside quotes/parens
- Practice `diw`, `daw`, `di"`, `da"`
- Use `.` to repeat your changes

### Week 2+: Build Speed
- Learn `w`, `b`, `e` for word movement
- Learn `f` and `t` for jumping to characters
- Learn `/` for searching
- Learn `*` to search for word under cursor
- Start using counts: `3dd` deletes 3 lines

---

## Common Mistakes and Fixes

| Mistake | What happened | Fix |
|---------|--------------|-----|
| Typed `dd` and my line is gone | You deleted a line | Press `u` to undo, or `p` to paste it back |
| I keep typing in normal mode and random things happen | Your keys are commands, not text | Press `i` first to enter insert mode |
| I pressed `q` and now it says "recording" | You started recording a macro | Press `q` again to stop |
| My screen looks weird/split | You accidentally split the window | Press `:q` to close the split |
| I can't exit Vim | The classic meme | Press `Escape`, then `:q!` and Enter |
| Search highlights won't go away | Search highlighting is sticky | Press `Escape` (our config clears it) |
| I pressed `Ctrl+s` and Vim froze | Terminal flow control (not Vim's fault) | Press `Ctrl+q` to unfreeze |

---

## Why This Is Worth It

Learning Vim is hard for about 2 weeks. Then it becomes natural. Then you can't use anything else.

**The payoff:**
- Edit at the speed of thought
- Hands never leave the keyboard
- The same skills work everywhere (servers, VS Code, any editor with Vim mode)
- You look like a wizard to your coworkers

**The investment:**
- ~2 weeks of being slower than normal
- ~1 month to feel comfortable
- ~3 months to feel fast
- Forever to master (but you don't need mastery to be productive)

---

## Quick Start Cheat Sheet

Print this out and keep it next to your keyboard:

```
MODES
  i     Enter insert mode (type text)
  Esc   Back to normal mode
  v     Enter visual mode (select text)
  :     Enter command mode

SAVE/QUIT
  :w    Save
  :q    Quit
  :wq   Save and quit
  :q!   Quit without saving

MOVEMENT
  h j k l   Left, down, up, right
  w b       Next word, previous word
  0 $       Start/end of line
  gg G      Top/bottom of file

EDITING
  i a       Insert before/after cursor
  o O       New line below/above
  dd        Delete line
  yy        Yank (copy) line
  p         Paste

TEXT OBJECTS (use with d, c, y, v)
  iw aw     Inner/around word
  i" a"     Inner/around quotes
  i( a(     Inner/around parentheses
  i{ a{     Inner/around braces

UNDO/REDO
  u         Undo
  Ctrl+r    Redo
  .         Repeat last change

SEARCH
  /text     Search forward
  n N       Next/previous match
  *         Search word under cursor
```

---

# Part 2: Keybindings Reference

Everything below is the full reference. Come back here once you're comfortable with the basics above.

---

## Table of Contents

- [Custom Keybindings](#custom-keybindings)
  - [General](#general)
  - [Navigation & Windows](#navigation--windows)
  - [File Operations](#file-operations)
  - [Search (Telescope)](#search-telescope)
  - [LSP (Language Server)](#lsp-language-server)
  - [Git](#git)
  - [Harpoon (File Marks)](#harpoon-file-marks)
  - [Terminal](#terminal)
  - [Search & Replace (Spectre)](#search--replace-spectre)
  - [Code Outline](#code-outline)
  - [Multi-Cursor](#multi-cursor)
  - [PHP Specific](#php-specific)
- [VS Code Neovim Keybindings](#vs-code-neovim-keybindings)
- [Vim Defaults](#vim-defaults)
  - [Modes](#modes)
  - [Motion](#motion)
  - [Editing](#editing)
  - [Text Objects](#text-objects)
  - [Search](#search)
  - [Marks & Jumps](#marks--jumps)
  - [Registers](#registers)
  - [Macros](#macros)
  - [Folding](#folding)
  - [Windows & Tabs](#windows--tabs)
  - [Command Mode](#command-mode)

---

## Custom Keybindings

### General

| Key | Mode | Action |
|-----|------|--------|
| `jj` | Insert | Exit insert mode |
| `;` | Normal | Enter command mode (same as `:`) |
| `<Esc>` | Normal | Clear search highlight |
| `;;` | Insert | Add semicolon at end of line |
| `,,` | Insert | Add comma at end of line |
| `i` | Normal | Insert (auto-indents on empty line) |
| `o` | Normal | New line below (reuses blank lines) |
| `O` | Normal | New line above (reuses blank lines) |
| `p` | Normal | Paste and auto-indent |
| `P` | Normal | Paste before and auto-indent |
| `j` | Normal | Down and move to first non-blank |
| `k` | Normal | Up and move to first non-blank |
| `Y` | Normal | Yank to end of line |

### Navigation & Windows

| Key | Mode | Action |
|-----|------|--------|
| `<C-h>` | Normal | Move to left window |
| `<C-j>` | Normal | Move to bottom window |
| `<C-k>` | Normal | Move to top window |
| `<C-l>` | Normal | Move to right window |
| `<leader>e` | Normal | Toggle file tree (Neo-tree) |
| `<leader>v` | Normal | New vertical split with file picker |
| `<leader>w` | Normal | Close split (or return to dashboard) |
| `<leader>x` | Normal | Close buffer (force) |
| `<leader>s` | Normal | Save file |
| `<leader>rc` | Normal | Restart Neovim (saves all files) |

### File Operations

| Key | Mode | Action |
|-----|------|--------|
| `<leader>s` | Normal | Save file |

### Search (Telescope)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>sf` | Normal | Search files |
| `<leader>sg` | Normal | Search by grep (live grep) |
| `<leader>sw` | Normal | Search current word |
| `<leader>sk` | Normal | Search keymaps |
| `<leader>sh` | Normal | Search help |
| `<leader>sd` | Normal | Search diagnostics |
| `<leader>sr` | Normal | Search resume (last search) |
| `<leader>ss` | Normal | Search select Telescope picker |
| `<leader>s/` | Normal | Search in open files |
| `<leader>gf` | Normal | Search git files |
| `<leader>?` | Normal | Find recently opened files |
| `<leader><space>` | Normal | Find existing buffers |
| `<leader>/` | Normal | Fuzzy search in current buffer |

### LSP (Language Server)

| Key | Mode | Action |
|-----|------|--------|
| `gd` | Normal | Go to definition |
| `gr` | Normal | Go to references |
| `gI` | Normal | Go to implementation |
| `gD` | Normal | Go to declaration |
| `K` | Normal | Hover documentation |
| `<C-k>` | Normal | Signature help |
| `<leader>rn` | Normal | Rename symbol |
| `<leader>ca` | Normal | Code action |
| `<leader>D` | Normal | Type definition |
| `<leader>ds` | Normal | Document symbols |
| `<leader>ws` | Normal | Workspace symbols |
| `<leader>wa` | Normal | Add workspace folder |
| `<leader>wr` | Normal | Remove workspace folder |
| `<leader>wl` | Normal | List workspace folders |
| `<leader>ih` | Normal | Toggle inlay hints (buffer) |
| `<leader>th` | Normal | Toggle inlay hints (global) |
| `[d` | Normal | Previous diagnostic |
| `]d` | Normal | Next diagnostic |
| `<leader>q` | Normal | Open diagnostics list |

### Git

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gg` | Normal | Open LazyGit |
| `]c` | Normal/Visual | Jump to next hunk |
| `[c` | Normal/Visual | Jump to previous hunk |
| `<leader>hs` | Normal | Stage hunk |
| `<leader>hs` | Visual | Stage selected hunk |
| `<leader>hr` | Normal | Reset hunk |
| `<leader>hr` | Visual | Reset selected hunk |
| `<leader>hS` | Normal | Stage buffer |
| `<leader>hu` | Normal | Undo stage hunk |
| `<leader>hR` | Normal | Reset buffer |
| `<leader>hp` | Normal | Preview hunk |
| `<leader>hb` | Normal | Blame line |
| `<leader>hd` | Normal | Diff against index |
| `<leader>hD` | Normal | Diff against last commit |
| `<leader>tb` | Normal | Toggle line blame |
| `<leader>td` | Normal | Toggle show deleted |
| `ih` | Operator/Visual | Select git hunk (text object) |

### Harpoon (File Marks)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>m` | Normal | Mark file with Harpoon |
| `<leader>h` | Normal | Open Harpoon menu |
| `<leader>1` | Normal | Jump to Harpoon file 1 |
| `<leader>2` | Normal | Jump to Harpoon file 2 |
| `<leader>3` | Normal | Jump to Harpoon file 3 |
| `<leader>4` | Normal | Jump to Harpoon file 4 |
| `<leader>5` | Normal | Jump to Harpoon file 5 |

### Terminal

| Key | Mode | Action |
|-----|------|--------|
| `<leader>tt` | Normal/Terminal | Toggle floating terminal |
| `<leader>tr` | Normal/Terminal | Reset floating terminal |
| `<leader>pt` | Normal | Run Pest tests |
| `<Esc>` | Terminal | Exit terminal mode / Close floating terminal |

### Search & Replace (Spectre)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>S` | Normal | Open Spectre (search & replace) |
| `<leader>sw` | Normal | Search current word in Spectre |
| `<leader>sw` | Visual | Search selection in Spectre |
| `<leader>sp` | Normal | Search in current file |

**Inside Spectre:**
| Key | Action |
|-----|--------|
| `dd` | Toggle item |
| `<CR>` | Open file |
| `<leader>q` | Send to quickfix |
| `<leader>c` | Input replace command |
| `<leader>o` | Show options |
| `<leader>rc` | Replace current line |
| `<leader>R` | Replace all |
| `<leader>v` | Change view mode |
| `<leader>l` | Resume last search |

### Code Outline

| Key | Mode | Action |
|-----|------|--------|
| `<leader>o` | Normal | Toggle code outline |

### Multi-Cursor

| Key | Mode | Action |
|-----|------|--------|
| `<C-g>` | Normal | Add cursor to next match (vim-visual-multi) |

### PHP Specific

| Key | Mode | Action |
|-----|------|--------|
| `<leader>dd` | Normal | Wrap line with `dd()` |

---

## VS Code Neovim Keybindings

These keybindings are active when using Neovim inside VS Code with the vscode-neovim extension.

### General

| Key | Mode | Action |
|-----|------|--------|
| `jj` | Insert | Exit insert mode |
| `;` | Normal | Command mode |
| `<Esc>` | Normal | Clear search highlight |
| `;;` | Insert | Add semicolon at end of line |
| `,,` | Insert | Add comma at end of line |
| `i` | Normal | Insert (auto-indent on empty) |
| `o` | Normal | New line below (reuse blank) |
| `O` | Normal | New line above (reuse blank) |
| `p` | Normal | Paste and indent |
| `P` | Normal | Paste before and indent |
| `j` | Normal | Down and first non-blank |
| `k` | Normal | Up and first non-blank |
| `Y` | Normal | Yank to end of line |

### Windows & Buffers

| Key | Mode | Action |
|-----|------|--------|
| `<C-h>` | Normal | Move to left editor group |
| `<C-j>` | Normal | Move to bottom editor group |
| `<C-k>` | Normal | Move to top editor group |
| `<C-l>` | Normal | Move to right editor group |
| `<leader>e` | Normal | Toggle sidebar |
| `<leader>x` | Normal | Close editor |
| `<leader>w` | Normal | Close editor |
| `<leader>s` | Normal | Save file |
| `<leader>v` | Normal | Split right |
| `<C-=>` | Normal | Increase view size |
| `<C-->` | Normal | Decrease view size |

### Search

| Key | Mode | Action |
|-----|------|--------|
| `<leader>sf` | Normal | Quick open (files) |
| `<leader>sg` | Normal | Find in files |
| `<leader>?` | Normal | Recent files |
| `<leader><space>` | Normal | Show all editors |
| `<leader>/` | Normal | Search in buffer |
| `<leader>gf` | Normal | Git files |
| `<leader>sd` | Normal | Problems panel |
| `<leader>sk` | Normal | Open keybindings |

### LSP

| Key | Mode | Action |
|-----|------|--------|
| `gd` | Normal | Go to definition |
| `gr` | Normal | Go to references |
| `gI` | Normal | Go to implementation |
| `gD` | Normal | Go to declaration |
| `K` | Normal | Hover |
| `<C-k>` | Normal | Signature help |
| `<leader>rn` | Normal | Rename |
| `<leader>ca` | Normal | Code action |
| `<leader>D` | Normal | Type definition |
| `<leader>ds` | Normal | Document symbols |
| `<leader>ws` | Normal | Workspace symbols |
| `[d` | Normal | Previous diagnostic |
| `]d` | Normal | Next diagnostic |
| `<leader>q` | Normal | Problems panel |

### Git

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gg` | Normal | Git source control |
| `<leader>gb` | Normal | Toggle line blame |

### Multi-Cursor

| Key | Mode | Action |
|-----|------|--------|
| `<C-g>` | Normal/Insert | Add cursor to next match |

### Testing

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ta` | Normal | Test all |
| `<leader>tl` | Normal | Test last |
| `<leader>tc` | Normal | Test at cursor |
| `<leader>tf` | Normal | Test file |
| `<Esc>` | - | Close test results panel |

### PHP

| Key | Mode | Action |
|-----|------|--------|
| `<leader>dd` | Normal | Wrap line with dd() |

---

## Vim Defaults

### Modes

| Key | From Mode | To Mode |
|-----|-----------|---------|
| `i` | Normal | Insert (before cursor) |
| `I` | Normal | Insert (start of line) |
| `a` | Normal | Insert (after cursor) |
| `A` | Normal | Insert (end of line) |
| `o` | Normal | Insert (new line below) |
| `O` | Normal | Insert (new line above) |
| `v` | Normal | Visual (character) |
| `V` | Normal | Visual (line) |
| `<C-v>` | Normal | Visual (block) |
| `R` | Normal | Replace mode |
| `<Esc>` | Any | Normal mode |
| `:` | Normal | Command mode |

### Motion

#### Character Movement
| Key | Action |
|-----|--------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |

#### Word Movement
| Key | Action |
|-----|--------|
| `w` | Next word (start) |
| `W` | Next WORD (start) |
| `e` | Next word (end) |
| `E` | Next WORD (end) |
| `b` | Previous word (start) |
| `B` | Previous WORD (start) |
| `ge` | Previous word (end) |
| `gE` | Previous WORD (end) |

#### Line Movement
| Key | Action |
|-----|--------|
| `0` | Start of line |
| `^` | First non-blank character |
| `$` | End of line |
| `g_` | Last non-blank character |
| `+` | First non-blank of next line |
| `-` | First non-blank of previous line |

#### Screen Movement
| Key | Action |
|-----|--------|
| `H` | Top of screen |
| `M` | Middle of screen |
| `L` | Bottom of screen |
| `<C-f>` | Page down |
| `<C-b>` | Page up |
| `<C-d>` | Half page down |
| `<C-u>` | Half page up |
| `<C-e>` | Scroll down one line |
| `<C-y>` | Scroll up one line |
| `zz` | Center cursor on screen |
| `zt` | Cursor to top of screen |
| `zb` | Cursor to bottom of screen |

#### File Movement
| Key | Action |
|-----|--------|
| `gg` | Go to first line |
| `G` | Go to last line |
| `{count}G` | Go to line {count} |
| `{count}gg` | Go to line {count} |
| `%` | Jump to matching bracket |

#### Paragraph/Section Movement
| Key | Action |
|-----|--------|
| `{` | Previous paragraph |
| `}` | Next paragraph |
| `[[` | Previous section |
| `]]` | Next section |
| `[(` | Previous unmatched `(` |
| `])` | Next unmatched `)` |
| `[{` | Previous unmatched `{` |
| `]}` | Next unmatched `}` |

### Editing

#### Basic Operations
| Key | Action |
|-----|--------|
| `x` | Delete character under cursor |
| `X` | Delete character before cursor |
| `r{char}` | Replace character with {char} |
| `s` | Substitute character (delete + insert) |
| `S` | Substitute line |
| `J` | Join line below to current |
| `gJ` | Join line without space |
| `~` | Toggle case |
| `g~{motion}` | Toggle case over motion |
| `gu{motion}` | Lowercase over motion |
| `gU{motion}` | Uppercase over motion |
| `>` | Indent (in visual mode) |
| `<` | Outdent (in visual mode) |
| `>>` | Indent line |
| `<<` | Outdent line |
| `=` | Auto-indent (in visual mode) |
| `==` | Auto-indent line |

#### Delete
| Key | Action |
|-----|--------|
| `d{motion}` | Delete over motion |
| `dd` | Delete line |
| `D` | Delete to end of line |
| `d$` | Delete to end of line |
| `d0` | Delete to start of line |
| `dw` | Delete word |
| `daw` | Delete a word (including space) |
| `diw` | Delete inner word |
| `dap` | Delete a paragraph |
| `dip` | Delete inner paragraph |
| `di"` | Delete inside quotes |
| `da"` | Delete including quotes |
| `di(` | Delete inside parentheses |
| `da(` | Delete including parentheses |
| `di{` | Delete inside braces |
| `da{` | Delete including braces |
| `dit` | Delete inside HTML tag |
| `dat` | Delete including HTML tag |

#### Change
| Key | Action |
|-----|--------|
| `c{motion}` | Change over motion |
| `cc` | Change line |
| `C` | Change to end of line |
| `cw` | Change word |
| `ciw` | Change inner word |
| `ci"` | Change inside quotes |
| `ci(` | Change inside parentheses |
| `ci{` | Change inside braces |
| `cit` | Change inside HTML tag |

#### Yank (Copy)
| Key | Action |
|-----|--------|
| `y{motion}` | Yank over motion |
| `yy` | Yank line |
| `Y` | Yank to end of line (custom, default is `yy`) |
| `yw` | Yank word |
| `yiw` | Yank inner word |
| `yi"` | Yank inside quotes |
| `yap` | Yank a paragraph |

#### Put (Paste)
| Key | Action |
|-----|--------|
| `p` | Put after cursor |
| `P` | Put before cursor |
| `gp` | Put after, cursor after text |
| `gP` | Put before, cursor after text |
| `]p` | Put after, adjust indent |
| `[p` | Put before, adjust indent |

#### Undo/Redo
| Key | Action |
|-----|--------|
| `u` | Undo |
| `<C-r>` | Redo |
| `U` | Undo all changes on line |
| `.` | Repeat last change |

### Text Objects

Used with operators like `d`, `c`, `y`, `v`:

| Text Object | Description |
|-------------|-------------|
| `iw` | Inner word |
| `aw` | A word (with trailing space) |
| `iW` | Inner WORD |
| `aW` | A WORD |
| `is` | Inner sentence |
| `as` | A sentence |
| `ip` | Inner paragraph |
| `ap` | A paragraph |
| `i"` | Inside double quotes |
| `a"` | Including double quotes |
| `i'` | Inside single quotes |
| `a'` | Including single quotes |
| `` i` `` | Inside backticks |
| `` a` `` | Including backticks |
| `i(` or `i)` or `ib` | Inside parentheses |
| `a(` or `a)` or `ab` | Including parentheses |
| `i[` or `i]` | Inside brackets |
| `a[` or `a]` | Including brackets |
| `i{` or `i}` or `iB` | Inside braces |
| `a{` or `a}` or `aB` | Including braces |
| `i<` or `i>` | Inside angle brackets |
| `a<` or `a>` | Including angle brackets |
| `it` | Inside HTML tag |
| `at` | Including HTML tag |

### Search

| Key | Action |
|-----|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` | Next search result |
| `N` | Previous search result |
| `*` | Search word under cursor (forward) |
| `#` | Search word under cursor (backward) |
| `g*` | Search word under cursor (partial match, forward) |
| `g#` | Search word under cursor (partial match, backward) |
| `gd` | Go to local definition |
| `gD` | Go to global definition |
| `f{char}` | Find char forward (on line) |
| `F{char}` | Find char backward (on line) |
| `t{char}` | Till char forward (before char) |
| `T{char}` | Till char backward (before char) |
| `;` | Repeat f/F/t/T |
| `,` | Repeat f/F/t/T (opposite direction) |

### Marks & Jumps

| Key | Action |
|-----|--------|
| `m{a-z}` | Set mark (local to buffer) |
| `m{A-Z}` | Set mark (global) |
| `` `{mark} `` | Jump to mark (exact position) |
| `'{mark}` | Jump to mark (line) |
| ``` `` ``` | Jump to position before last jump |
| `''` | Jump to line before last jump |
| `` `. `` | Jump to position of last change |
| `'.` | Jump to line of last change |
| `<C-o>` | Jump to older position in jump list |
| `<C-i>` | Jump to newer position in jump list |
| `:marks` | List all marks |
| `:jumps` | List jump history |

**Special Marks:**
| Mark | Description |
|------|-------------|
| `` `" `` | Position when last exiting buffer |
| `` `[ `` | Start of last change or yank |
| `` `] `` | End of last change or yank |
| `` `< `` | Start of last visual selection |
| `` `> `` | End of last visual selection |

### Registers

| Key | Action |
|-----|--------|
| `"{reg}` | Use register {reg} for next delete/yank/put |
| `:reg` | Show all registers |
| `<C-r>{reg}` | Insert register contents (insert mode) |

**Special Registers:**
| Register | Description |
|----------|-------------|
| `"` | Default register (unnamed) |
| `0` | Last yank |
| `1-9` | Last 9 deletes |
| `-` | Last small delete (less than one line) |
| `a-z` | Named registers |
| `A-Z` | Append to named register |
| `+` | System clipboard |
| `*` | Primary selection (Linux) |
| `/` | Last search pattern |
| `:` | Last command |
| `.` | Last inserted text |
| `%` | Current filename |
| `#` | Alternate filename |
| `=` | Expression register |
| `_` | Black hole register (discard) |

### Macros

| Key | Action |
|-----|--------|
| `q{reg}` | Start recording macro to register |
| `q` | Stop recording |
| `@{reg}` | Play macro from register |
| `@@` | Replay last macro |
| `{count}@{reg}` | Play macro {count} times |

### Folding

| Key | Action |
|-----|--------|
| `za` | Toggle fold under cursor |
| `zo` | Open fold under cursor |
| `zc` | Close fold under cursor |
| `zO` | Open all folds under cursor |
| `zC` | Close all folds under cursor |
| `zR` | Open all folds |
| `zM` | Close all folds |
| `zr` | Reduce folding (open one level) |
| `zm` | More folding (close one level) |
| `zj` | Move to next fold |
| `zk` | Move to previous fold |
| `[z` | Move to start of current fold |
| `]z` | Move to end of current fold |

### Windows & Tabs

#### Windows
| Key | Action |
|-----|--------|
| `<C-w>s` | Split horizontally |
| `<C-w>v` | Split vertically |
| `<C-w>n` | New window |
| `<C-w>q` | Close window |
| `<C-w>c` | Close window |
| `<C-w>o` | Close all other windows |
| `<C-w>h/j/k/l` | Move to window |
| `<C-w>H/J/K/L` | Move window |
| `<C-w>r` | Rotate windows |
| `<C-w>R` | Rotate windows (reverse) |
| `<C-w>x` | Exchange with next window |
| `<C-w>=` | Make all windows equal size |
| `<C-w>+` | Increase height |
| `<C-w>-` | Decrease height |
| `<C-w>>` | Increase width |
| `<C-w><` | Decrease width |
| `<C-w>_` | Maximize height |
| `<C-w>\|` | Maximize width |
| `<C-w>T` | Move window to new tab |

#### Tabs
| Key | Action |
|-----|--------|
| `:tabnew` | New tab |
| `:tabc` | Close tab |
| `:tabo` | Close all other tabs |
| `gt` | Next tab |
| `gT` | Previous tab |
| `{count}gt` | Go to tab {count} |

### Command Mode

| Command | Action |
|---------|--------|
| `:w` | Save |
| `:q` | Quit |
| `:wq` | Save and quit |
| `:x` | Save and quit (only if changed) |
| `:q!` | Quit without saving |
| `:qa` | Quit all |
| `:wa` | Save all |
| `:e {file}` | Edit file |
| `:r {file}` | Read file into buffer |
| `:bn` | Next buffer |
| `:bp` | Previous buffer |
| `:bd` | Delete buffer |
| `:ls` | List buffers |
| `:{range}s/{old}/{new}/g` | Substitute |
| `:%s/{old}/{new}/g` | Substitute in whole file |
| `:%s/{old}/{new}/gc` | Substitute with confirmation |
| `:g/{pattern}/d` | Delete lines matching pattern |
| `:v/{pattern}/d` | Delete lines NOT matching pattern |
| `:sort` | Sort lines |
| `:sort!` | Sort reverse |
| `:sort u` | Sort unique |

---

## Quick Reference Card

### Most Used Custom Keybindings

| Key | Action |
|-----|--------|
| `<leader>sf` | Find files |
| `<leader>sg` | Live grep |
| `<leader>e` | Toggle file tree |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover docs |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename |
| `<leader>gg` | LazyGit |
| `<leader>tt` | Toggle terminal |
| `<leader>m` | Harpoon mark |
| `<leader>h` | Harpoon menu |
| `<C-g>` | Multi-cursor next |

### Essential Vim

| Key | Action |
|-----|--------|
| `ciw` | Change word |
| `ci"` | Change in quotes |
| `dd` | Delete line |
| `yy` | Yank line |
| `p` | Paste |
| `u` | Undo |
| `<C-r>` | Redo |
| `.` | Repeat |
| `/` | Search |
| `*` | Search word |
| `n/N` | Next/prev result |
| `gg/G` | Top/bottom of file |
| `%` | Jump to matching bracket |
