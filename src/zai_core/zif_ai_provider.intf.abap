INTERFACE zif_ai_provider
  PUBLIC.
  METHODS generate
    IMPORTING it_messages       TYPE zcl_ai_message=>ty_t_messages
              it_tools          TYPE zif_ai_tool=>ty_t_tool_def OPTIONAL
    RETURNING VALUE(ro_message) TYPE REF TO zcl_ai_message
    RAISING   zcx_ai_error.
ENDINTERFACE.
