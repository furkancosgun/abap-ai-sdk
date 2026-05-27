CLASS zcl_ai_ollama_provider DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_client TYPE REF TO zif_ai_http_client
                io_format TYPE REF TO zif_ai_tool_formatter
                iv_model  TYPE string.

    INTERFACES zif_ai_provider.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_req_msg_tool_func,
        name      TYPE string,
        arguments TYPE REF TO data,
      END OF ty_s_req_msg_tool_func.
    TYPES:
      BEGIN OF ty_s_req_msg_tool,
        id       TYPE string,
        type     TYPE string,
        function TYPE ty_s_req_msg_tool_func,
      END OF ty_s_req_msg_tool.
    TYPES:
      BEGIN OF ty_s_req_msg,
        role         TYPE string,
        content      TYPE string,
        tool_calls   TYPE STANDARD TABLE OF ty_s_req_msg_tool WITH EMPTY KEY,
        tool_call_id TYPE string,
      END OF ty_s_req_msg.
    TYPES ty_t_req_msg TYPE STANDARD TABLE OF ty_s_req_msg WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_req,
        model    TYPE string,
        stream   TYPE abap_bool,
        messages TYPE ty_t_req_msg,
        tools    TYPE REF TO data,
      END OF ty_s_req.

    TYPES:
      BEGIN OF ty_s_res_msg,
        role       TYPE string,
        content    TYPE string,
        tool_calls TYPE STANDARD TABLE OF ty_s_req_msg_tool WITH EMPTY KEY,
      END OF ty_s_res_msg.

    TYPES:
      BEGIN OF ty_s_res,
        message TYPE ty_s_res_msg,
      END OF ty_s_res.

    DATA mo_client TYPE REF TO zif_ai_http_client.
    DATA mo_format TYPE REF TO zif_ai_tool_formatter.
    DATA mv_model  TYPE string.

    METHODS serialize_messages
      IMPORTING it_messages        TYPE zcl_ai_message=>ty_t_messages
      RETURNING VALUE(rt_messages) TYPE ty_t_req_msg.
ENDCLASS.


CLASS zcl_ai_ollama_provider IMPLEMENTATION.
  METHOD zif_ai_provider~generate.
    DATA ls_req TYPE ty_s_req.
    DATA lv_req TYPE string.
    DATA ls_res TYPE ty_s_res.
    DATA lv_res TYPE string.

    ls_req-model    = mv_model.
    ls_req-messages = serialize_messages( it_messages ).
    ls_req-stream   = abap_undefined.
    ls_req-tools    = mo_format->format_all( it_tools ).

    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-low_case ).

    lv_res = mo_client->send( iv_endpoint = '/api/chat'
                              iv_body     = lv_req ).

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                    IMPORTING ev_data = ls_res ).

    ro_message = NEW zcl_ai_assistant_message( iv_content    = ls_res-message-content
                                               it_tool_calls = VALUE #( FOR tool IN ls_res-message-tool_calls
                                                                        ( id        = tool-id
                                                                          name      = tool-function-name
                                                                          arguments = tool-function-arguments ) ) ).
  ENDMETHOD.

  METHOD constructor.
    mo_client = io_client.
    mo_format = io_format.
    mv_model = iv_model.
  ENDMETHOD.

  METHOD serialize_messages.
    DATA lo_assistant TYPE REF TO zcl_ai_assistant_message.
    DATA lo_tool      TYPE REF TO zcl_ai_tool_message.
    FIELD-SYMBOLS <fs_message> TYPE REF TO zcl_ai_message.
    FIELD-SYMBOLS <fs_msg>     TYPE ty_s_req_msg.
    FIELD-SYMBOLS <fs_call>    TYPE zcl_ai_assistant_message=>ty_s_tool_call.

    LOOP AT it_messages ASSIGNING <fs_message>.
      APPEND INITIAL LINE TO rt_messages ASSIGNING <fs_msg>.
      <fs_msg>-role    = <fs_message>->get_role( ).
      <fs_msg>-content = <fs_message>->get_content( ).
      IF <fs_message> IS INSTANCE OF zcl_ai_assistant_message.
        lo_assistant = CAST zcl_ai_assistant_message( <fs_message> ).
        LOOP AT lo_assistant->get_tool_calls( ) ASSIGNING <fs_call>.
          APPEND VALUE #( id       = <fs_call>-id
                          type     = 'function'
                          function = VALUE #( name      = <fs_call>-name
                                              arguments = <fs_call>-arguments ) ) TO <fs_msg>-tool_calls.
        ENDLOOP.
      ENDIF.

      IF <fs_message> IS INSTANCE OF zcl_ai_tool_message.
        lo_tool = CAST zcl_ai_tool_message( <fs_message> ).
        <fs_msg>-tool_call_id = lo_tool->get_id( ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
