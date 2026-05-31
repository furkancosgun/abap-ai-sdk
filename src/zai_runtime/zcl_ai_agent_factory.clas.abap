CLASS zcl_ai_agent_factory DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS create
      IMPORTING io_provider        TYPE REF TO zif_ai_provider
                io_pipeline        TYPE REF TO zcl_ai_pipeline              OPTIONAL
                io_tool_registry   TYPE REF TO zif_ai_tool_registry         OPTIONAL
                it_tools           TYPE string_table                        OPTIONAL
                io_memory          TYPE REF TO zif_ai_memory_store          OPTIONAL
                io_memory_strategy TYPE REF TO zif_ai_memory_strategy       OPTIONAL
                iv_system_prompt   TYPE string                              OPTIONAL
                it_middlewares     TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL
                iv_max_tool_round  TYPE i                                   DEFAULT 10
      RETURNING VALUE(ro_agent)    TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_openai
      IMPORTING iv_api_key         TYPE string
                iv_model           TYPE string                              DEFAULT 'gpt-4o'
                it_tools           TYPE string_table                        OPTIONAL
                iv_system_prompt   TYPE string                              DEFAULT 'You are a helpful AI assistant.'
                io_pipeline        TYPE REF TO zcl_ai_pipeline              OPTIONAL
                io_tool_registry   TYPE REF TO zif_ai_tool_registry         OPTIONAL
                io_memory          TYPE REF TO zif_ai_memory_store          OPTIONAL
                io_memory_strategy TYPE REF TO zif_ai_memory_strategy       OPTIONAL
                it_middlewares     TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL
                iv_max_tool_round  TYPE i                                   DEFAULT 10
      RETURNING VALUE(ro_agent)    TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_gemini
      IMPORTING iv_api_key         TYPE string
                iv_model           TYPE string                              DEFAULT 'gemini-2.0-flash'
                it_tools           TYPE string_table                        OPTIONAL
                iv_system_prompt   TYPE string                              DEFAULT 'You are a helpful AI assistant.'
                io_pipeline        TYPE REF TO zcl_ai_pipeline              OPTIONAL
                io_tool_registry   TYPE REF TO zif_ai_tool_registry         OPTIONAL
                io_memory          TYPE REF TO zif_ai_memory_store          OPTIONAL
                io_memory_strategy TYPE REF TO zif_ai_memory_strategy       OPTIONAL
                it_middlewares     TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL
                iv_max_tool_round  TYPE i                                   DEFAULT 10
      RETURNING VALUE(ro_agent)    TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_anthropic
      IMPORTING iv_api_key         TYPE string
                iv_model           TYPE string                              DEFAULT 'claude-sonnet-4-20250514'
                it_tools           TYPE string_table                        OPTIONAL
                iv_system_prompt   TYPE string                              DEFAULT 'You are a helpful AI assistant.'
                io_pipeline        TYPE REF TO zcl_ai_pipeline              OPTIONAL
                io_tool_registry   TYPE REF TO zif_ai_tool_registry         OPTIONAL
                io_memory          TYPE REF TO zif_ai_memory_store          OPTIONAL
                io_memory_strategy TYPE REF TO zif_ai_memory_strategy       OPTIONAL
                it_middlewares     TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL
                iv_max_tool_round  TYPE i                                   DEFAULT 10
      RETURNING VALUE(ro_agent)    TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_ollama
      IMPORTING iv_base_url        TYPE string                              DEFAULT 'http://localhost:11434'
                iv_model           TYPE string                              DEFAULT 'llama3.2'
                it_tools           TYPE string_table                        OPTIONAL
                iv_system_prompt   TYPE string                              DEFAULT 'You are a helpful AI assistant.'
                io_pipeline        TYPE REF TO zcl_ai_pipeline              OPTIONAL
                io_tool_registry   TYPE REF TO zif_ai_tool_registry         OPTIONAL
                io_memory          TYPE REF TO zif_ai_memory_store          OPTIONAL
                io_memory_strategy TYPE REF TO zif_ai_memory_strategy       OPTIONAL
                it_middlewares     TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL
                iv_max_tool_round  TYPE i                                   DEFAULT 10
      RETURNING VALUE(ro_agent)    TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.

    CLASS-METHODS create_default
      IMPORTING iv_system_prompt   TYPE string                              DEFAULT 'You are a helpful AI assistant.'
                it_tools           TYPE string_table                        OPTIONAL
                io_pipeline        TYPE REF TO zcl_ai_pipeline              OPTIONAL
                io_tool_registry   TYPE REF TO zif_ai_tool_registry         OPTIONAL
                io_memory          TYPE REF TO zif_ai_memory_store          OPTIONAL
                io_memory_strategy TYPE REF TO zif_ai_memory_strategy       OPTIONAL
                it_middlewares     TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL
                iv_max_tool_round  TYPE i                                   DEFAULT 10
      RETURNING VALUE(ro_agent)    TYPE REF TO zif_ai_agent
      RAISING   zcx_ai_error.
