CLASS zcl_ai_gemini_formatter DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_format_function,
        name        TYPE string,
        description TYPE string,
        parameters  TYPE zif_ai_tool=>ty_s_schema,
      END OF ty_s_format_function.

    INTERFACES zif_ai_tool_formatter.

  PRIVATE SECTION.
    METHODS to_camel_case
      IMPORTING iv_field        TYPE string
      RETURNING VALUE(rv_field) TYPE string.
ENDCLASS.


CLASS zcl_ai_gemini_formatter IMPLEMENTATION.
  METHOD zif_ai_tool_formatter~format.
    FIELD-SYMBOLS <fs_format> TYPE ty_s_format_function.

    CREATE DATA rr_format TYPE ty_s_format_function.
    ASSIGN rr_format->* TO <fs_format>.
    <fs_format> = VALUE #( name        = iv_name
                           description = iv_description
                           parameters  = is_schema ).

    <fs_format>-parameters-required = VALUE #( FOR r IN is_schema-required
                                               ( to_camel_case( r ) ) ).
  ENDMETHOD.

  METHOD zif_ai_tool_formatter~format_all.
    TYPES ty_t_tools TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY.
    FIELD-SYMBOLS <fs_format> TYPE ty_t_tools.

    CREATE DATA rr_format TYPE ty_t_tools.
    ASSIGN rr_format->* TO <fs_format>.

    LOOP AT it_defs ASSIGNING FIELD-SYMBOL(<fs_def>).
      APPEND zif_ai_tool_formatter~format( iv_name        = <fs_def>-name
                                           iv_description = <fs_def>-description
                                           is_schema      = <fs_def>-schema ) TO <fs_format>.
    ENDLOOP.
  ENDMETHOD.

  METHOD to_camel_case.
    rv_field = to_mixed( val  = iv_field
                         case = 'a' ).
  ENDMETHOD.
ENDCLASS.
