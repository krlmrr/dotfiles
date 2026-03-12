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
