CLASS zcl_ai_rag_middleware DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_middleware.

    METHODS constructor
      IMPORTING io_vector_store TYPE REF TO zcl_ai_vector_store.

  PRIVATE SECTION.
    DATA mo_vector_store TYPE REF TO zcl_ai_vector_store.
ENDCLASS.


CLASS zcl_ai_rag_middleware IMPLEMENTATION.
  METHOD constructor.
    mo_vector_store = io_vector_store.
  ENDMETHOD.

  METHOD zif_ai_middleware~before.
    DATA lt_messages TYPE zcl_ai_message=>ty_t_messages.
    DATA lv_query    TYPE string.
    DATA lv_context  TYPE string.
    DATA lo_msg      TYPE REF TO zcl_ai_message.
    DATA lo_last_user TYPE REF TO zcl_ai_message.

    lt_messages = io_context->get_memory( )->get_all( ).

    LOOP AT lt_messages INTO lo_msg.
      IF lo_msg->get_role( ) = 'user'.
        lo_last_user = lo_msg.
        lv_query = lo_msg->get_content( ).
      ENDIF.
    ENDLOOP.

    IF lv_query IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        lv_context = mo_vector_store->search( lv_query ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    IF lv_context IS INITIAL.
      RETURN.
    ENDIF.

    lo_last_user->set_content(
      |Retrieved context:\n{ lv_context }|
      & |\n\n---\nUser query:\n{ lv_query }| ).
  ENDMETHOD.

  METHOD zif_ai_middleware~after.
    ASSERT io_context IS BOUND.
  ENDMETHOD.
ENDCLASS.
