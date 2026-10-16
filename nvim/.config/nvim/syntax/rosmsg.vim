" ROS .msg / .srv / .action syntax
if exists("b:current_syntax")
  finish
endif

syn match   rosmsgComment     "#.*$" contains=@Spell
syn keyword rosmsgType        bool byte char float32 float64 int8 uint8 int16 uint16 int32 uint32 int64 uint64 string wstring time duration Header
syn match   rosmsgCustomType  "^\s*\zs[A-Za-z_][A-Za-z0-9_]*/[A-Za-z0-9_/]*"
syn match   rosmsgArray       "\[\%(<=\)\?\d*\]"
syn match   rosmsgBound       "<=\d\+"
syn match   rosmsgSeparator   "^---\s*$"
syn match   rosmsgConstName   "\<[A-Z][A-Z0-9_]*\ze\s*="
syn match   rosmsgValue       "=\s*\zs[^#]*"

hi def link rosmsgComment     Comment
hi def link rosmsgType        Type
hi def link rosmsgCustomType  Structure
hi def link rosmsgArray       Delimiter
hi def link rosmsgBound       Delimiter
hi def link rosmsgSeparator   Special
hi def link rosmsgConstName   Constant
hi def link rosmsgValue       Number

let b:current_syntax = "rosmsg"
