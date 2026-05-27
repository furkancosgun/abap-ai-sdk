CLASS zcl_ai_summarize_memory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_provider                    TYPE REF TO zif_ai_provider
                iv_max_messages_before_summary TYPE i
                iv_summary_prompt              TYPE string
                DEFAULT 'Summarize the following conversation concisely, keeping all important details:'.

    INTERFACES zif_ai_memory_strategy.

  PRIVATE SECTION.
    DATA mo_provider                    TYPE REF TO zif_ai_provider.
    DATA mv_max_messages_before_summary TYPE i.
    DATA mv_summary_prompt              TYPE string.

    METHODS summarize
      IMPORTING iv_text           TYPE string
      RETURNING VALUE(rv_summary) TYPE string
      RAISING   zcx_ai_error.
ENDCLASS.


CLASS zcl_ai_summarize_memory IMPLEMENTATION.
  METHOD constructor.
    mo_provider = io_provider.
    mv_max_messages_before_summary = iv_max_messages_before_summary.
    mv_summary_prompt = iv_summary_prompt.
  ENDMETHOD.

  METHOD summarize.
    DATA lt_prompt_messages TYPE zcl_ai_message=>ty_t_messages.

    APPEND NEW zcl_ai_system_message( iv_content = mv_summary_prompt ) TO lt_prompt_messages.
    APPEND NEW zcl_ai_user_message( iv_content = iv_text ) TO lt_prompt_messages.

    DATA(lo_result) = mo_provider->generate( lt_prompt_messages ).

    rv_summary = lo_result->get_content( ).
  ENDMETHOD.

  METHOD zif_ai_memory_strategy~apply.
    DATA lt_system_messages TYPE zcl_ai_message=>ty_t_messages.
    DATA lt_other_messages  TYPE zcl_ai_message=>ty_t_messages.
    DATA lt_to_summarize    TYPE zcl_ai_message=>ty_t_messages.
    DATA lt_keep            TYPE zcl_ai_message=>ty_t_messages.
    DATA lv_conversation    TYPE string.
    DATA lv_other_count     TYPE i.
    DATA lv_summarize_to    TYPE i.
    DATA lv_keep_from       TYPE i.
    DATA lv_summary_text    TYPE string.
    DATA lo_summary_msg     TYPE REF TO zcl_ai_message.
    FIELD-SYMBOLS <fs_message> LIKE LINE OF it_messages.

    LOOP AT it_messages ASSIGNING <fs_message>.
      IF <fs_message> IS INSTANCE OF zcl_ai_system_message.
        APPEND <fs_message> TO lt_system_messages.
      ELSE.
        APPEND <fs_message> TO lt_other_messages.
      ENDIF.
    ENDLOOP.

    lv_other_count = lines( lt_other_messages ).
    IF lv_other_count <= mv_max_messages_before_summary.
      rt_messages = it_messages.
      RETURN.
    ENDIF.

    lv_summarize_to = lv_other_count - mv_max_messages_before_summary.
    APPEND LINES OF lt_other_messages FROM 1 TO lv_summarize_to TO lt_to_summarize.

    lv_keep_from = lv_summarize_to + 1.
    APPEND LINES OF lt_other_messages FROM lv_keep_from TO lv_other_count TO lt_keep.

    LOOP AT lt_to_summarize ASSIGNING <fs_message>.
      IF <fs_message>->get_content( ) IS NOT INITIAL.
        IF lv_conversation IS INITIAL.
          lv_conversation = |{ <fs_message>->get_role( ) }: { <fs_message>->get_content( ) }|.
        ELSE.
          lv_conversation = |{ lv_conversation }\n{ <fs_message>->get_role( ) }: { <fs_message>->get_content( ) }|.
        ENDIF.
      ENDIF.
    ENDLOOP.

    TRY.
        lv_summary_text = summarize( lv_conversation ).
      CATCH zcx_ai_error.
        CLEAR lv_summary_text.
    ENDTRY.

    lo_summary_msg = NEW zcl_ai_system_message( iv_content = |[Conversation summary]\n{ lv_summary_text }| ).

    APPEND LINES OF lt_system_messages TO rt_messages.
    APPEND lo_summary_msg TO rt_messages.
    APPEND LINES OF lt_keep TO rt_messages.
  ENDMETHOD.
ENDCLASS.
