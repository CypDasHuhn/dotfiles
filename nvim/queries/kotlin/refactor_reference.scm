(parameter
  (simple_identifier) @reference.identifier
  (user_type (type_identifier) @_type)
  (#kotlin-set-type! @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(class_parameter
  (simple_identifier) @reference.identifier
  (user_type (type_identifier) @_type)
  (#kotlin-set-type! @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(property_declaration
  (variable_declaration
    (simple_identifier) @reference.identifier
    (user_type (type_identifier) @_type)?)
  .
  (_)? @_value
  (#kotlin-decl-type! @_type @_value @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(function_declaration
  (simple_identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(lambda_parameters
  (variable_declaration
    (simple_identifier) @reference.identifier
    (user_type (type_identifier) @_type)?)
  (#kotlin-set-type! @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(for_statement
  (variable_declaration
    (simple_identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(assignment
  (directly_assignable_expression
    (simple_identifier) @reference.identifier)
  (#set! reference_type write))

(interpolated_identifier) @reference.identifier
  (#set! reference_type read)

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
