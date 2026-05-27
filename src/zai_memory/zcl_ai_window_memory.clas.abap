CLASS zcl_ai_window_memory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_window_size TYPE i DEFAULT 20.

    INTERFACES zif_ai_memory_strategy.

  PRIVATE SECTION.
    DATA mv_window_size TYPE i.
ENDCLASS.


CLASS zcl_ai_window_memory IMPLEMENTATION.
  METHOD constructor.
    mv_window_size = iv_window_size.
  ENDMETHOD.

  METHOD zif_ai_memory_strategy~apply.
    DATA lv_from            TYPE i.
    DATA lt_system_messages TYPE zcl_ai_message=>ty_t_messages.
    DATA lt_other_messages  TYPE zcl_ai_message=>ty_t_messages.

    FIELD-SYMBOLS <fs_message> LIKE LINE OF it_messages.

    LOOP AT it_messages ASSIGNING <fs_message>.
      IF <fs_message> IS INSTANCE OF zcl_ai_system_message.
        APPEND <fs_message> TO lt_system_messages.
      ELSE.
        APPEND <fs_message> TO lt_other_messages.
      ENDIF.
    ENDLOOP.

    lv_from = nmax( val1 = 1
                    val2 = lines( lt_other_messages ) - mv_window_size + 1 ).

    APPEND LINES OF lt_system_messages TO rt_messages.
    APPEND LINES OF lt_other_messages FROM lv_from TO rt_messages.
  ENDMETHOD.
ENDCLASS.
