CLASS zcl_ai_context DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_memory   TYPE REF TO zif_ai_memory_store
                io_tool_reg TYPE REF TO zif_ai_tool_registry.

    METHODS get_memory
      RETURNING VALUE(ro_memory) TYPE REF TO zif_ai_memory_store.

    METHODS get_tool_registry
      RETURNING VALUE(ro_tool_reg) TYPE REF TO zif_ai_tool_registry.

  PRIVATE SECTION.
    DATA mo_memory   TYPE REF TO zif_ai_memory_store.
    DATA mo_tool_reg TYPE REF TO zif_ai_tool_registry.
ENDCLASS.


CLASS zcl_ai_context IMPLEMENTATION.
  METHOD constructor.
    mo_memory   = io_memory.
    mo_tool_reg = io_tool_reg.
  ENDMETHOD.

  METHOD get_memory.
    ro_memory = mo_memory.
  ENDMETHOD.

  METHOD get_tool_registry.
    ro_tool_reg = mo_tool_reg.
  ENDMETHOD.
ENDCLASS.
