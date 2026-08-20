# PHP Style Details

## Build results with expressions, not conditional assignment

Prefer an expression that produces the value over an `if` that mutates one. (Simple guard-clause early returns are fine — see the `general` skill's "No Flying Vs". This is about *building values*, not bailing early.)

```php
// Wrong - conditionally append with an if
$attributes = ['ip_address' => $this->request->ip()];

if ($timezone = Timezone::sanitize($this->request->input('timezone'))) {
    $attributes['timezone'] = $timezone;
}

// Right - build it, then filter
$attributes = array_filter([
    'ip_address' => $this->request->ip(),
    'timezone' => Timezone::sanitize($this->request->input('timezone')),
]);
```

Reach for `match`, `when()` / `unless()`, `firstOr()` / `firstOrFail()`, `?->`, `array_filter`, `tap()`, and pipelines before reaching for `if`.

A guard clause that just validates inputs is redundant when the expression already handles the empty/invalid case:

```php
// Wrong - guard duplicates what in_array already does
public static function sanitize(?string $timezone): ?string
{
    if ($timezone === null || $timezone === '') {
        return null;
    }

    return in_array($timezone, timezone_identifiers_list(), true) ? $timezone : null;
}

// Right - strict in_array already rejects null and ''
public static function sanitize(?string $timezone): ?string
{
    return in_array($timezone, timezone_identifiers_list(), true)
        ? $timezone
        : null;
}
```

## Empty method bodies stay on one line

```php
// Wrong
public function __construct(private Request $request)
{
    //
}

// Right (Pint's single_line_empty_body keeps this)
public function __construct(private Request $request) {}
```

A constructor cannot declare a return type — `__construct(...): void` is a fatal error.
