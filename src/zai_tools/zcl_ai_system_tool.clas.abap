CLASS zcl_ai_system_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_system_info,
        sysid TYPE string,
        mandt TYPE string,
        saprl TYPE string,
        uname TYPE string,
        datum TYPE string,
        uzeit TYPE string,
      END OF ty_system_info.
ENDCLASS.


CLASS zcl_ai_system_tool IMPLEMENTATION.
  METHOD zif_ai_tool~execute.
    DATA ls_info TYPE ty_system_info.

    ls_info = VALUE #( sysid = sy-sysid
                       mandt = sy-mandt
                       saprl = sy-saprl
                       uname = sy-uname
                       datum = |{ sy-datum DATE = ISO }|
                       uzeit = |{ sy-uzeit TIME = ISO }| ).

    rv_result = zcl_ai_serializer=>serialize( ls_info ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'get_system_info'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Returns current SAP system information (SID, client, host, version, user, date, time).'.
  ENDMETHOD.
ENDCLASS.
