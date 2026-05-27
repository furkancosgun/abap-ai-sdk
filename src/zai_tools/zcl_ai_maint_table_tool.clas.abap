CLASS zcl_ai_maint_table_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_table_name TYPE dd02l-tabname.

  PRIVATE SECTION.
    DATA mv_table_name TYPE dd02l-tabname.
ENDCLASS.


CLASS zcl_ai_maint_table_tool IMPLEMENTATION.
  METHOD constructor.
    mv_table_name = iv_table_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        table_name TYPE string,
        message    TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING  action    = 'S'
                 view_name = mv_table_name
      EXCEPTIONS OTHERS    = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    ls_result = VALUE #( table_name = mv_table_name
                         message    = |Maintenance view for { mv_table_name } opened.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'call_maintenance_table'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Opens the table maintenance dialog (SM30) for a given table name.'.
  ENDMETHOD.
ENDCLASS.
