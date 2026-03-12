---
name: laravel
description: Laravel coding style and conventions. Use when writing or modifying PHP/Laravel code in any Laravel project.
user-invocable: false
---

# Laravel Coding Style

Follow these rules when writing or modifying Laravel code:

## Validation Belongs in Request Classes

Never validate in controllers. Always create a dedicated Form Request class.

```php
// Wrong - validation in controller
public function store(Request $request)
{
    $request->validate(['name' => 'required']);
}

// Right - use a Form Request
public function store(StoreProjectRequest $request)
{
    // $request is already validated
}
```

When creating validation rules, put them in a Form Request class (`php artisan make:request`). Use `authorize()` for authorization logic and `rules()` for validation.

## Controller Methods

Controllers may only contain these methods: `__invoke`, `index`, `show`, `create`, `store`, `edit`, `update`, `destroy`, `forceDelete`. Nothing else. If you need other actions, create a new controller.

## Method Chaining

One method per line when chaining.

```php
// Wrong
$users = User::where('active', true)->where('role', 'admin')->orderBy('name')->get();

// Right
$users = User::where('active', true)
    ->where('role', 'admin')
    ->orderBy('name')
    ->get();
```

## Code Formatting

Run code formatting frequently after making changes. Prefer Duster over Pint, but fall back to Pint if Duster is not installed:

```bash
# Preferred
./vendor/bin/duster fix

# Fallback if Duster is not installed
./vendor/bin/pint
```

## Local Development

Solo (`soloterm/solo`) is always running. Use `php artisan solo` commands and assume Solo is managing background processes (Vite, queue workers, logs, etc.) — never suggest starting these manually.
