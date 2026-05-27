CLASS zcl_ai_tr_delete_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_trkorr TYPE e070-trkorr.

  PRIVATE SECTION.
    DATA mv_trkorr TYPE e070-trkorr.
ENDCLASS.


CLASS zcl_ai_tr_delete_tool IMPLEMENTATION.
  METHOD constructor.
    mv_trkorr = iv_trkorr.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        trkorr  TYPE string,
        message TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    CALL FUNCTION 'TRINT_DELETE_COMM'
      EXPORTING  wi_trkorr = mv_trkorr
      EXCEPTIONS OTHERS    = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    ls_result = VALUE #( trkorr  = mv_trkorr
                         message = |Transport request { mv_trkorr } deleted.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'delete_transport'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Deletes an ABAP transport request by its number.'.
  ENDMETHOD.
ENDCLASS.
