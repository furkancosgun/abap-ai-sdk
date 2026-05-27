INTERFACE zif_ai_middleware
  PUBLIC.

  TYPES ty_t_middlewares TYPE STANDARD TABLE OF REF TO zif_ai_middleware WITH EMPTY KEY.

  METHODS before
    IMPORTING io_context TYPE REF TO zcl_ai_context.

  METHODS after
    IMPORTING io_context TYPE REF TO zcl_ai_context.
ENDINTERFACE.
