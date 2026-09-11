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

(source_file
  (property_declaration) @output_function)
