CLASS zcl_ai_gemini_embedding DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_embedding.

    METHODS constructor
      IMPORTING io_client  TYPE REF TO zif_ai_http_client
                iv_model   TYPE string DEFAULT 'text-embedding-004'
                iv_api_key TYPE string DEFAULT ''.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_part,
        text TYPE string,
      END OF ty_s_part.
    TYPES ty_t_parts TYPE STANDARD TABLE OF ty_s_part WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_content,
        parts TYPE ty_t_parts,
      END OF ty_s_content.
    TYPES:
      BEGIN OF ty_s_req,
        model   TYPE string,
        content TYPE ty_s_content,
      END OF ty_s_req.
    TYPES:
      BEGIN OF ty_s_res_embedding,
        values TYPE zif_ai_embedding=>ty_t_vector,
      END OF ty_s_res_embedding.
    TYPES:
      BEGIN OF ty_s_res,
        embedding TYPE ty_s_res_embedding,
      END OF ty_s_res.

    DATA mo_client TYPE REF TO zif_ai_http_client.
    DATA mv_model  TYPE string.
    DATA mv_api_key TYPE string.
ENDCLASS.


CLASS zcl_ai_gemini_embedding IMPLEMENTATION.
  METHOD constructor.
    mo_client  = io_client.
    mv_model   = |models/{ iv_model }|.
    mv_api_key = iv_api_key.
  ENDMETHOD.

  METHOD zif_ai_embedding~embed.
    DATA ls_req TYPE ty_s_req.
    DATA lv_req TYPE string.
    DATA lv_res TYPE string.
    DATA lv_endpoint TYPE string.
    DATA ls_res TYPE ty_s_res.

    ls_req = VALUE #( model   = mv_model
                      content = VALUE #( parts = VALUE #( ( text = iv_text ) ) ) ).
    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-low_case ).

    lv_endpoint = |/v1/{ mv_model }:embedContent|.
    IF mv_api_key IS NOT INITIAL.
      lv_endpoint = |{ lv_endpoint }?key={ mv_api_key }|.
    ENDIF.

    lv_res = mo_client->send( iv_endpoint = lv_endpoint
                              iv_body     = lv_req ).

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                    IMPORTING ev_data = ls_res ).

    rt_vector = ls_res-embedding-values.
  ENDMETHOD.
ENDCLASS.
