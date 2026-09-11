; Experimental Kotlin support for refactoring.nvim.
; The function surrounding the selection (used for placement/indentation).

(source_file
  (function_declaration) @input_function)

(class_declaration
  (class_body
    (function_declaration) @input_function)
  (#set! method))
