# Eloquent Model Conventions

## Mass assignment: `$guarded`, never `$fillable`

Always use an empty guard. Never declare `$fillable`.

```php
// Wrong
protected $fillable = ['name', 'email', 'password'];

// Right
/** @var list<string> */
protected $guarded = [];
```

Only ever pass `create()` / `update()` explicit, validated data (validation lives in Form Requests), so an open guard is safe.

## Factories: the `#[UseFactory]` attribute

*Which* factory builds a model is configuration, so declare it with the attribute. Keep the `HasFactory` trait (it provides `::factory()`), but drop the `/** @use HasFactory<...> */` generic — once `#[UseFactory]` is present the generic is redundant (larastan reads the attribute; runtime resolution comes from it).

```php
use Illuminate\Database\Eloquent\Attributes\UseFactory;

// Wrong - naming-convention factory + redundant generic docblock
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory;
}

// Right - explicit config attribute, no generic docblock
#[UseFactory(UserFactory::class)]
class User extends Authenticatable
{
    use HasFactory;
}
```

## Attributes are for config only

Model PHP attributes carry *configuration* — `#[UseFactory]`, `#[ObservedBy]`, `#[ScopedBy]`, `#[CollectedBy]`. Anything schema-shaped stays a property or method:

- `$guarded`, `$hidden` → properties — never `#[Fillable]` / `#[Hidden]`
- casts → the `casts()` method

## Acting on the authenticated user

The `Login` event hands you an `Authenticatable`, not your `User`. Don't assign-then-`instanceof`. Pull the identifier off the contract and act on the typed model directly:

```php
// Wrong - set something, then check it's the thing you set
$user = $event->user;
if (! $user instanceof User) {
    return;
}
$user->update($attributes);

// Right - typed model from the start, no guard
User::whereKey($event->user->getAuthIdentifier())->update($attributes);
```
