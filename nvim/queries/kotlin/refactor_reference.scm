; Experimental Kotlin support for refactoring.nvim.
; Reference/declaration capture, modelled after the Java queries.

; --- declarations ---

; fun f(a: Int, b: String)
(parameter
  (simple_identifier) @reference.identifier
  (user_type (type_identifier) @_type)
  (#kotlin-set-type! @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; class Foo(val a: Int)
(class_parameter
  (simple_identifier) @reference.identifier
  (user_type (type_identifier) @_type)
  (#kotlin-set-type! @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; val/var name[: Type] = value
(property_declaration
  (variable_declaration
    (simple_identifier) @reference.identifier
    (user_type (type_identifier) @_type)?)
  .
  (_)? @_value
  (#kotlin-decl-type! @_type @_value @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; fun name(...)
(function_declaration
  (simple_identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

; { a, b -> ... }
(lambda_parameters
  (variable_declaration
    (simple_identifier) @reference.identifier
    (user_type (type_identifier) @_type)?)
  (#kotlin-set-type! @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; for (x in xs)
(for_statement
  (variable_declaration
    (simple_identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; --- writes ---

(assignment
  (directly_assignable_expression
    (simple_identifier) @reference.identifier)
  (#set! reference_type write))

; --- reads ---

; "Hello $name"
(interpolated_identifier) @reference.identifier
  (#set! reference_type read)

; Any simple_identifier whose immediate parent is an expression context.
((simple_identifier) @reference.identifier
  (#has-parent? @reference.identifier
    value_argument
    call_expression
    navigation_expression
    navigation_suffix
    additive_expression
    multiplicative_expression
    comparison_expression
    equality_expression
    conjunction_expression
    disjunction_expression
    elvis_expression
    infix_expression
    range_expression
    prefix_expression
    postfix_expression
    parenthesized_expression
    indexing_expression
    jump_expression
    check_expression
    as_expression
    assignment
    if_expression
    while_statement
    for_statement
    when_condition
    when_subject
    property_declaration)
  (#set! reference_type read))
