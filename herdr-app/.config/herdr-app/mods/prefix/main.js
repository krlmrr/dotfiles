import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { run, hc, props, closeOverlay, focused, spaces, theme } from "herdr";

const go = (direction) => ["pane.go", { direction }];
const swap = (direction) => ["pane.swap", { direction }];

const BINDINGS = {
  "?": ["app.help"],
  "s": ["app.settings"],
  "w": ["mod.open", { name: "picker" }],
  "g": ["mod.open", { name: "picker" }],
  "shift-n": ["space.new"],
  "shift-w": ["space.rename"],
  "shift-d": ["space.close", { confirmed: true }],
  "c": ["tab.new"],
  "shift-t": ["tab.rename"],
  "shift-x": ["tab.close"],
  "n": ["tab.next"],
  "p": ["tab.prev"],
  "h": go("left"),
  "j": go("down"),
  "k": go("up"),
  "l": go("right"),
  "left": go("left"),
  "down": go("down"),
  "up": go("up"),
  "right": go("right"),
  "shift-h": swap("left"),
  "shift-j": swap("down"),
  "shift-k": swap("up"),
  "shift-l": swap("right"),
  "v": ["pane.split", { direction: "right" }],
  "-": ["pane.split", { direction: "down" }],
  "x": () => closePaneWithoutAsking(),
  "z": ["pane.zoom"],
  "b": ["layout.toggle", { id: "sidebar" }],
};

for (let index = 1; index <= 9; index++) BINDINGS[String(index)] = ["tab.select", { index }];

function closePaneWithoutAsking() {
  const now = focused();
  const space = spaces().find((s) => s.id === now?.space);
  const tab = space?.tabs.find((t) => t.id === now?.tab);
  if (!space || !tab || tab.panes > 1) return run("pane.close");
  if (space.tabs.length > 1) return run("tab.close", { id: tab.id, confirmed: true });
  run("space.close", { id: space.id, confirmed: true });
}

const MODIFIER_ONLY = new Set(["shift", "control", "ctrl", "alt", "platform", "super", "function"]);

function chordOf(event) {
  const m = event.modifiers ?? {};
  if (event.key_char === "?") return "?";
  const key = event.key === "minus" ? "-" : event.key;
  if (m.control) return "ctrl-" + key;
  return (m.shift ? "shift-" : "") + key;
}

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(50, () => this.handle.focus());
    this.unknown = null;
  }

  close() {
    closeOverlay(props().overlay);
  }

  key(event, cx) {
    cx.stop_propagation();
    if (MODIFIER_ONLY.has(event.key)) return;
    const chord = chordOf(event);
    if (chord === "escape") return this.close();
    if (chord === "ctrl-b") {
      const terminal = focused()?.terminal;
      this.close();
      if (terminal) hc(["keys", terminal, "ctrl+b"]);
      return;
    }
    const binding = BINDINGS[chord];
    if (!binding) {
      this.unknown = chord;
      cx.notify();
      return;
    }
    this.close();
    if (typeof binding === "function") binding();
    else run(binding[0], binding[1] ?? {});
  }

  render() {
    const t = theme();
    const hint = this.unknown ? `ctrl+b ${this.unknown} is not bound` : "waiting for a key · ? help · esc cancels";
    return h_flex()
      .id("prefix")
      .track_focus(this.handle)
      .on_key_down((event, cx) => this.key(event, cx))
      .size_full()
      .px(16)
      .gap(12)
      .items_center()
      .rounded(8)
      .bg(t.popover)
      .text_size(13)
      .child(div().px(8).py(2).rounded(6).bg(t.solid).text_color(t.solid_foreground).font_semibold().child("ctrl+b"))
      .child(div().flex_1().text_color(this.unknown ? t.foreground : t.muted).child(hint));
  }
}
