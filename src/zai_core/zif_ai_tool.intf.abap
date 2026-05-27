INTERFACE zif_ai_tool
  PUBLIC.

  TYPES:
    BEGIN OF ty_s_schema,
      type       TYPE string,
      properties TYPE REF TO data,
      required   TYPE STANDARD TABLE OF string WITH EMPTY KEY,
    END OF ty_s_schema.

  TYPES:
    BEGIN OF ty_s_tool_def,
      name        TYPE string,
      class_name  TYPE string,
      description TYPE string,
      schema      TYPE ty_s_schema,
    END OF ty_s_tool_def,
    ty_t_tool_def TYPE STANDARD TABLE OF ty_s_tool_def WITH EMPTY KEY.

  CLASS-METHODS get_name
    RETURNING VALUE(rv_name) TYPE string.

  CLASS-METHODS get_description
    RETURNING VALUE(rv_description) TYPE string.

  METHODS execute
    RETURNING VALUE(rv_result) TYPE string
    RAISING   zcx_ai_error.

ENDINTERFACE.
