INTERFACE zif_ai_tool_registry
  PUBLIC.

  METHODS add
    IMPORTING iv_class_name TYPE string
    RAISING   zcx_ai_error.

  METHODS add_all
    IMPORTING it_class_names TYPE string_table
    RAISING   zcx_ai_error.

  METHODS remove
    IMPORTING iv_name TYPE string.

  METHODS get
    IMPORTING iv_name        TYPE string
              iv_input       TYPE any
    RETURNING VALUE(ro_tool) TYPE REF TO zif_ai_tool
    RAISING   zcx_ai_error.

  METHODS has
    IMPORTING iv_name        TYPE string
    RETURNING VALUE(rv_have) TYPE abap_bool.

  METHODS size
    RETURNING VALUE(rv_size) TYPE i.

  METHODS clear.

  METHODS get_all_definitions
    RETURNING VALUE(rt_defs) TYPE zif_ai_tool=>ty_t_tool_def.
ENDINTERFACE.
