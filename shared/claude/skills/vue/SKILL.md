---
name: vue
description: Vue coding style and conventions. Use when writing or modifying Vue/Blade templates and frontend code.
user-invocable: false
---

# Vue Coding Style

Follow these rules when writing or modifying Vue templates:

## Never Break Closing Tags

Never split a closing tag across lines. The closing tag belongs on its own line, intact.

```html
<!-- Wrong -->
<span
    :class="[
        open ? 'text-indigo-600' : 'text-gray-900',
        'text-sm font-medium',
    ]"
    >{{ detail.name }}</span
>

<!-- Right -->
<span
    :class="[
        open ? 'text-indigo-600' : 'text-gray-900',
        'text-sm font-medium',
    ]"
>
    {{ detail.name }}
</span>
```
