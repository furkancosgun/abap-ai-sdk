CLASS zcl_ai_logging_middleware DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_middleware.
ENDCLASS.


CLASS zcl_ai_logging_middleware IMPLEMENTATION.
  METHOD zif_ai_middleware~before.
    DATA lv_count TYPE i.
    DATA lv_tools TYPE i.

    lv_count = io_context->get_memory( )->size( ).
    lv_tools = io_context->get_tool_registry( )->size( ).
    WRITE / |AI: Processing { lv_count } messages with { lv_tools } tools.|.
  ENDMETHOD.

  METHOD zif_ai_middleware~after.
    DATA lv_count TYPE i.

    lv_count = io_context->get_memory( )->size( ).
    WRITE / |AI: Response received. Memory size: { lv_count }.|.
  ENDMETHOD.
ENDCLASS.
