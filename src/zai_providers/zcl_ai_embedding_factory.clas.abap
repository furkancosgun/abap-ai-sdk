CLASS zcl_ai_embedding_factory DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF mc_provider,
                 ollama TYPE string VALUE 'ollama',
                 openai TYPE string VALUE 'openai',
                 gemini TYPE string VALUE 'gemini',
               END OF mc_provider.

    CLASS-METHODS create
      IMPORTING io_client           TYPE REF TO zif_ai_http_client
                iv_provider_type    TYPE string                    OPTIONAL
                iv_model            TYPE string                    OPTIONAL
                iv_api_key          TYPE string                    OPTIONAL
      RETURNING VALUE(ro_embedding) TYPE REF TO zif_ai_embedding
      RAISING   zcx_ai_error.

    CLASS-METHODS create_ollama
      IMPORTING io_client           TYPE REF TO zif_ai_http_client
                iv_model            TYPE string                    DEFAULT 'nomic-embed-text:latest'
      RETURNING VALUE(ro_embedding) TYPE REF TO zif_ai_embedding
      RAISING   zcx_ai_error.

    CLASS-METHODS create_openai
      IMPORTING io_client           TYPE REF TO zif_ai_http_client
                iv_api_key          TYPE string
                iv_model            TYPE string                    DEFAULT 'text-embedding-3-small'
      RETURNING VALUE(ro_embedding) TYPE REF TO zif_ai_embedding
      RAISING   zcx_ai_error.

    CLASS-METHODS create_gemini
      IMPORTING io_client           TYPE REF TO zif_ai_http_client
                iv_api_key          TYPE string
                iv_model            TYPE string                    DEFAULT 'text-embedding-004'
      RETURNING VALUE(ro_embedding) TYPE REF TO zif_ai_embedding
      RAISING   zcx_ai_error.
ENDCLASS.


CLASS zcl_ai_embedding_factory IMPLEMENTATION.

  METHOD create.
    IF io_client IS NOT BOUND.
      zcx_ai_error=>raise( 'A valid HTTP client instance (io_client) must be provided.' ).
    ENDIF.

    CASE iv_provider_type.
      WHEN mc_provider-ollama.
        ro_embedding = NEW zcl_ai_ollama_embedding(
          io_client = io_client
          iv_model  = COND #( WHEN iv_model IS NOT INITIAL THEN iv_model ELSE 'nomic-embed-text:latest' ) ).

      WHEN mc_provider-openai.
        ro_embedding = NEW zcl_ai_openai_embedding(
          io_client  = io_client
          iv_model   = COND #( WHEN iv_model IS NOT INITIAL THEN iv_model ELSE 'text-embedding-3-small' )
          iv_api_key = iv_api_key ).

      WHEN mc_provider-gemini.
        ro_embedding = NEW zcl_ai_gemini_embedding(
          io_client  = io_client
          iv_model   = COND #( WHEN iv_model IS NOT INITIAL THEN iv_model ELSE 'text-embedding-004' )
          iv_api_key = iv_api_key ).

      WHEN OTHERS.
        zcx_ai_error=>raise( |Unsupported embedding provider type: { iv_provider_type }| ).
    ENDCASE.
  ENDMETHOD.

  METHOD create_ollama.
    ro_embedding = create( io_client        = io_client
                           iv_provider_type = mc_provider-ollama
                           iv_model         = iv_model ).
  ENDMETHOD.

  METHOD create_openai.
    ro_embedding = create( io_client        = io_client
                           iv_provider_type = mc_provider-openai
                           iv_api_key       = iv_api_key
                           iv_model         = iv_model ).
  ENDMETHOD.

  METHOD create_gemini.
    ro_embedding = create( io_client        = io_client
                           iv_provider_type = mc_provider-gemini
                           iv_api_key       = iv_api_key
                           iv_model         = iv_model ).
  ENDMETHOD.
ENDCLASS.