CLASS zcl_ai_agent_factory DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS create_openai
      IMPORTING iv_api_key       TYPE string
                iv_model         TYPE string       DEFAULT 'gpt-4o'
                it_tools         TYPE string_table OPTIONAL
                iv_system_prompt TYPE string       DEFAULT 'You are a helpful AI assistant.'
      RETURNING VALUE(ro_agent)  TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_gemini
      IMPORTING iv_api_key       TYPE string
                iv_model         TYPE string       DEFAULT 'gemini-2.0-flash'
                it_tools         TYPE string_table OPTIONAL
                iv_system_prompt TYPE string       DEFAULT 'You are a helpful AI assistant.'
      RETURNING VALUE(ro_agent)  TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_anthropic
      IMPORTING iv_api_key       TYPE string
                iv_model         TYPE string       DEFAULT 'claude-sonnet-4-20250514'
                it_tools         TYPE string_table OPTIONAL
                iv_system_prompt TYPE string       DEFAULT 'You are a helpful AI assistant.'
      RETURNING VALUE(ro_agent)  TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_ollama
      IMPORTING iv_base_url      TYPE string       DEFAULT 'http://localhost:11434'
                iv_model         TYPE string       DEFAULT 'llama3.2'
                it_tools         TYPE string_table OPTIONAL
                iv_system_prompt TYPE string       DEFAULT 'You are a helpful AI assistant.'
      RETURNING VALUE(ro_agent)  TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_default
      IMPORTING iv_system_prompt TYPE string       DEFAULT 'You are a helpful AI assistant.'
                it_tools         TYPE string_table OPTIONAL
      RETURNING VALUE(ro_agent)  TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

  PRIVATE SECTION.
    CLASS-METHODS build_agent
      IMPORTING io_provider      TYPE REF TO zif_ai_provider
                it_tools         TYPE string_table OPTIONAL
                iv_system_prompt TYPE string
      RETURNING VALUE(ro_agent)  TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.
ENDCLASS.


CLASS zcl_ai_agent_factory IMPLEMENTATION.
  METHOD build_agent.
    DATA lo_registry TYPE REF TO zif_ai_tool_registry.
    DATA lo_memory   TYPE REF TO zif_ai_memory_store.
    DATA lo_pipeline TYPE REF TO zcl_ai_pipeline.

    lo_memory = NEW zcl_ai_memory_store( NEW zcl_ai_noop_memory( ) ).
    lo_memory->add( NEW zcl_ai_system_message( iv_system_prompt ) ).
    lo_registry = NEW zcl_ai_tool_registry( ).
    lo_registry->add_all( it_tools ).
    lo_pipeline = NEW zcl_ai_pipeline( ).

    ro_agent = NEW zcl_ai_agent( io_provider      = io_provider
                                 io_tool_registry = lo_registry
                                 io_memory        = lo_memory
                                 io_pipeline      = lo_pipeline ).
  ENDMETHOD.

  METHOD create_openai.
    DATA lo_http     TYPE REF TO zif_ai_http_client.
    DATA lo_format   TYPE REF TO zif_ai_tool_formatter.
    DATA lo_provider TYPE REF TO zif_ai_provider.

    lo_http = NEW zcl_ai_onprem_http_client( iv_base_url = 'https://api.openai.com' ).
    lo_format = NEW zcl_ai_openai_formatter( ).
    lo_provider = NEW zcl_ai_openai_provider( io_client  = lo_http
                                              io_format  = lo_format
                                              iv_model   = iv_model
                                              iv_api_key = iv_api_key ).

    ro_agent = build_agent( io_provider      = lo_provider
                            it_tools         = it_tools
                            iv_system_prompt = iv_system_prompt ).
  ENDMETHOD.

  METHOD create_gemini.
    DATA lo_http     TYPE REF TO zif_ai_http_client.
    DATA lo_format   TYPE REF TO zif_ai_tool_formatter.
    DATA lo_provider TYPE REF TO zif_ai_provider.

    lo_http = NEW zcl_ai_onprem_http_client( iv_base_url = 'https://generativelanguage.googleapis.com' ).
    lo_format = NEW zcl_ai_gemini_formatter( ).
    lo_provider = NEW zcl_ai_gemini_provider( io_client  = lo_http
                                              io_format  = lo_format
                                              iv_model   = iv_model
                                              iv_api_key = iv_api_key ).

    ro_agent = build_agent( io_provider      = lo_provider
                            it_tools         = it_tools
                            iv_system_prompt = iv_system_prompt ).
  ENDMETHOD.

  METHOD create_anthropic.
    DATA lo_http     TYPE REF TO zif_ai_http_client.
    DATA lo_format   TYPE REF TO zif_ai_tool_formatter.
    DATA lo_provider TYPE REF TO zif_ai_provider.

    lo_http = NEW zcl_ai_onprem_http_client( iv_base_url = 'https://api.anthropic.com' ).
    lo_format = NEW zcl_ai_anthropic_formatter( ).
    lo_provider = NEW zcl_ai_anthropic_provider( io_client  = lo_http
                                                 io_format  = lo_format
                                                 iv_model   = iv_model
                                                 iv_api_key = iv_api_key ).

    ro_agent = build_agent( io_provider      = lo_provider
                            it_tools         = it_tools
                            iv_system_prompt = iv_system_prompt ).
  ENDMETHOD.

  METHOD create_ollama.
    DATA lo_http     TYPE REF TO zif_ai_http_client.
    DATA lo_format   TYPE REF TO zif_ai_tool_formatter.
    DATA lo_provider TYPE REF TO zif_ai_provider.

    lo_http = NEW zcl_ai_onprem_http_client( iv_base_url = iv_base_url ).
    lo_format = NEW zcl_ai_openai_formatter( ).

    lo_provider = NEW zcl_ai_ollama_provider( io_client = lo_http
                                              io_format = lo_format
                                              iv_model  = iv_model ).

    ro_agent = build_agent( io_provider      = lo_provider
                            it_tools         = it_tools
                            iv_system_prompt = iv_system_prompt ).
  ENDMETHOD.

  METHOD create_default.
    ro_agent = create_ollama( iv_model         = 'gemma4:latest'
                              iv_system_prompt = iv_system_prompt
                              it_tools         = it_tools ).
  ENDMETHOD.
ENDCLASS.
