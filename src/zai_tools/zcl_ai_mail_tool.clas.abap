CLASS zcl_ai_mail_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    TYPES:
      BEGIN OF ty_s_recipient,
        email TYPE ad_smtpadr,
      END OF ty_s_recipient.
    TYPES ty_t_recipient TYPE STANDARD TABLE OF ty_s_recipient WITH EMPTY KEY.

    METHODS constructor
      IMPORTING iv_subject TYPE string
                iv_body    TYPE string
                it_to      TYPE ty_t_recipient
                it_cc      TYPE ty_t_recipient OPTIONAL
                it_bcc     TYPE ty_t_recipient OPTIONAL
                iv_sender  TYPE ad_smtpadr     OPTIONAL.

  PRIVATE SECTION.
    DATA mv_subject TYPE string.
    DATA mv_body    TYPE string.
    DATA mt_to      TYPE ty_t_recipient.
    DATA mt_cc      TYPE ty_t_recipient.
    DATA mt_bcc     TYPE ty_t_recipient.
    DATA mv_sender  TYPE string.
ENDCLASS.


CLASS zcl_ai_mail_tool IMPLEMENTATION.
  METHOD constructor.
    mv_subject = iv_subject.
    mv_body    = iv_body.
    mt_to      = it_to.
    mt_cc      = it_cc.
    mt_bcc     = it_bcc.
    mv_sender  = iv_sender.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lo_bcs TYPE REF TO cl_bcs_message.

    lo_bcs = NEW cl_bcs_message( ).

    lo_bcs->set_subject( mv_subject ).
    lo_bcs->set_main_doc( iv_contents_txt = mv_body
                          iv_doctype      = 'HTM' ).
    IF mv_sender IS NOT INITIAL.
      lo_bcs->set_sender( iv_address = mv_sender ).
    ENDIF.

    LOOP AT mt_to ASSIGNING FIELD-SYMBOL(<fs_to>).
      lo_bcs->add_recipient( iv_address = CONV #( <fs_to>-email ) ).
    ENDLOOP.

    LOOP AT mt_cc ASSIGNING FIELD-SYMBOL(<fs_cc>).
      lo_bcs->add_recipient( iv_address = CONV #( <fs_cc>-email )
                             iv_copy    = 'C' ).
    ENDLOOP.

    LOOP AT mt_bcc ASSIGNING FIELD-SYMBOL(<fs_bcc>).
      lo_bcs->add_recipient( iv_address = CONV #( <fs_bcc>-email )
                             iv_copy    = 'B' ).
    ENDLOOP.

    lo_bcs->send( ).

    rv_result = 'Mail successfuly sent.'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'send_mail'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Sends an email via SAP internal mail system with to, cc, bcc, subject, and body.'.
  ENDMETHOD.
ENDCLASS.
