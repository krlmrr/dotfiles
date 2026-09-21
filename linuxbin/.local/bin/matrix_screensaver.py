#!/usr/bin/env python3
"""OneDark Matrix Screensaver - Terminal-based falling code animation."""

import curses
import random
import time
import string
import sys

# OneDark color palette
COLORS = {
    "bg": (40, 44, 52),
    "green": (152, 195, 121),
    "blue": (97, 175, 239),
    "red": (224, 108, 117),
    "yellow": (229, 192, 123),
    "purple": (198, 120, 221),
    "cyan": (86, 182, 194),
    "gray": (171, 178, 191),
    "dark_gray": (92, 99, 112),
}

CHAR_POOLS = {
    "katakana": "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン",
    "latin": string.ascii_letters,
    "numbers": string.digits,
    "symbols": "!@#$%^&*()_+-=[]{}|;':\",./<>?",
}

DECAY = 0.88
THRESHOLD = 0.05
DROPS_PER_COL = 2

MOUSE_TRACKING_ON = "\033[?1003h\033[?1006h"
MOUSE_TRACKING_OFF = "\033[?1003l\033[?1006l"


def set_mouse_tracking(enabled):
    sys.stdout.write(MOUSE_TRACKING_ON if enabled else MOUSE_TRACKING_OFF)
    sys.stdout.flush()


class Drop:
    def __init__(self, x, max_y, phase, speed_range=(1, 3)):
        self.x = x
        self.y = phase
        self.phase = phase
        self.speed = random.randint(*speed_range)
        self.pool = random.choice(list(CHAR_POOLS.values()))
        self.color_idx = random.choice([1, 2, 3, 4, 5, 6])
        self.char = random.choice(self.pool)
        self.change_timer = 0
        self.length = random.randint(10, 24)

    def next_char(self):
        self.change_timer += 1
        if self.change_timer % 5 == 0:
            self.char = random.choice(self.pool)
        return self.char

    def move(self, max_y):
        cells = []
        for _ in range(self.speed):
            self.y += 1
            if self.y - self.length > max_y:
                self.y = self.phase
                self.speed = random.randint(1, 3)
                self.pool = random.choice(list(CHAR_POOLS.values()))
                self.change_timer = 0
                self.char = random.choice(self.pool)
            cells.append(self.y)
        return cells


def setup_colors(stdscr):
    curses.start_color()
    curses.use_default_colors()

    for idx, (name, rgb) in enumerate(COLORS.items(), 1):
        curses.init_color(idx, rgb[0] * 4, rgb[1] * 4, rgb[2] * 4)

    curses.init_pair(1, curses.COLOR_GREEN, -1)
    curses.init_pair(2, curses.COLOR_BLUE, -1)
    curses.init_pair(3, curses.COLOR_RED, -1)
    curses.init_pair(4, curses.COLOR_YELLOW, -1)
    curses.init_pair(5, curses.COLOR_MAGENTA, -1)
    curses.init_pair(6, curses.COLOR_CYAN, -1)
    curses.init_pair(7, curses.COLOR_WHITE, -1)


def build_drops(max_y, max_x):
    drops = []
    for x in range(max_x):
        phase = random.randint(-max_y, 0)
        for _ in range(DROPS_PER_COL):
            drops.append(Drop(x, max_y, phase))
            phase -= max_y // DROPS_PER_COL
    return drops


def build_grid(max_y, max_x):
    intensity = [[0.0] * max_x for _ in range(max_y)]
    glyphs = [[" " * 1] * max_x for _ in range(max_y)]
    colors = [[7] * max_x for _ in range(max_y)]
    return intensity, glyphs, colors


def attr_for(v, color):
    if v >= 0.9:
        return curses.color_pair(7) | curses.A_BOLD
    if v >= 0.55:
        return curses.color_pair(color) | curses.A_BOLD
    if v >= 0.3:
        return curses.color_pair(color)
    return curses.color_pair(7) | curses.A_DIM


def main(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.timeout(30)
    set_mouse_tracking(True)

    setup_colors(stdscr)

    max_y, max_x = stdscr.getmaxyx()
    intensity, glyphs, colors = build_grid(max_y, max_x)
    drops = build_drops(max_y, max_x)

    try:
        while True:
            new_y, new_x = stdscr.getmaxyx()
            if new_y != max_y or new_x != max_x:
                max_y, max_x = new_y, new_x
                intensity, glyphs, colors = build_grid(max_y, max_x)
                drops = build_drops(max_y, max_x)

            if stdscr.getch() != -1:
                break

            for drop in drops:
                for cy in drop.move(max_y):
                    cy = min(cy, max_y - 1)
                    if 0 <= cy < max_y:
                        intensity[cy][drop.x] = 1.0
                        glyphs[cy][drop.x] = drop.next_char()
                        colors[cy][drop.x] = drop.color_idx

            stdscr.erase()

            for y in range(max_y):
                row_i = intensity[y]
                row_g = glyphs[y]
                row_c = colors[y]
                for x in range(max_x):
                    v = row_i[x]
                    if v < THRESHOLD:
                        continue
                    row_i[x] = v * DECAY
                    try:
                        stdscr.addstr(y, x, row_g[x], attr_for(v, row_c[x]))
                    except curses.error:
                        pass

            stdscr.refresh()
            time.sleep(0.05)

    except KeyboardInterrupt:
        pass
    finally:
        set_mouse_tracking(False)


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)