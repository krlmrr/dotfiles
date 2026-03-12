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

Do not write tests during implementation. Tests come after the feature has been verified working by the user.

## Feature Boundaries

When breaking down work, treat these as separate features:

- **Index** — model, migration, factory, seeder, controller, and list view
- **Show** — controller action and detail view (model already exists from Index)
- **Create + Store** — Form Request class and controller actions
- **Edit + Update** — Form Request class and controller actions
- **Delete + ForceDelete** — controller actions

Each feature should be planned and implemented independently. Earlier features build the foundation (model, migration, etc.) that later features build on.

## One at a Time

Implement one feature at a time. After completing a feature, stop and wait for the user to test and confirm it works before moving on to the next one. Update the checklist in the feature document as steps are completed.
