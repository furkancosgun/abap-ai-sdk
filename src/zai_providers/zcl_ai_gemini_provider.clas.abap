CLASS zcl_ai_gemini_provider DEFINITION
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
      BEGIN OF ty_s_res_funcall,
        id   TYPE string,
        name TYPE string,
        args TYPE REF TO data,
      END OF ty_s_res_funcall.

    TYPES:
      BEGIN OF ty_s_part,
        text          TYPE string,
        function_call TYPE ty_s_res_funcall,
      END OF ty_s_part.
    TYPES ty_t_parts TYPE STANDARD TABLE OF ty_s_part WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_content,
        role  TYPE string,
        parts TYPE ty_t_parts,
      END OF ty_s_content.
    TYPES ty_t_contents TYPE STANDARD TABLE OF ty_s_content WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_sys_instruction,
        parts TYPE ty_t_parts,
      END OF ty_s_sys_instruction.

    TYPES:
      BEGIN OF ty_s_tool_wrapper,
        function_declarations TYPE REF TO data,
      END OF ty_s_tool_wrapper.
    TYPES ty_t_tools TYPE STANDARD TABLE OF ty_s_tool_wrapper WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_req,
        contents           TYPE ty_t_contents,
        system_instruction TYPE ty_s_sys_instruction,
        tools              TYPE ty_t_tools,
      END OF ty_s_req.

    TYPES:
      BEGIN OF ty_s_res_content,
        parts TYPE ty_t_parts,
      END OF ty_s_res_content.
    TYPES:
      BEGIN OF ty_s_candidate,
        content TYPE ty_s_res_content,
      END OF ty_s_candidate.
    TYPES ty_t_candidates TYPE STANDARD TABLE OF ty_s_candidate WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_res,
        candidates TYPE ty_t_candidates,
      END OF ty_s_res.

    DATA mo_client  TYPE REF TO zif_ai_http_client.
    DATA mo_format  TYPE REF TO zif_ai_tool_formatter.
    DATA mv_model   TYPE string.
    DATA mv_api_key TYPE string.

    METHODS serialize_messages
      IMPORTING it_messages TYPE zcl_ai_message=>ty_t_messages
      CHANGING  cs_req      TYPE ty_s_req.
ENDCLASS.


CLASS zcl_ai_gemini_provider IMPLEMENTATION.
  METHOD constructor.
    mo_client  = io_client.
    mo_format  = io_format.
    mv_model   = iv_model.
    mv_api_key = iv_api_key.
  ENDMETHOD.

  METHOD zif_ai_provider~generate.
    DATA ls_req       TYPE ty_s_req.
    DATA lv_req       TYPE string.
    DATA ls_res       TYPE ty_s_res.
    DATA lv_res       TYPE string.
    DATA lv_endpoint  TYPE string.
    DATA lv_text      TYPE string.
    DATA ls_funcall   TYPE ty_s_res_funcall.
    DATA ls_tool_wrap TYPE ty_s_tool_wrapper.
    DATA lo_tool_data TYPE REF TO data.

    serialize_messages( EXPORTING it_messages = it_messages
                        CHANGING  cs_req      = ls_req ).

    IF it_tools IS NOT INITIAL.
      lo_tool_data = mo_format->format_all( it_tools ).
      ls_tool_wrap-function_declarations = lo_tool_data.
      APPEND ls_tool_wrap TO ls_req-tools.
    ENDIF.
    lv_req = zcl_ai_serializer=>serialize( iv_data = ls_req
                                           iv_mode = zcl_ai_serializer=>mc_pretty_mode-camel_case ).

    lv_endpoint = |/v1beta/models/{ mv_model }:generateContent|.
    IF mv_api_key IS NOT INITIAL.
      lv_endpoint = |{ lv_endpoint }?key={ mv_api_key }|.
    ENDIF.

    lv_res = mo_client->send( iv_endpoint = lv_endpoint
                              iv_body     = lv_req ).

    zcl_ai_serializer=>deserialize( EXPORTING iv_json = lv_res
                                              iv_mode = zcl_ai_serializer=>mc_pretty_mode-camel_case
                                    IMPORTING ev_data = ls_res ).

    ASSIGN ls_res-candidates[ 1 ] TO FIELD-SYMBOL(<fs_candidate>).
    IF sy-subrc = 0.
      LOOP AT <fs_candidate>-content-parts ASSIGNING FIELD-SYMBOL(<fs_part>).
        IF <fs_part>-text IS NOT INITIAL.
          lv_text = <fs_part>-text.
        ENDIF.
        IF <fs_part>-function_call IS NOT INITIAL.
          ls_funcall = <fs_part>-function_call.
        ENDIF.
      ENDLOOP.
    ENDIF.

    ro_message = NEW zcl_ai_assistant_message(
                         iv_content    = lv_text
                         it_tool_calls = COND #( WHEN ls_funcall-name IS NOT INITIAL
                                                 THEN VALUE #( ( id        = ls_funcall-id
                                                                 name      = ls_funcall-name
                                                                 arguments = ls_funcall-args ) ) ) ).
  ENDMETHOD.

  METHOD serialize_messages.
    DATA lo_msg     TYPE REF TO zcl_ai_message.
    DATA lo_assist  TYPE REF TO zcl_ai_assistant_message.
    DATA ls_content TYPE ty_s_content.
    DATA ls_part    TYPE ty_s_part.
    FIELD-SYMBOLS <fs_call> TYPE zcl_ai_assistant_message=>ty_s_tool_call.

    LOOP AT it_messages INTO lo_msg.
      IF lo_msg->get_role( ) = 'system'.
        CLEAR ls_part.
        ls_part-text = lo_msg->get_content( ).
        APPEND ls_part TO cs_req-system_instruction-parts.
        CONTINUE.
      ENDIF.

      CLEAR ls_content.
      CASE lo_msg->get_role( ).
        WHEN 'assistant'.
          ls_content-role = 'model'.
        WHEN 'tool'.
          ls_content-role = 'user'.
        WHEN OTHERS.
          ls_content-role = lo_msg->get_role( ).
      ENDCASE.

      IF lo_msg->get_content( ) IS NOT INITIAL.
        CLEAR ls_part.
        ls_part-text = lo_msg->get_content( ).
        APPEND ls_part TO ls_content-parts.
      ENDIF.

      IF lo_msg IS INSTANCE OF zcl_ai_assistant_message.
        lo_assist ?= lo_msg.
        LOOP AT lo_assist->get_tool_calls( ) ASSIGNING <fs_call>.
          CLEAR ls_part.
          ls_part-function_call-id   = <fs_call>-id.
          ls_part-function_call-name = <fs_call>-name.
          ls_part-function_call-args = <fs_call>-arguments.
          APPEND ls_part TO ls_content-parts.
        ENDLOOP.
      ENDIF.

      APPEND ls_content TO cs_req-contents.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
