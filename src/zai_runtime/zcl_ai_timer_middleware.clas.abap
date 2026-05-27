CLASS zcl_ai_timer_middleware DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_middleware.

  PRIVATE SECTION.
    DATA mv_start TYPE tzntstmpl.
ENDCLASS.


CLASS zcl_ai_timer_middleware IMPLEMENTATION.
  METHOD zif_ai_middleware~before.
    GET TIME STAMP FIELD mv_start.
  ENDMETHOD.

  METHOD zif_ai_middleware~after.
    DATA lv_end TYPE tzntstmpl.
    DATA lv_ms  TYPE decfloat34.

    GET TIME STAMP FIELD lv_end.
    lv_ms = ( lv_end - mv_start ) * 1000.
    WRITE / |AI: Request took { lv_ms DECIMALS = 0 } ms.|.
  ENDMETHOD.
ENDCLASS.
