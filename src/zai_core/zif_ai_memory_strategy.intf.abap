INTERFACE zif_ai_memory_strategy
  PUBLIC.

  METHODS apply
    IMPORTING it_messages        TYPE zcl_ai_message=>ty_t_messages
    RETURNING VALUE(rt_messages) TYPE zcl_ai_message=>ty_t_messages.
ENDINTERFACE.
