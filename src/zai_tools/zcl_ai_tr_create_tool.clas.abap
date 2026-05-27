CLASS zcl_ai_tr_create_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_description TYPE e07t-as4text
                iv_type        TYPE e070-trfunction.

  PRIVATE SECTION.
    DATA mv_description TYPE e07t-as4text.
    DATA mv_type        TYPE e070-trfunction.
ENDCLASS.


CLASS zcl_ai_tr_create_tool IMPLEMENTATION.
  METHOD constructor.
    mv_description = iv_description.
    mv_type = iv_type.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lv_trkorr TYPE trkorr.
    TYPES:
      BEGIN OF ty_result,
        trkorr  TYPE string,
        message TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    CALL FUNCTION 'TRINT_INSERT_NEW_COMM'
      EXPORTING  wi_kurztext   = mv_description
                 wi_trfunction = mv_type
                 wi_client     = sy-mandt
      IMPORTING we_trkorr      = lv_trkorr
      EXCEPTIONS OTHERS        = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    ls_result = VALUE #( trkorr  = lv_trkorr
                         message = |Transport request { lv_trkorr } created.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'create_transport'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Creates a new ABAP transport request with a description and type.'.
  ENDMETHOD.
ENDCLASS.
