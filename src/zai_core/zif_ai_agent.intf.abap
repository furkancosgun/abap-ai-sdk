INTERFACE zif_ai_agent
  PUBLIC.

  METHODS execute
    IMPORTING iv_task           TYPE string
    RETURNING VALUE(ro_message) TYPE REF TO zcl_ai_message
    RAISING   zcx_ai_error.
ENDINTERFACE.
