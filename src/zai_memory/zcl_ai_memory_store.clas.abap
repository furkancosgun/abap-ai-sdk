CLASS zcl_ai_memory_store DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_memory_store.

    METHODS constructor
      IMPORTING io_strategy TYPE REF TO zif_ai_memory_strategy OPTIONAL.

  PRIVATE SECTION.
    DATA mt_messages TYPE zcl_ai_message=>ty_t_messages.
    DATA mo_strategy TYPE REF TO zif_ai_memory_strategy.
ENDCLASS.


CLASS zcl_ai_memory_store IMPLEMENTATION.
  METHOD constructor.
    mo_strategy = COND #( WHEN io_strategy IS BOUND
                          THEN io_strategy
                          ELSE NEW zcl_ai_noop_memory( ) ).
  ENDMETHOD.

  METHOD zif_ai_memory_store~add.
    APPEND io_message TO mt_messages.
    mt_messages = mo_strategy->apply( mt_messages ).
  ENDMETHOD.

  METHOD zif_ai_memory_store~get_all.
    rt_messages = mt_messages.
  ENDMETHOD.

  METHOD zif_ai_memory_store~clear.
    CLEAR mt_messages.
  ENDMETHOD.

  METHOD zif_ai_memory_store~size.
    rv_size = lines( mt_messages ).
  ENDMETHOD.
ENDCLASS.
