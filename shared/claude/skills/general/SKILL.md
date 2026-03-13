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

## Atomic Commits

Keep commits small and focused. Each commit should represent one logical change. Keep PRs small and reviewable — don't bundle unrelated changes together.
