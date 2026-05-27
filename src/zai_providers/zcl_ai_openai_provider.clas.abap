CLASS zcl_ai_openai_provider DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_client  TYPE REF TO zif_ai_http_client
                io_format  TYPE REF TO zif_ai_tool_formatter
                iv_model   TYPE string
                iv_api_key TYPE string DEFAULT ''.

    INTERFACES zif_ai_provider.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_func,
        name      TYPE string,
        arguments TYPE REF TO data,
      END OF ty_s_func.
    TYPES:
      BEGIN OF ty_s_tool_call,
        id       TYPE string,
        type     TYPE string,
        function TYPE ty_s_func,
      END OF ty_s_tool_call.
    TYPES ty_t_tool_call TYPE STANDARD TABLE OF ty_s_tool_call WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_msg,
        role         TYPE string,
        content      TYPE string,
        tool_calls   TYPE ty_t_tool_call,
        tool_call_id TYPE string,
      END OF ty_s_msg.
    TYPES ty_t_msg TYPE STANDARD TABLE OF ty_s_msg WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_req,
        model    TYPE string,
        messages TYPE ty_t_msg,
        tools    TYPE REF TO data,
      END OF ty_s_req.
    TYPES:
      BEGIN OF ty_s_res_choice,
        message TYPE ty_s_msg,
      END OF ty_s_res_choice.
    TYPES ty_t_res_choice TYPE STANDARD TABLE OF ty_s_res_choice WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_res,
        choices TYPE ty_t_res_choice,
      END OF ty_s_res.

    DATA mo_client  TYPE REF TO zif_ai_http_client.
    DATA mo_format  TYPE REF TO zif_ai_tool_formatter.
    DATA mv_model   TYPE string.
    DATA mv_api_key TYPE string.

    METHODS serialize_messages
      IMPORTING it_messages        TYPE zcl_ai_message=>ty_t_messages
      RETURNING VALUE(rt_messages) TYPE ty_t_msg.
ENDCLASS.


CLASS zcl_ai_openai_provider IMPLEMENTATION.
  METHOD constructor.
    mo_client  = io_client.
    mo_format  = io_format.
    mv_model   = iv_model.
    mv_api_key = iv_api_key.
  ENDMETHOD.

  METHOD zif_ai_provider~generate.
    DATA ls_req        TYPE ty_s_req.
    DATA lv_req        TYPE string.
    DATA ls_res        TYPE ty_s_res.
    DATA lv_res        TYPE string.
    DATA lt_tool_calls TYPE zcl_ai_assistant_message=>ty_t_tool_call.
    DATA lr_args       TYPE REF TO data.
    DATA lv_args       TYPE string.
    FIELD-SYMBOLS <fs_call> TYPE ty_s_tool_call.
    FIELD-SYMBOLS <fs_args> TYPE data.

    ls_req-model    = mv_model.
    ls_req-messages = serialize_messages( it_messages ).
    ls_req-tools    = mo_format->format_all( it_tools ).

    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-low_case ).

    IF mv_api_key IS NOT INITIAL.
      lv_res = mo_client->send( iv_endpoint = '/v1/chat/completions'
                                iv_body     = lv_req
                                it_headers  = VALUE #( ( name  = 'Authorization'
                                                         value = |Bearer { mv_api_key }| ) ) ).
    ELSE.
      lv_res = mo_client->send( iv_endpoint = '/v1/chat/completions'
                                iv_body     = lv_req ).
    ENDIF.

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                    IMPORTING ev_data = ls_res ).

    lv_res = VALUE #( ls_res-choices[ 1 ]-message-content OPTIONAL ).

    LOOP AT ls_res-choices[ 1 ]-message-tool_calls ASSIGNING <fs_call>.
      ASSIGN <fs_call>-function-arguments->* TO <fs_args>.
      IF sy-subrc = 0.
        lv_args = <fs_args>.
      ENDIF.

      CREATE DATA lr_args TYPE string.
      ASSIGN lr_args->* TO <fs_args>.
      <fs_args> = lv_args.
      APPEND VALUE #( id        = <fs_call>-id
                      name      = <fs_call>-function-name
                      arguments = lr_args ) TO lt_tool_calls.
    ENDLOOP.

    ro_message = NEW zcl_ai_assistant_message( iv_content    = lv_res
                                               it_tool_calls = lt_tool_calls ).
  ENDMETHOD.

  METHOD serialize_messages.
    DATA lo_assistant TYPE REF TO zcl_ai_assistant_message.
    DATA lo_tool      TYPE REF TO zcl_ai_tool_message.
    DATA ls_func      TYPE ty_s_func.
    FIELD-SYMBOLS <fs_msg>  TYPE REF TO zcl_ai_message.
    FIELD-SYMBOLS <fs_m>    TYPE ty_s_msg.
    FIELD-SYMBOLS <fs_call> TYPE zcl_ai_assistant_message=>ty_s_tool_call.
    FIELD-SYMBOLS <fs_args> TYPE data.

    LOOP AT it_messages ASSIGNING <fs_msg>.
      APPEND INITIAL LINE TO rt_messages ASSIGNING <fs_m>.
      <fs_m>-role    = <fs_msg>->get_role( ).
      <fs_m>-content = <fs_msg>->get_content( ).

      IF <fs_msg> IS INSTANCE OF zcl_ai_assistant_message.
        lo_assistant = CAST zcl_ai_assistant_message( <fs_msg> ).
        LOOP AT lo_assistant->get_tool_calls( ) ASSIGNING <fs_call>.
          ASSIGN <fs_call>-arguments->* TO <fs_args>.
          ls_func = VALUE #( name      = <fs_call>-name
                             arguments = <fs_args> ).
          APPEND VALUE #( id       = <fs_call>-id
                          type     = 'function'
                          function = ls_func ) TO <fs_m>-tool_calls.
        ENDLOOP.
      ENDIF.

      IF <fs_msg> IS INSTANCE OF zcl_ai_tool_message.
        lo_tool = CAST zcl_ai_tool_message( <fs_msg> ).
        <fs_m>-tool_call_id = lo_tool->get_id( ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
