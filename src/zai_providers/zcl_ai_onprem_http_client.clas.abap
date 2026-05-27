CLASS zcl_ai_onprem_http_client DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_base_url TYPE string
                iv_ssl_id   TYPE string OPTIONAL
                iv_timeout  TYPE i      DEFAULT 120.

    INTERFACES zif_ai_http_client.

  PRIVATE SECTION.
    DATA mv_base_url TYPE string.
    DATA mv_ssl_id   TYPE ssfapplssl.
    DATA mv_timeout  TYPE i.
ENDCLASS.


CLASS zcl_ai_onprem_http_client IMPLEMENTATION.
  METHOD zif_ai_http_client~send.
    DATA lo_client        TYPE REF TO if_http_client.
    DATA lv_response_text TYPE string.
    DATA lv_response_code TYPE i.

    cl_http_client=>create_by_url( EXPORTING  url    = mv_base_url
                                              ssl_id = mv_ssl_id
                                   IMPORTING client  = lo_client
                                   EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    cl_http_utility=>set_request_uri( request = lo_client->request
                                      uri     = iv_endpoint ).

    lo_client->propertytype_logon_popup   = lo_client->co_disabled.
    lo_client->propertytype_accept_cookie = lo_client->co_enabled.
    lo_client->request->set_method( iv_method ).

    lo_client->request->set_header_field( name  = 'Content-Type'
                                          value = 'application/json' ).
    LOOP AT it_headers ASSIGNING FIELD-SYMBOL(<fs_header>).
      lo_client->request->set_header_field( name  = <fs_header>-name
                                            value = <fs_header>-value ).
    ENDLOOP.

    IF iv_body IS NOT INITIAL.
      lo_client->request->set_cdata( iv_body ).
    ENDIF.

    lo_client->send( EXPORTING  timeout = mv_timeout
                     EXCEPTIONS OTHERS  = 1 ).
    IF sy-subrc <> 0.
      lo_client->get_last_error( IMPORTING code    = lv_response_code
                                           message = lv_response_text ).
      lo_client->close( EXCEPTIONS OTHERS = 1 ).
      zcx_ai_error=>raise( lv_response_text ).
    ENDIF.

    lo_client->receive( EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      lo_client->get_last_error( IMPORTING code    = lv_response_code
                                           message = lv_response_text ).
      lo_client->close( EXCEPTIONS OTHERS = 1 ).
      zcx_ai_error=>raise( lv_response_text ).
    ENDIF.

    rv_response = lo_client->response->get_cdata( ).

    lo_client->response->get_status( IMPORTING code   = lv_response_code
                                               reason = lv_response_text ).

    lo_client->close( EXCEPTIONS OTHERS = 1 ).
    IF lv_response_code NOT BETWEEN 200 AND 299.
      zcx_ai_error=>raise( COND #( WHEN rv_response IS NOT INITIAL THEN rv_response ELSE lv_response_text ) ).
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    mv_base_url = iv_base_url.
    mv_ssl_id = iv_ssl_id.
    IF mv_base_url CP '*/'.
      mv_base_url = substring( val = mv_base_url
                               len = strlen( mv_base_url ) - 1 ).
    ENDIF.
    mv_timeout = iv_timeout.
  ENDMETHOD.
ENDCLASS.
