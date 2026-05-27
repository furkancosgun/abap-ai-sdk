CLASS zcl_ai_assistant_message DEFINITION
  PUBLIC
  INHERITING FROM zcl_ai_message FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_tool_call,
        id        TYPE string,
        name      TYPE string,
        arguments TYPE REF TO data,
      END OF ty_s_tool_call.
    TYPES ty_t_tool_call TYPE STANDARD TABLE OF ty_s_tool_call WITH EMPTY KEY.

    METHODS constructor
      IMPORTING iv_content    TYPE string
                it_tool_calls TYPE ty_t_tool_call OPTIONAL.

    METHODS get_tool_calls
      RETURNING VALUE(rt_tool_calls) TYPE ty_t_tool_call.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA mt_tool_calls TYPE ty_t_tool_call.
ENDCLASS.


CLASS zcl_ai_assistant_message IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_role    = 'assistant'
                        iv_name    = ''
                        iv_content = iv_content ).
    mt_tool_calls = it_tool_calls.
  ENDMETHOD.

  METHOD get_tool_calls.
    rt_tool_calls = mt_tool_calls.
  ENDMETHOD.
ENDCLASS.
