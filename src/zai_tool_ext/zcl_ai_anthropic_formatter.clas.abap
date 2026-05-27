CLASS zcl_ai_anthropic_formatter DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_format,
        name         TYPE string,
        description  TYPE string,
        input_schema TYPE zif_ai_tool=>ty_s_schema,
      END OF ty_s_format.

    INTERFACES zif_ai_tool_formatter.
ENDCLASS.


CLASS zcl_ai_anthropic_formatter IMPLEMENTATION.
  METHOD zif_ai_tool_formatter~format.
    FIELD-SYMBOLS <fs_format> TYPE ty_s_format.

    CREATE DATA rr_format TYPE ty_s_format.
    ASSIGN rr_format->* TO <fs_format>.
    <fs_format> = VALUE #( name         = iv_name
                           description  = iv_description
                           input_schema = is_schema ).
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
ENDCLASS.
