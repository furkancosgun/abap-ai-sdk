CLASS zcl_ai_short_dump_read_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING is_key TYPE snap_key.

  PRIVATE SECTION.
    DATA ms_key TYPE snap_key.
ENDCLASS.


CLASS zcl_ai_short_dump_read_tool IMPLEMENTATION.
  METHOD constructor.
    ms_key = is_key.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_s_source_detail,
        program TYPE syrepid,
        include TYPE syrepid,
        lineno  TYPE i,
        source  TYPE string,
      END OF ty_s_source_detail.
    TYPES:
      BEGIN OF ty_s_detail,
        short_description TYPE string,
        what_happened     TYPE string,
        error_analysis    TYPE string,
        source_detail     TYPE ty_s_source_detail,
      END OF ty_s_detail.

    DATA ls_detail      TYPE ty_s_detail.
    DATA lt_entries     TYPE snap_entries.
    DATA lt_source_raw  TYPE sourcetable.
    DATA lo_entry       TYPE REF TO cl_runtime_error.
    DATA lv_from        TYPE i.
    DATA lv_to          TYPE i.
    DATA lv_total_lines TYPE i.
    DATA lv_index       TYPE i.
    DATA lv_line_str    TYPE string.

    cl_runtime_error=>create( EXPORTING p_i_t_snapkeys    = VALUE #( ( ms_key ) )
                              IMPORTING p_e_t_snapentries = lt_entries ).
    IF lt_entries IS INITIAL.
      zcx_ai_error=>raise( 'Runtime error not found.' ).
    ENDIF.

    lo_entry = lt_entries[ 1 ].

    lo_entry->get_what_happened_text( CHANGING p_text = ls_detail-what_happened ).
    lo_entry->get_error_analysis_text( IMPORTING p_text = ls_detail-error_analysis ).
    lo_entry->get_short_description( IMPORTING p_e_short_text = ls_detail-short_description ).
    lo_entry->get_abap_sourceinfo( IMPORTING p_e_include     = ls_detail-source_detail-include
                                             p_e_mainprogram = ls_detail-source_detail-program
                                             p_e_lineno      = ls_detail-source_detail-lineno
                                             p_e_sourcetext  = lt_source_raw ).

    lv_total_lines = lines( lt_source_raw ).
    IF lv_total_lines > 0.
      lv_from = nmax( val1 = 1
                      val2 = ls_detail-source_detail-lineno - 8 ).
      lv_to   = nmin( val1 = lv_total_lines
                      val2 = ls_detail-source_detail-lineno + 8 ).

      LOOP AT lt_source_raw INTO lv_line_str FROM lv_from TO lv_to.
        lv_index = sy-tabix.
        IF lv_index = ls_detail-source_detail-lineno.
          ls_detail-source_detail-source = |{ ls_detail-source_detail-source } { lv_line_str } <--ERROR:\n|.
        ELSE.
          ls_detail-source_detail-source = |{ ls_detail-source_detail-source }{ lv_line_str }\n|.
        ENDIF.
      ENDLOOP.
    ENDIF.

    rv_result = zcl_ai_serializer=>serialize( ls_detail ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'read_short_dump'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Reads full details of a specific ABAP short dump by its snapshot ID from ST22.'.
  ENDMETHOD.
ENDCLASS.
