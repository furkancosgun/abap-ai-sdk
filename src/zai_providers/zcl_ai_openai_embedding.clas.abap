CLASS zcl_ai_openai_embedding DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_ai_embedding.

    METHODS constructor
      IMPORTING io_client  TYPE REF TO zif_ai_http_client
                iv_model   TYPE string DEFAULT 'text-embedding-3-small'
                iv_api_key TYPE string DEFAULT ''.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_req,
        input TYPE string,
        model TYPE string,
      END OF ty_s_req.
    TYPES:
      BEGIN OF ty_s_res_data,
        embedding TYPE zif_ai_embedding=>ty_t_vector,
      END OF ty_s_res_data.
    TYPES ty_t_res_data TYPE STANDARD TABLE OF ty_s_res_data WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_res,
        data TYPE ty_t_res_data,
      END OF ty_s_res.

    DATA mo_client TYPE REF TO zif_ai_http_client.
    DATA mv_model  TYPE string.
    DATA mv_api_key TYPE string.
ENDCLASS.


CLASS zcl_ai_openai_embedding IMPLEMENTATION.
  METHOD constructor.
    mo_client  = io_client.
    mv_model   = iv_model.
    mv_api_key = iv_api_key.
  ENDMETHOD.

  METHOD zif_ai_embedding~embed.
    DATA ls_req TYPE ty_s_req.
    DATA lv_req TYPE string.
    DATA lv_res TYPE string.
    DATA ls_res TYPE ty_s_res.

    ls_req = VALUE #( input = iv_text
                      model = mv_model ).
    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-low_case ).

    lv_res = mo_client->send( iv_endpoint = '/v1/embeddings'
                              iv_body     = lv_req
                              it_headers  = COND #( WHEN mv_api_key IS NOT INITIAL
                                                    THEN VALUE #( ( name  = 'Authorization'
                                                                    value = |Bearer { mv_api_key }| ) ) ) ).

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                    IMPORTING ev_data = ls_res ).

    IF ls_res-data IS NOT INITIAL.
      rt_vector = ls_res-data[ 1 ]-embedding.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