ENDCLASS.


CLASS zcl_ai_agent_factory IMPLEMENTATION.
  METHOD create.
    DATA lo_registry    TYPE REF TO zif_ai_tool_registry.
    DATA lo_memory      TYPE REF TO zif_ai_memory_store.
    DATA lo_strategy    TYPE REF TO zif_ai_memory_strategy.
    DATA lo_pipeline    TYPE REF TO zcl_ai_pipeline.
    DATA lt_middlewares TYPE zif_ai_middleware=>ty_t_middlewares.
    FIELD-SYMBOLS <fs_middleware> LIKE LINE OF it_middlewares.

    IF io_provider IS NOT BOUND.
      zcx_ai_error=>raise( 'Provider is required to create an agent' ).
    ENDIF.

    IF io_memory IS BOUND.
      lo_memory = io_memory.
    ELSE.
      IF io_memory_strategy IS BOUND.
        lo_strategy = io_memory_strategy.
      ELSE.
        lo_strategy = NEW zcl_ai_noop_memory( ).
      ENDIF.
      lo_memory = NEW zcl_ai_memory_store( lo_strategy ).
    ENDIF.

    IF lo_memory->size( ) = 0 AND iv_system_prompt IS NOT INITIAL.
      lo_memory->add( NEW zcl_ai_system_message( iv_system_prompt ) ).
    ENDIF.

    IF io_tool_registry IS BOUND.
      lo_registry = io_tool_registry.
    ELSE.
      lo_registry = NEW zcl_ai_tool_registry( ).
      IF it_tools IS NOT INITIAL.
        lo_registry->add_all( it_tools ).
      ENDIF.
    ENDIF.

    IF io_pipeline IS BOUND.
      lo_pipeline = io_pipeline.
    ELSE.
      LOOP AT it_middlewares ASSIGNING <fs_middleware>.
        APPEND <fs_middleware> TO lt_middlewares.
      ENDLOOP.
      lo_pipeline = NEW zcl_ai_pipeline( lt_middlewares ).
    ENDIF.

    ro_agent = NEW zcl_ai_agent( io_provider       = io_provider
                                 io_tool_registry  = lo_registry
                                 io_memory         = lo_memory
                                 io_pipeline       = lo_pipeline
                                 iv_max_tool_round = iv_max_tool_round ).
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

    ro_agent = create( io_provider        = lo_provider
                       it_tools           = it_tools
                       iv_system_prompt   = iv_system_prompt
                       io_pipeline        = io_pipeline
                       io_tool_registry   = io_tool_registry
                       io_memory          = io_memory
                       io_memory_strategy = io_memory_strategy
                       it_middlewares     = it_middlewares
                       iv_max_tool_round  = iv_max_tool_round ).
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

    ro_agent = create( io_provider        = lo_provider
                       it_tools           = it_tools
                       iv_system_prompt   = iv_system_prompt
                       io_pipeline        = io_pipeline
                       io_tool_registry   = io_tool_registry
                       io_memory          = io_memory
                       io_memory_strategy = io_memory_strategy
                       it_middlewares     = it_middlewares
                       iv_max_tool_round  = iv_max_tool_round ).
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

    ro_agent = create( io_provider        = lo_provider
                       it_tools           = it_tools
                       iv_system_prompt   = iv_system_prompt
                       io_pipeline        = io_pipeline
                       io_tool_registry   = io_tool_registry
                       io_memory          = io_memory
                       io_memory_strategy = io_memory_strategy
                       it_middlewares     = it_middlewares
                       iv_max_tool_round  = iv_max_tool_round ).
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

    ro_agent = create( io_provider        = lo_provider
                       it_tools           = it_tools
                       iv_system_prompt   = iv_system_prompt
                       io_pipeline        = io_pipeline
                       io_tool_registry   = io_tool_registry
                       io_memory          = io_memory
                       io_memory_strategy = io_memory_strategy
                       it_middlewares     = it_middlewares
                       iv_max_tool_round  = iv_max_tool_round ).
  ENDMETHOD.

  METHOD create_default.
    ro_agent = create_ollama( iv_model           = 'gemma4:latest'
                              iv_system_prompt   = iv_system_prompt
                              it_tools           = it_tools
                              io_pipeline        = io_pipeline
                              io_tool_registry   = io_tool_registry
                              io_memory          = io_memory
                              io_memory_strategy = io_memory_strategy
                              it_middlewares     = it_middlewares
                              iv_max_tool_round  = iv_max_tool_round ).
  ENDMETHOD.
ENDCLASS.
