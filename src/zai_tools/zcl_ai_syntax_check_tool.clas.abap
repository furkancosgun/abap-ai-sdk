CLASS zcl_ai_syntax_check_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_source  TYPE string OPTIONAL
                iv_program TYPE string OPTIONAL.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_syntax_result,
        is_valid TYPE abap_bool,
        message  TYPE string,
        line     TYPE i,
        word     TYPE string,
      END OF ty_s_syntax_result.

    DATA mv_source  TYPE string.
    DATA mv_program TYPE string.
ENDCLASS.


CLASS zcl_ai_syntax_check_tool IMPLEMENTATION.
  METHOD constructor.
    mv_source  = iv_source.
    mv_program = iv_program.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lv_message TYPE string.
    DATA lv_keyword TYPE string.
    DATA lv_linenum TYPE i.
    DATA lt_source  TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA ls_result  TYPE ty_s_syntax_result.

    IF mv_source IS NOT INITIAL.
      SPLIT mv_source AT cl_abap_char_utilities=>newline INTO TABLE lt_source.

      SYNTAX-CHECK FOR lt_source
                   MESSAGE lv_message
                   LINE lv_linenum
                   WORD lv_keyword
                   PROGRAM mv_program.
    ELSEIF mv_program IS NOT INITIAL.
      SYNTAX-CHECK FOR PROGRAM mv_program
                   MESSAGE lv_message
                   LINE lv_linenum
                   WORD lv_keyword.
    ELSE.
      zcx_ai_error=>raise( 'No source code or program name provided.' ).
    ENDIF.

    IF sy-subrc = 0.
      ls_result-is_valid = abap_true.
      ls_result-message  = 'Syntax is correct.'.
    ELSE.
      ls_result-is_valid = abap_false.
      ls_result-message  = lv_message.
      ls_result-line     = lv_linenum.
      ls_result-word     = lv_keyword.
    ENDIF.

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'syntax_check'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Checks ABAP source code syntax and returns any errors with line/column details.'.
  ENDMETHOD.
ENDCLASS.
