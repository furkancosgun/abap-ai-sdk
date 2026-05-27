CLASS zcl_ai_sql_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_query TYPE string.

  PRIVATE SECTION.
    DATA mv_query TYPE string.
ENDCLASS.


CLASS zcl_ai_sql_tool IMPLEMENTATION.
  METHOD constructor.
    mv_query = iv_query.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lo_sql       TYPE REF TO cl_sql_statement.
    DATA lo_result    TYPE REF TO cl_sql_result_set.
    DATA lt_metadata  TYPE adbc_rs_metadata_descr_tab.
    DATA lo_tabletype TYPE REF TO cl_abap_tabledescr.
    DATA lr_result    TYPE REF TO data.
    FIELD-SYMBOLS <fs_metadata> LIKE LINE OF lt_metadata.

    lo_sql = NEW cl_sql_statement( ).
    lo_result = lo_sql->execute_query( mv_query ).
    lt_metadata = lo_result->get_metadata( ).

    LOOP AT lt_metadata ASSIGNING <fs_metadata>.
      IF <fs_metadata>-column_name IS INITIAL.
        <fs_metadata>-column_name = |COL{ sy-tabix }|.
      ENDIF.
      CASE <fs_metadata>-data_type.
        WHEN cl_sql_result_set=>c_md_type_p.
          IF <fs_metadata>-length > cl_abap_elemdescr=>type_p_max_length.
            <fs_metadata>-length = cl_abap_elemdescr=>type_p_max_length.
          ENDIF.
        WHEN cl_sql_result_set=>c_md_type_c.
          IF <fs_metadata>-length > cl_abap_elemdescr=>type_c_max_length.
            <fs_metadata>-length = cl_abap_elemdescr=>type_c_max_length.
          ENDIF.
        WHEN cl_sql_result_set=>c_md_type_x.
          IF <fs_metadata>-length > cl_abap_elemdescr=>type_x_max_length.
            <fs_metadata>-length = cl_abap_elemdescr=>type_x_max_length.
          ENDIF.
      ENDCASE.
    ENDLOOP.

    lo_tabletype = cl_abap_tabledescr=>create( p_line_type = CAST cl_abap_structdescr(
                                                        cl_abap_structdescr=>describe_by_data_ref(
                                                            p_data_ref = lo_result->get_struct_ref(
                                                                             md_tab = lt_metadata ) ) ) ).
    CREATE DATA lr_result TYPE HANDLE lo_tabletype.
    lo_result->set_param_table( lr_result ).
    lo_result->next_package( ).
    lo_result->close( ).

    rv_result = zcl_ai_serializer=>serialize( lr_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'execute_sql'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Executes an SQL query on the current system database and returns results as JSON.'.
  ENDMETHOD.
ENDCLASS.
