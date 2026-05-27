CLASS zcl_ai_tr_copy_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_from_trkorr TYPE e070-trkorr
                iv_to_trkorr   TYPE e070-trkorr.

  PRIVATE SECTION.
    DATA mv_from_trkorr TYPE e070-trkorr.
    DATA mv_to_trkorr   TYPE e070-trkorr.
ENDCLASS.


CLASS zcl_ai_tr_copy_tool IMPLEMENTATION.
  METHOD constructor.
    mv_from_trkorr = iv_from_trkorr.
    mv_to_trkorr   = iv_to_trkorr.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        from_trkorr TYPE string,
        to_trkorr   TYPE string,
        message     TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    CALL FUNCTION 'TR_COPY_COMM'
      EXPORTING  wi_dialog                = abap_false
                 wi_trkorr_from           = mv_from_trkorr
                 wi_trkorr_to             = mv_to_trkorr
                 wi_without_documentation = 'X'
      EXCEPTIONS OTHERS                   = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    ls_result = VALUE #( from_trkorr = mv_from_trkorr
                         to_trkorr   = mv_to_trkorr
                         message     = |Copied { mv_from_trkorr } to { mv_to_trkorr }.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'copy_transport'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Copies objects from one transport request to another.'.
  ENDMETHOD.
ENDCLASS.
