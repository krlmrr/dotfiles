(element
  (start_tag
    "<" @delimiter
    (tag_name) @delimiter
    ">" @delimiter)
  (end_tag
    "</" @delimiter
    (tag_name) @delimiter
    ">" @delimiter @sentinel)) @container

(element
  (self_closing_tag
    "<" @delimiter
    (tag_name) @delimiter
    "/>" @delimiter @sentinel)) @container

(element
  (start_tag
    "<" @delimiter
    (tag_name) @delimiter @_tag_name
    ">" @delimiter @sentinel)
  (#any-of? @_tag_name
   "area"
   "base"
   "br"
   "col"
   "embed"
   "hr"
   "img"
   "input"
   "link"
   "meta"
   "param"
   "source"
   "track"
   "wbr")
) @container

(style_element
  (start_tag
    "<" @delimiter
    (tag_name) @delimiter
    ">" @delimiter)
  (end_tag
    "</" @delimiter
    (tag_name) @delimiter
    ">" @delimiter @sentinel)) @container

(script_element
  (start_tag
    "<" @delimiter
    (tag_name) @delimiter
    ">" @delimiter)
  (end_tag
    "</" @delimiter
    (tag_name) @delimiter
    ">" @delimiter @sentinel)) @container
