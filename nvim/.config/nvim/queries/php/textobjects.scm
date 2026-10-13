; extends

(_
  (compound_statement
    .
    "{"
    _+ @block.inner
    "}") @block.outer)
