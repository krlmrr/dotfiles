---
name: feedback-no-time-estimates
description: Don't give time/duration estimates for tasks ("an afternoon", "1-2 hours", "2-3 weeks of evenings", "10 minutes"). Karl finds them noise at best, wrong at worst.
metadata:
  type: feedback
---

Don't include ANY time references in responses. This covers two distinct things:

**1. Duration estimates** (how long something will take):
- "an afternoon", "1-2 hours", "2-3 weeks of evenings", "10 minutes of setup", "takes ~30 seconds to pull"

**2. Elapsed-time claims** (how long something has taken — claims about session length, when something happened earlier in the conversation, "we've been at this for X"):
- "you're 6 hours into this project" (turned out to be ~1 hour — Karl called this out)
- "we've been talking for a while"
- "earlier this morning" / "this afternoon"
- Anything that locates a past event on a wall clock

**3. Suggestions to stop/pause based on assumed lateness or tiredness**:
- "given how late it is, let's pick this up tomorrow"
- "you've been at this a while, want to call it a night?"
- "this can wait for a fresh session"
- "if you're cooked, we can bail" / "fresh brains tomorrow"
- Anything that pushes toward stopping because I assumed the user is tired or it's late. Karl will tell me when he's done. Don't decide for him.

**Why:** I have no reliable sense of elapsed time within a session OR future duration of tasks. Both kinds of estimates are usually wrong, sometimes wildly. Even when roughly right they don't help — Karl is a fullstack dev who can judge effort himself, and he can see when things happened in the conversation if he cares. The pattern of being repeatedly wrong about time is the actual irritant. Note that wall-clock anchors that come from real sources (timestamps in tool output, the system clock, dates in user messages) are fine — the problem is *guessing* about time.

**How to apply:** Describe scope by what's involved (components, integration points, complexity factors, fragility) — not by hours/days. If a comparison helps, anchor it to other code ("similar size to the buildghostty script") rather than wall-clock time. When referring to earlier work in the conversation, use structural language ("the change we made to the firewall rules", "when we set up the Mullvad exit node") instead of temporal ("a few hours ago", "earlier today"). Let Karl form his own time picture.

Related: [[feedback-stop-guessing]] — same family. When unsure, ask or describe structure, don't fabricate quantitative answers.
