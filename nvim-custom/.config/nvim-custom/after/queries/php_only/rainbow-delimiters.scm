(parenthesized_expression
    "(" @delimiter
    ")" @delimiter @sentinel) @container

(arguments
    "(" @delimiter
    ")" @delimiter @sentinel) @container

(formal_parameters
    "(" @delimiter
    ")" @delimiter @sentinel) @container

(array_creation_expression
    "[" @delimiter
    "]" @delimiter @sentinel) @container

(subscript_expression
    "[" @delimiter
    "]" @delimiter @sentinel) @container
