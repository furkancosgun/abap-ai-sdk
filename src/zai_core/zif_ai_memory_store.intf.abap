INTERFACE zif_ai_memory_store
  PUBLIC.

  METHODS add
    IMPORTING io_message TYPE REF TO zcl_ai_message.

  METHODS get_all
    RETURNING VALUE(rt_messages) TYPE zcl_ai_message=>ty_t_messages.

  METHODS clear.

  METHODS size
    RETURNING VALUE(rv_size) TYPE i.
ENDINTERFACE.
