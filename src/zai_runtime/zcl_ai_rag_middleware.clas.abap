CLASS zcl_ai_rag_middleware DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_middleware.

    METHODS constructor
      IMPORTING io_vector_store TYPE REF TO zcl_ai_vector_store
                iv_threshold    TYPE f DEFAULT 0.

  PRIVATE SECTION.
    DATA mo_vector_store TYPE REF TO zcl_ai_vector_store.
    DATA mv_threshold    TYPE f.
ENDCLASS.


CLASS zcl_ai_rag_middleware IMPLEMENTATION.
  METHOD constructor.
    mo_vector_store = io_vector_store.
    mv_threshold    = iv_threshold.
  ENDMETHOD.

  METHOD zif_ai_middleware~before.
    DATA lt_messages TYPE zcl_ai_message=>ty_t_messages.
    DATA lv_query    TYPE string.
    DATA lv_context  TYPE string.
    FIELD-SYMBOLS <fs_message> TYPE REF TO zcl_ai_message.

    lt_messages = io_context->get_memory( )->get_all( ).

    ASSIGN lt_messages[ lines( lt_messages ) ] TO <fs_message>.
    IF sy-subrc <> 0 OR <fs_message>->get_role( ) <> 'user'.
      RETURN.
    ENDIF.

    lv_query = <fs_message>->get_content( ).

    IF lv_query IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        lv_context = mo_vector_store->search(
          iv_query     = lv_query
          iv_threshold = mv_threshold ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    IF lv_context IS INITIAL.
      RETURN.
    ENDIF.

    <fs_message>->set_content( |Retrieved context:\n{ lv_context }\n\n---\n|
                             & |User query:\n{ lv_query }| ).
  ENDMETHOD.

  METHOD zif_ai_middleware~after.
    ASSERT io_context IS BOUND.
  ENDMETHOD.
ENDCLASS.
