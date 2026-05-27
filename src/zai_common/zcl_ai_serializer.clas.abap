CLASS zcl_ai_serializer DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF mc_pretty_mode,
        none          TYPE c LENGTH 1 VALUE '',
        low_case      TYPE c LENGTH 1 VALUE `L`,
        camel_case    TYPE c LENGTH 1 VALUE `X`,
        extended      TYPE c LENGTH 1 VALUE `Y`,
        user          TYPE c LENGTH 1 VALUE `U`,
        user_low_case TYPE c LENGTH 1 VALUE `C`,
      END OF  mc_pretty_mode.

    CLASS-METHODS serialize
      IMPORTING iv_data        TYPE any
                iv_mode        TYPE c DEFAULT mc_pretty_mode-none
      RETURNING VALUE(rv_json) TYPE string.

    CLASS-METHODS deserialize
      IMPORTING iv_json TYPE any
                iv_mode TYPE c DEFAULT mc_pretty_mode-none
      EXPORTING ev_data TYPE any.

    CLASS-METHODS cast
      IMPORTING iv_data TYPE any
                iv_mode TYPE c DEFAULT mc_pretty_mode-none
      EXPORTING ev_data TYPE any.
ENDCLASS.


CLASS zcl_ai_serializer IMPLEMENTATION.
  METHOD cast.
    deserialize( EXPORTING iv_json = serialize( iv_data = iv_data
                                                iv_mode = iv_mode )
                 IMPORTING ev_data = ev_data ).
  ENDMETHOD.

  METHOD deserialize.
    /ui2/cl_json=>deserialize( EXPORTING json        = iv_json
                                         pretty_name = iv_mode
                               CHANGING  data        = ev_data ).
  ENDMETHOD.

  METHOD serialize.
    rv_json = /ui2/cl_json=>serialize( data        = iv_data
                                       compress    = abap_true
                                       pretty_name = iv_mode ).
  ENDMETHOD.
ENDCLASS.
