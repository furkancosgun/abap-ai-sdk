CLASS zcl_ai_anthropic_provider DEFINITION
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
      BEGIN OF ty_s_msg_content,
        type        TYPE string,
        text        TYPE string,
        id          TYPE string,
        name        TYPE string,
        input       TYPE REF TO data,
        tool_use_id TYPE string,
        content     TYPE string,
      END OF ty_s_msg_content.
    TYPES ty_t_msg_content TYPE STANDARD TABLE OF ty_s_msg_content WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_message,
        role    TYPE string,
        content TYPE ty_t_msg_content,
      END OF ty_s_message.
    TYPES ty_t_messages TYPE STANDARD TABLE OF ty_s_message WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_req,
        model      TYPE string,
        max_tokens TYPE i,
        system     TYPE string,
        messages   TYPE ty_t_messages,
        tools      TYPE REF TO data,
      END OF ty_s_req.
    TYPES:
      BEGIN OF ty_s_res_content,
        type  TYPE string,
        text  TYPE string,
        id    TYPE string,
        name  TYPE string,
        input TYPE REF TO data,
      END OF ty_s_res_content.
    TYPES ty_t_res_content TYPE STANDARD TABLE OF ty_s_res_content WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_res,
        content TYPE ty_t_res_content,
      END OF ty_s_res.

    DATA mo_client  TYPE REF TO zif_ai_http_client.
    DATA mo_format  TYPE REF TO zif_ai_tool_formatter.
    DATA mv_model   TYPE string.
    DATA mv_api_key TYPE string.

    METHODS serialize_messages
      IMPORTING it_messages TYPE zcl_ai_message=>ty_t_messages
      EXPORTING ev_system   TYPE string
                et_messages TYPE ty_t_messages.
ENDCLASS.


CLASS zcl_ai_anthropic_provider IMPLEMENTATION.
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
    DATA lv_text       TYPE string.
    DATA lt_tool_calls TYPE zcl_ai_assistant_message=>ty_t_tool_call.
    FIELD-SYMBOLS <fs_block> TYPE ty_s_res_content.

    serialize_messages( EXPORTING it_messages = it_messages
                        IMPORTING ev_system   = ls_req-system
                                  et_messages = ls_req-messages ).

    ls_req-model      = mv_model.
    ls_req-max_tokens = 1024.
    ls_req-tools      = mo_format->format_all( it_tools ).

    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-camel_case ).

    lv_res = mo_client->send( iv_endpoint = '/v1/messages'
                              iv_body     = lv_req
                              it_headers  = COND #( WHEN mv_api_key IS NOT INITIAL
                                                    THEN VALUE #( ( name  = 'x-api-key'
                                                                    value = mv_api_key )
                                                                  ( name  = 'anthropic-version'
                                                                    value = '2023-06-01' ) ) ) ).

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                    IMPORTING ev_data = ls_res ).

    lv_text = VALUE #( ls_res-content[ type = 'text' ]-text OPTIONAL ).

    lt_tool_calls = VALUE #( ).
    LOOP AT ls_res-content ASSIGNING <fs_block> WHERE type = 'tool_use'.
      APPEND VALUE #( id        = <fs_block>-id
                      name      = <fs_block>-name
                      arguments = <fs_block>-input ) TO lt_tool_calls.
    ENDLOOP.

    ro_message = NEW zcl_ai_assistant_message( iv_content    = lv_text
                                               it_tool_calls = lt_tool_calls ).
  ENDMETHOD.

  METHOD serialize_messages.
    DATA lv_role      TYPE string.
    DATA lo_tool      TYPE REF TO zcl_ai_tool_message.
    DATA lo_assistant TYPE REF TO zcl_ai_assistant_message.
    FIELD-SYMBOLS <fs_msg>       TYPE REF TO zcl_ai_message.
    FIELD-SYMBOLS <fs_anthropic> TYPE ty_s_message.
    FIELD-SYMBOLS <fs_call>      TYPE zcl_ai_assistant_message=>ty_s_tool_call.

    LOOP AT it_messages ASSIGNING <fs_msg>.
      lv_role = <fs_msg>->get_role( ).

      IF lv_role = 'system'.
        ev_system = <fs_msg>->get_content( ).
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO et_messages ASSIGNING <fs_anthropic>.
      <fs_anthropic>-role = lv_role.

      IF <fs_msg> IS INSTANCE OF zcl_ai_tool_message.
        lo_tool = CAST zcl_ai_tool_message( <fs_msg> ).
        <fs_anthropic>-role    = 'user'.
        <fs_anthropic>-content = VALUE #( ( type        = 'tool_result'
                                            tool_use_id = lo_tool->get_id( )
                                            content     = <fs_msg>->get_content( ) ) ).
      ELSEIF <fs_msg> IS INSTANCE OF zcl_ai_assistant_message.
        lo_assistant = CAST zcl_ai_assistant_message( <fs_msg> ).
        <fs_anthropic>-content = VALUE #( ( type = 'text'
                                            text = <fs_msg>->get_content( ) ) ).
        LOOP AT lo_assistant->get_tool_calls( ) ASSIGNING <fs_call>.
          APPEND VALUE #( type  = 'tool_use'
                          id    = <fs_call>-id
                          name  = <fs_call>-name
                          input = <fs_call>-arguments ) TO <fs_anthropic>-content.
        ENDLOOP.
      ELSE.
        <fs_anthropic>-content = VALUE #( ( type = 'text'
                                            text = <fs_msg>->get_content( ) ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
