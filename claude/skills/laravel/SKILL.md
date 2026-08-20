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

## Use Import Statements

Always use `use` statements at the top of the file. Never inline fully qualified class names.

```php
// Wrong
/** @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string> */

// Right
use Illuminate\Contracts\Validation\ValidationRule;

/** @return array<string, ValidationRule|array<mixed>|string> */
```

## Always Use `query()` for Eloquent Queries

Always start Eloquent queries with `Model::query()` instead of calling methods directly on the model. This returns a typed `Builder` instance, giving the IDE proper autocomplete and static analysis support.

```php
// Wrong - __callStatic magic, no IDE support
$user = User::where('active', true)->first();
$variant = ProductVariant::firstWhere('sku', $sku);

// Right - typed Builder, full IDE support
$user = User::query()->where('active', true)->first();
$variant = ProductVariant::query()->firstWhere('sku', $sku);
```

## Eloquent Models

- Mass assignment: always `protected $guarded = [];`. Never use `$fillable`.
- Declare the factory with the `#[UseFactory(XFactory::class)]` attribute. Keep the `HasFactory` trait; drop the redundant `/** @use HasFactory<XFactory> */` generic.
- Model attributes are for config only (`#[UseFactory]`, `#[ObservedBy]`, …); keep `$guarded`, `$hidden`, and `casts()` as properties/methods — never `#[Fillable]` / `#[Hidden]`.
- Don't assign-then-`instanceof` an `Authenticatable`; act on the typed model via its identifier (`User::whereKey($event->user->getAuthIdentifier())`).

Read `references/eloquent.md` before writing model code.

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

## Avoid Nested Ifs — Use Laravel Alternatives

Laravel provides expressive alternatives to nested conditionals. Use them:

- `when()` / `unless()` instead of wrapping queries in ifs
- `match()` instead of if/elseif chains
- `firstOr()` / `firstOrFail()` instead of find-then-check-null
- `?->` nullsafe operator for optional chaining
- `tap()` for acting on a value without breaking the chain
- Pipelines for sequential transformations

Build values with expressions instead of conditionally appending (`array_filter([...])` over an `if`), and keep empty method bodies on one line (`__construct(...) {}`). See `references/php-style.md`.

## Local Development

Solo (`soloterm/solo`) is always running. Use `php artisan solo` commands and assume Solo is managing background processes (Vite, queue workers, logs, etc.) — never suggest starting these manually.
