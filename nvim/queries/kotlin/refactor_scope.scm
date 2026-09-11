; Experimental Kotlin support for refactoring.nvim.
; Scopes used to map declarations to their enclosing block.

(function_declaration
  (function_value_parameters) @scope
  (function_body
    (statements
      .
      (_) @scope.inside) @scope))

(class_declaration
  (class_body
    .
    (_) @scope.inside)) @scope

(control_structure_body
  (statements
    .
    (_) @scope.inside) @scope)

(lambda_literal
  (statements
    .
    (_) @scope.inside) @scope)

(source_file) @scope
