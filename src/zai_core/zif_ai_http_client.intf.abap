INTERFACE zif_ai_http_client
  PUBLIC.
  TYPES:
    BEGIN OF ty_s_header,
      name  TYPE string,
      value TYPE string,
    END OF ty_s_header.
  TYPES ty_t_header TYPE STANDARD TABLE OF ty_s_header WITH EMPTY KEY.

  CONSTANTS:
    BEGIN OF mc_methods,
      get    TYPE string VALUE 'GET',
      post   TYPE string VALUE 'POST',
      put    TYPE string VALUE 'PUT',
      delete TYPE string VALUE 'DELETE',
    END OF mc_methods.

  METHODS send
    IMPORTING iv_endpoint        TYPE string
              iv_method          TYPE string      DEFAULT zif_ai_http_client=>mc_methods-post
              iv_body            TYPE string      OPTIONAL
              it_headers         TYPE ty_t_header OPTIONAL
    RETURNING VALUE(rv_response) TYPE string
    RAISING   zcx_ai_error.
ENDINTERFACE.
