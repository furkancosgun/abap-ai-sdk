CLASS zcl_ai_table_def_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_table_name TYPE dd02l-tabname.

  PRIVATE SECTION.
    DATA mv_table_name TYPE dd02l-tabname.
ENDCLASS.


CLASS zcl_ai_table_def_tool IMPLEMENTATION.
  METHOD constructor.
    mv_table_name = iv_table_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_field,
        fieldname TYPE string,
        keyflag   TYPE string,
        datatype  TYPE string,
        leng      TYPE string,
        decimals  TYPE string,
        fieldtext TYPE string,
      END OF ty_field.
    TYPES:
      BEGIN OF ty_result,
        table_name TYPE string,
        table_type TYPE dd02l-tabclass,
        fields     TYPE STANDARD TABLE OF ty_field WITH EMPTY KEY,
      END OF ty_result.
    DATA ls_result TYPE ty_result.
    DATA lt_dfies  TYPE STANDARD TABLE OF dfies WITH EMPTY KEY.

    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING  tabname  = mv_table_name
      IMPORTING ddobjtype = ls_result-table_type
      TABLES dfies_tab    = lt_dfies
      EXCEPTIONS OTHERS   = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise( |Table { mv_table_name } not found.| ).
    ENDIF.

    ls_result-table_name = mv_table_name.
    LOOP AT lt_dfies ASSIGNING FIELD-SYMBOL(<fs_dfies>).
      APPEND VALUE #( fieldname = <fs_dfies>-fieldname
                      keyflag   = <fs_dfies>-keyflag
                      datatype  = <fs_dfies>-datatype
                      leng      = <fs_dfies>-leng
                      decimals  = <fs_dfies>-decimals
                      fieldtext = <fs_dfies>-fieldtext )
             TO ls_result-fields.
    ENDLOOP.

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'get_table_definition'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Returns the field definition and metadata of a given ABAP dictionary table.'.
  ENDMETHOD.
ENDCLASS.
