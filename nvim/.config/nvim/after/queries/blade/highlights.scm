; inherits: html

; Blade directives - use keyword highlighting for visibility
[
  (directive)
  (directive_start)
  (directive_end)
] @keyword

[
  (php_tag)
  (php_end_tag)
] @keyword

; Echo brackets
[
  "{{"
  "}}"
] @punctuation.special

; Raw echo brackets
[
  "{!!"
  "!!}"
] @punctuation.special

[
  "("
  ")"
] @punctuation.bracket
