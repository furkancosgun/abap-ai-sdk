CLASS zcx_ai_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_message TYPE string.

    CLASS-METHODS raise
      IMPORTING iv_message TYPE string
      RAISING   zcx_ai_error.

    CLASS-METHODS raise_syst
      RAISING zcx_ai_error.

    METHODS get_text REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA mv_message TYPE string.
ENDCLASS.


CLASS zcx_ai_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( ).
    mv_message = iv_message.
  ENDMETHOD.

  METHOD get_text.
    result = mv_message.
  ENDMETHOD.

  METHOD raise.
    RAISE EXCEPTION NEW zcx_ai_error( iv_message ).
  ENDMETHOD.

  METHOD raise_syst.
    DATA lv_message TYPE string.

    MESSAGE ID sy-msgid
            TYPE sy-msgty
            NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO lv_message.
    RAISE EXCEPTION NEW zcx_ai_error( lv_message ).
  ENDMETHOD.
ENDCLASS.
