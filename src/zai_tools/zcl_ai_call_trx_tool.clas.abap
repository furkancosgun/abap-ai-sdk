CLASS zcl_ai_call_trx_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    TYPES:
      BEGIN OF ty_s_parameter,
        id    TYPE tpara-paramid,
        value TYPE fieldvalue,
      END OF ty_s_parameter.
    TYPES ty_t_parameters TYPE STANDARD TABLE OF ty_s_parameter WITH EMPTY KEY.

    METHODS constructor
      IMPORTING iv_tcode  TYPE tstc-tcode
                it_params TYPE ty_t_parameters.

  PRIVATE SECTION.
    DATA mv_tcode  TYPE tstc-tcode.
    DATA mt_params TYPE ty_t_parameters.
ENDCLASS.


CLASS zcl_ai_call_trx_tool IMPLEMENTATION.
  METHOD constructor.
    mv_tcode = iv_tcode.
    mt_params = it_params.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_s_result,
        tcode   TYPE string,
        message TYPE string,
      END OF ty_s_result.
    DATA ls_result TYPE ty_s_result.

    SELECT SINGLE COUNT(*) FROM tstc
      WHERE tcode = @mv_tcode.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise( |Transaction code { mv_tcode } does not exist.| ).
    ENDIF.

    LOOP AT mt_params ASSIGNING FIELD-SYMBOL(<fs_param>).
      SET PARAMETER ID <fs_param>-id FIELD <fs_param>-value.
    ENDLOOP.

    CALL TRANSACTION mv_tcode WITH AUTHORITY-CHECK AND SKIP FIRST SCREEN.

    ls_result = VALUE #( tcode   = mv_tcode
                         message = |Transaction { mv_tcode } executed.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'call_transaction'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Calls an ABAP transaction by its transaction code (TCODE).'.
  ENDMETHOD.
ENDCLASS.
