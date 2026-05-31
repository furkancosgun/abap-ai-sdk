CLASS zcl_ai_ollama_embedding DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_embedding.

    METHODS constructor
      IMPORTING io_client TYPE REF TO zif_ai_http_client
                iv_model  TYPE string DEFAULT 'nomic-embed-text:latest'.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_req,
        model  TYPE string,
        prompt TYPE string,
      END OF ty_s_req.
    TYPES:
      BEGIN OF ty_s_res,
        embedding TYPE zif_ai_embedding=>ty_t_vector,
      END OF ty_s_res.

    DATA mo_client TYPE REF TO zif_ai_http_client.
    DATA mv_model  TYPE string.
ENDCLASS.


CLASS zcl_ai_ollama_embedding IMPLEMENTATION.
  METHOD constructor.
    mo_client = io_client.
    mv_model  = iv_model.
  ENDMETHOD.

  METHOD zif_ai_embedding~embed.
    DATA ls_req TYPE ty_s_req.
    DATA lv_req TYPE string.
    DATA lv_res TYPE string.
    DATA ls_res TYPE ty_s_res.

    ls_req = VALUE #( model  = mv_model
                      prompt = iv_text ).
    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-low_case ).

    lv_res = mo_client->send( iv_endpoint = '/api/embeddings'
                              iv_body     = lv_req ).

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                    IMPORTING ev_data = ls_res ).

    rt_vector = ls_res-embedding.
  ENDMETHOD.
ENDCLASS.
