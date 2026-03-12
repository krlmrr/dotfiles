---
name: feature
description: Generate a feature plan document breaking down a task into steps.
argument-hint: [feature description]
---

# Feature Planning

When given a feature description:

1. Explore the codebase to understand the existing architecture and relevant code
2. Create a markdown file at `docs/features/<feature-name>.md` with:
   - A clear title
   - A brief summary of the feature
   - A step-by-step breakdown of the work as a checklist (`- [ ]`)
   - Each step should be specific and actionable
3. Present the plan to the user and **wait for approval before doing any implementation work**

Do not start coding until the user has reviewed the plan and given the go-ahead.
