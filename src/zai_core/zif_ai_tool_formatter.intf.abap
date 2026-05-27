INTERFACE zif_ai_tool_formatter
  PUBLIC.

  METHODS format
    IMPORTING iv_name          TYPE string
              iv_description   TYPE string
              is_schema        TYPE zif_ai_tool=>ty_s_schema
    RETURNING VALUE(rr_format) TYPE REF TO data
    RAISING   zcx_ai_error.

  METHODS format_all
    IMPORTING it_defs          TYPE zif_ai_tool=>ty_t_tool_def
    RETURNING VALUE(rr_format) TYPE REF TO data
    RAISING   zcx_ai_error.
ENDINTERFACE.
