CLASS zcl_ai_pipeline DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING it_middlewares TYPE zif_ai_middleware=>ty_t_middlewares OPTIONAL.

    METHODS add
      IMPORTING io_middleware TYPE REF TO zif_ai_middleware.

    METHODS run
      IMPORTING io_context        TYPE REF TO zcl_ai_context
                io_provider       TYPE REF TO zif_ai_provider
      RETURNING VALUE(ro_message) TYPE REF TO zcl_ai_message
      RAISING   zcx_ai_error.

  PRIVATE SECTION.
    DATA mt_middlewares TYPE zif_ai_middleware=>ty_t_middlewares.
ENDCLASS.


CLASS zcl_ai_pipeline IMPLEMENTATION.
  METHOD constructor.
    mt_middlewares = it_middlewares.
  ENDMETHOD.

  METHOD add.
    APPEND io_middleware TO mt_middlewares.
  ENDMETHOD.

  METHOD run.
    FIELD-SYMBOLS <fs_middleware> LIKE LINE OF mt_middlewares.

    LOOP AT mt_middlewares ASSIGNING <fs_middleware>.
      <fs_middleware>->before( io_context ).
    ENDLOOP.

    ro_message = io_provider->generate( it_messages = io_context->get_memory( )->get_all( )
                                        it_tools    = io_context->get_tool_registry( )->get_all_definitions( ) ).

    LOOP AT mt_middlewares ASSIGNING <fs_middleware>.
      <fs_middleware>->after( io_context ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
