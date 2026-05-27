CLASS zcl_ai_agent_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_task          TYPE string
                iv_system_prompt TYPE string DEFAULT 'You are a helpful AI assistant.'.

  PRIVATE SECTION.
    DATA mv_task          TYPE string.
    DATA mv_system_prompt TYPE string.
ENDCLASS.


CLASS zcl_ai_agent_tool IMPLEMENTATION.
  METHOD constructor.
    mv_task          = iv_task.
    mv_system_prompt = iv_system_prompt.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lo_agent   TYPE REF TO zif_ai_agent.
    DATA lo_message TYPE REF TO zcl_ai_message.
    TYPES:
      BEGIN OF ty_result,
        task    TYPE string,
        summary TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    lo_agent = zcl_ai_agent_factory=>create_default( iv_system_prompt = mv_system_prompt ).
    lo_message = lo_agent->execute( mv_task ).
    IF lo_message IS NOT BOUND.
      zcx_ai_error=>raise( 'Internal error.' ).
    ENDIF.

    ls_result = VALUE #( task    = mv_task
                         summary = lo_message->get_content( ) ).
    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'delegate_task'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Creates a sub-agent to handle a specific task and returns its response.'.
  ENDMETHOD.
ENDCLASS.
