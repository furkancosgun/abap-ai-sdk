CLASS zcl_ai_agent DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_provider       TYPE REF TO zif_ai_provider
                iv_max_tool_round TYPE i DEFAULT 10
                io_tool_registry  TYPE REF TO zif_ai_tool_registry
                io_memory         TYPE REF TO zif_ai_memory_store
                io_pipeline       TYPE REF TO zcl_ai_pipeline.

    INTERFACES zif_ai_agent.

  PRIVATE SECTION.
    DATA mo_memory         TYPE REF TO zif_ai_memory_store.
    DATA mo_registry       TYPE REF TO zif_ai_tool_registry.
    DATA mo_provider       TYPE REF TO zif_ai_provider.
    DATA mv_max_tool_round TYPE i.
    DATA mo_pipeline       TYPE REF TO zcl_ai_pipeline.

    METHODS execute_tool_calls
      IMPORTING it_tool_call TYPE zcl_ai_assistant_message=>ty_t_tool_call
      RAISING   zcx_ai_error.
ENDCLASS.


CLASS zcl_ai_agent IMPLEMENTATION.
  METHOD constructor.
    mo_provider = io_provider.
    mv_max_tool_round = iv_max_tool_round.
    mo_memory = io_memory.
    mo_pipeline = io_pipeline.
    mo_registry = io_tool_registry.
  ENDMETHOD.

  METHOD execute_tool_calls.
    DATA lo_tool    TYPE REF TO zif_ai_tool.
    DATA lx_error   TYPE REF TO cx_root.
    DATA lv_err_txt TYPE string.
    FIELD-SYMBOLS <fs_tool_call> TYPE zcl_ai_assistant_message=>ty_s_tool_call.

    LOOP AT it_tool_call ASSIGNING <fs_tool_call>.
      TRY.
          lo_tool = mo_registry->get( iv_name  = <fs_tool_call>-name
                                      iv_input = <fs_tool_call>-arguments ).
          mo_memory->add( NEW zcl_ai_tool_message( iv_id     = <fs_tool_call>-id
                                                   iv_name   = <fs_tool_call>-name
                                                   iv_result = lo_tool->execute( ) ) ).
        CATCH cx_root INTO lx_error.
          WHILE lx_error->previous IS BOUND.
            lx_error = lx_error->previous.
          ENDWHILE.
          lv_err_txt = |Tool execution failed: { lx_error->get_text( ) }|.
          mo_memory->add( NEW zcl_ai_tool_message( iv_id     = <fs_tool_call>-id
                                                   iv_name   = <fs_tool_call>-name
                                                   iv_result = lv_err_txt ) ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ai_agent~execute.
    DATA lo_context    TYPE REF TO zcl_ai_context.
    DATA lt_tool_calls TYPE zcl_ai_assistant_message=>ty_t_tool_call.
    DATA lx_error      TYPE REF TO cx_root.

    mo_memory->add( NEW zcl_ai_user_message( iv_task ) ).

    DO mv_max_tool_round TIMES.
      lo_context = NEW zcl_ai_context( io_memory   = mo_memory
                                       io_tool_reg = mo_registry ).

      TRY.
          ro_message = mo_pipeline->run( io_context  = lo_context
                                         io_provider = mo_provider ).

          mo_memory->add( ro_message ).

          IF ro_message IS NOT INSTANCE OF zcl_ai_assistant_message.
            RETURN.
          ENDIF.

          lt_tool_calls = CAST zcl_ai_assistant_message( ro_message )->get_tool_calls( ).
          IF lt_tool_calls IS INITIAL.
            RETURN.
          ENDIF.

          execute_tool_calls( lt_tool_calls ).
        CATCH cx_root INTO lx_error.
          WHILE lx_error->previous IS BOUND.
            lx_error = lx_error->previous.
          ENDWHILE.
          ro_message = NEW zcl_ai_assistant_message( |Pipeline Core Error: { lx_error->get_text( ) }| ).
          mo_memory->add( ro_message ).
          RETURN.
      ENDTRY.
    ENDDO.

    ro_message = NEW zcl_ai_assistant_message( 'Agent failed: Maximum tool rounds reached without resolving the task.' ).
    mo_memory->add( ro_message ).
  ENDMETHOD.
ENDCLASS.
