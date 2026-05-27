CLASS zcl_ai_user_detail_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_username TYPE sy-uname.

  PRIVATE SECTION.
    DATA mv_username TYPE sy-uname.
ENDCLASS.


CLASS zcl_ai_user_detail_tool IMPLEMENTATION.
  METHOD constructor.
    mv_username = iv_username.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_s_detail,
        title      TYPE string,
        firstname  TYPE string,
        lastname   TYPE string,
        email      TYPE string,
        department TYPE string,
        telephone  TYPE string,
      END OF ty_s_detail.
    DATA ls_result TYPE ty_s_detail.
    DATA ls_addr   TYPE bapiaddr3.
    DATA lt_return TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
      EXPORTING  username = mv_username
      IMPORTING address   = ls_addr
      TABLES return       = lt_return
      EXCEPTIONS OTHERS   = 1.
    LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type CA 'EAX'.
      EXIT.
    ENDLOOP.
    IF sy-subrc = 0.
      zcx_ai_error=>raise( |User { mv_username } not found.| ).
    ENDIF.

    ls_result = VALUE #( title      = ls_addr-title
                         firstname  = ls_addr-firstname
                         lastname   = ls_addr-lastname
                         email      = ls_addr-e_mail
                         department = ls_addr-department
                         telephone  = ls_addr-tel1_numbr ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'get_user_detail'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Returns details of an SAP user including address, authorization class, and user type.'.
  ENDMETHOD.
ENDCLASS.
