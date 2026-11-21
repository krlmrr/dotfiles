import { View, div } from "gpui-kit";
import { spaces, run } from "herdr";

const CHECK_EVERY_MS = 250;

export default class TabAutohide extends View {
  init(_props, cx) {
    this.tabBarShown = null;
    this.check(cx);
  }

  check(cx) {
    const space = spaces().find((s) => s.active);
    const wanted = (space?.tabs.length ?? 0) > 1;
    if (wanted !== this.tabBarShown) {
      this.tabBarShown = wanted;
      run(wanted ? "layout.show" : "layout.hide", { id: "tabs" });
    }
    cx.timer.after(CHECK_EVERY_MS, () => this.check(cx));
  }

  render() {
    return div();
  }
}
