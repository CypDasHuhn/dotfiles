; Experimental Kotlin support for refactoring.nvim.
; Where an extracted function is inserted: before the enclosing function.

(source_file
  _*
  [
    (line_comment)
    (multiline_comment)
  ]* @output_function.comment
  .
  (function_declaration) @output_function)

(class_declaration
  (class_body
    _*
    [
      (line_comment)
      (multiline_comment)
    ]* @output_function.comment
    .
    (function_declaration) @output_function))

; Lambdas aren't function declarations. Fall back to the top-level declaration
; that contains them so the extracted function lands at file scope and captured
; lambda parameters (which are declared after this point) become arguments.
(source_file
  (property_declaration) @output_function)
