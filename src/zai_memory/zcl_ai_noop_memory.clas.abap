CLASS zcl_ai_noop_memory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_memory_strategy.
ENDCLASS.


CLASS zcl_ai_noop_memory IMPLEMENTATION.
  METHOD zif_ai_memory_strategy~apply.
    rt_messages = it_messages.
  ENDMETHOD.
ENDCLASS.
