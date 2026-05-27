CLASS zcl_ai_short_dump_list_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING it_date  TYPE cl_runtime_error=>snap_r_date
                it_time  TYPE cl_runtime_error=>snap_r_time  OPTIONAL
                it_user  TYPE cl_runtime_error=>snap_r_uname OPTIONAL
                iv_limit TYPE i                              OPTIONAL.

  PRIVATE SECTION.
    DATA mt_date  TYPE cl_runtime_error=>snap_r_date.
    DATA mt_time  TYPE cl_runtime_error=>snap_r_time.
    DATA mt_user  TYPE cl_runtime_error=>snap_r_uname.
    DATA mv_limit TYPE i.
ENDCLASS.


CLASS zcl_ai_short_dump_list_tool IMPLEMENTATION.
  METHOD constructor.
    mt_date = it_date.
    mt_time = it_time.
    mt_user = it_user.
    mv_limit = iv_limit.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lt_keys TYPE snap_keys.

    cl_runtime_error=>select( EXPORTING p_r_date          = mt_date
                                        p_r_time          = mt_time
                                        p_r_uname         = mt_user
                              IMPORTING p_e_t_snapentries = lt_keys ).

    rv_result = zcl_ai_serializer=>serialize( lt_keys ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'list_short_dump'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Lists recent ABAP short dumps (ST22) with details like date, user, program, and error text.'.
  ENDMETHOD.
ENDCLASS.
