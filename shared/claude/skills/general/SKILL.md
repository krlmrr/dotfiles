---
name: general
description: General coding style conventions. Use when writing or modifying any code.
user-invocable: false
---

# General Coding Style

Follow these rules when writing or modifying any code:

## No Comments

Never write comments in code. No docblocks, no inline comments, no TODO comments. The code should be self-explanatory through clear naming and structure.

The one exception is PHPStan type annotations. When needed, always use the single-line format:

```php
/** @var Collection<int, User> */
$users = User::all();
```

## Descriptive Variable Names

Never use single-letter variables. Use the best possible variable name — clear and precise, but not needlessly long.

## Inline Single-Use Variables

If a variable is only used once, inline it instead of assigning it.

```php
// Wrong
$activeUsers = User::where('active', true)->get();
return response()->json($activeUsers);

// Right
return response()->json(User::where('active', true)->get());
```

## Ternaries on Their Own Lines

Break ternary expressions onto separate lines so the logic is easy to follow.

```php
// Wrong
$status = $user->isActive() ? 'active' : 'inactive';

// Right
$status = $user->isActive()
    ? 'active'
    : 'inactive';
```

```js
// Wrong
const label = isEnabled ? 'On' : 'Off'

// Right
const label = isEnabled
    ? 'On'
    : 'Off'
```

## No Flying Vs

Never nest deeply. Deeply indented code (nested ifs, nested divs, nested loops) forms a "Flying V" shape that is hard to read and maintain.

- Use early returns and guard clauses instead of nested `if` statements.
- Extract components or partials when template nesting gets deep.
- Prefer flat control flow: validate and bail early, then run the happy path at the top level.

```php
// Wrong - Flying V
public function handle(Request $request): Response
{
    if ($request->has('token')) {
        if ($request->user()) {
            if ($request->user()->isAdmin()) {
                return response()->json(['ok' => true]);
            }
        }
    }

    return response()->json(['error' => 'Unauthorized'], 403);
}

// Right - guard clauses
public function handle(Request $request): Response
{
    if (! $request->has('token')) {
        return response()->json(['error' => 'Unauthorized'], 403);
    }

    if (! $request->user()?->isAdmin()) {
        return response()->json(['error' => 'Unauthorized'], 403);
    }

    return response()->json(['ok' => true]);
}
```

## Atomic Commits

Keep commits small and focused. Each commit should represent one logical change. Keep PRs small and reviewable — don't bundle unrelated changes together.
