CLASS zcl_ai_locked_objects_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_username TYPE sy-uname OPTIONAL.

  PRIVATE SECTION.
    DATA mv_username TYPE sy-uname.
ENDCLASS.


CLASS zcl_ai_locked_objects_tool IMPLEMENTATION.
  METHOD constructor.
    mv_username = iv_username.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_s_lock,
        lock_table  TYPE string,
        lock_value  TYPE string,
        lock_object TYPE string,
        locked_by   TYPE string,
        locked_at   TYPE string,
      END OF ty_s_lock.
    TYPES ty_t_locks TYPE STANDARD TABLE OF ty_s_lock WITH EMPTY KEY.
    DATA lt_locks TYPE ty_t_locks.
    DATA lt_enq   TYPE STANDARD TABLE OF seqg3 WITH EMPTY KEY.

    CALL FUNCTION 'ENQUEUE_READ'
      EXPORTING  guname = mv_username
      TABLES enq        = lt_enq
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    LOOP AT lt_enq ASSIGNING FIELD-SYMBOL(<fs_enq>).
      APPEND VALUE #( lock_table  = <fs_enq>-gname
                      lock_value  = <fs_enq>-garg
                      lock_object = <fs_enq>-gobj
                      locked_by   = <fs_enq>-guname
                      locked_at   = |{ <fs_enq>-gtdate DATE = ISO } { <fs_enq>-gttime TIME = ISO }| )
             TO lt_locks.
    ENDLOOP.

    rv_result = zcl_ai_serializer=>serialize( lt_locks ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'get_locked_objects'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Returns locked objects in the system, optionally filtered by a specific username.'.
  ENDMETHOD.
ENDCLASS.
