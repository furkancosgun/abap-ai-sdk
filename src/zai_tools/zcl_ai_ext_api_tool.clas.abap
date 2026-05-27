CLASS zcl_ai_ext_api_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_url     TYPE string
                iv_method  TYPE string    DEFAULT 'GET'
                iv_body    TYPE string    OPTIONAL
                it_headers TYPE tihttpnvp OPTIONAL.

  PRIVATE SECTION.
    DATA mv_url     TYPE string.
    DATA mv_method  TYPE string.
    DATA mv_body    TYPE string.
    DATA mt_headers TYPE tihttpnvp.
ENDCLASS.


CLASS zcl_ai_ext_api_tool IMPLEMENTATION.
  METHOD constructor.
    mv_url     = iv_url.
    mv_method  = iv_method.
    mv_body    = iv_body.
    mt_headers = it_headers.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        url         TYPE string,
        method      TYPE string,
        status_code TYPE string,
        response    TYPE string,
      END OF ty_result.
    DATA ls_result   TYPE ty_result.
    DATA lo_client   TYPE REF TO if_http_client.
    DATA lv_response TYPE string.
    DATA lv_code     TYPE i.
    DATA lv_reason   TYPE string.

    cl_http_client=>create_by_url( EXPORTING  url    = mv_url
                                   IMPORTING client  = lo_client
                                   EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    lo_client->propertytype_logon_popup   = lo_client->co_disabled.
    lo_client->propertytype_accept_cookie = lo_client->co_enabled.
    lo_client->request->set_method( mv_method ).

    LOOP AT mt_headers ASSIGNING FIELD-SYMBOL(<fs_header>).
      lo_client->request->set_header_field( name  = <fs_header>-name
                                            value = <fs_header>-value ).
    ENDLOOP.

    IF mv_body IS NOT INITIAL.
      lo_client->request->set_cdata( mv_body ).
    ENDIF.

    lo_client->send( EXPORTING  timeout = 60
                     EXCEPTIONS OTHERS  = 1 ).
    IF sy-subrc <> 0.
      lo_client->get_last_error( IMPORTING code    = lv_code
                                           message = lv_reason ).
      lo_client->close( EXCEPTIONS OTHERS = 1 ).
      zcx_ai_error=>raise( |{ lv_code } - { lv_reason }| ).
    ENDIF.

    lo_client->receive( EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      lo_client->get_last_error( IMPORTING code    = lv_code
                                           message = lv_reason ).
      lo_client->close( EXCEPTIONS OTHERS = 1 ).
      zcx_ai_error=>raise( |{ lv_code } - { lv_reason }| ).
    ENDIF.

    lv_response = lo_client->response->get_cdata( ).
    lo_client->response->get_status( IMPORTING code   = lv_code
                                               reason = lv_reason ).
    lo_client->close( EXCEPTIONS OTHERS = 1 ).

    ls_result = VALUE #( url         = mv_url
                         method      = mv_method
                         status_code = lv_code
                         response    = lv_response ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'call_external_api'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Calls an external HTTP API with the given URL, method, optional body, and headers.'.
  ENDMETHOD.
ENDCLASS.
