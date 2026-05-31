INTERFACE zif_ai_embedding
  PUBLIC.

  TYPES ty_t_vector TYPE STANDARD TABLE OF f WITH EMPTY KEY.

  METHODS embed
    IMPORTING iv_text          TYPE string
    RETURNING VALUE(rt_vector) TYPE ty_t_vector
    RAISING   zcx_ai_error.
ENDINTERFACE.
