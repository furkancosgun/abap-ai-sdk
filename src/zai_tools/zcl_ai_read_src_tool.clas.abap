CLASS zcl_ai_read_src_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_object_type TYPE tadir-object
                iv_object_name TYPE tadir-obj_name.

  PRIVATE SECTION.
    TYPES ty_t_sources TYPE STANDARD TABLE OF tadir-obj_name WITH EMPTY KEY.

    METHODS get_source_includes
      RETURNING VALUE(rt_sources) TYPE ty_t_sources
      RAISING   zcx_ai_error.

    DATA mv_object_type TYPE tadir-object.
    DATA mv_object_name TYPE tadir-obj_name.
ENDCLASS.


CLASS zcl_ai_read_src_tool IMPLEMENTATION.
  METHOD constructor.
    mv_object_type = iv_object_type.
    mv_object_name = iv_object_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        object_type TYPE string,
        object_name TYPE string,
        lines       TYPE STANDARD TABLE OF string WITH EMPTY KEY,
      END OF ty_result.
    DATA lt_source   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA ls_result   TYPE ty_result.
    DATA lt_includes TYPE ty_t_sources.
    FIELD-SYMBOLS <fs_include> LIKE LINE OF lt_includes.

    ls_result = VALUE #( object_type = mv_object_type
                         object_name = mv_object_name ).

    lt_includes = get_source_includes( ).
    LOOP AT lt_includes ASSIGNING <fs_include>.
      READ REPORT <fs_include> INTO lt_source.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      APPEND LINES OF lt_source TO ls_result-lines.
    ENDLOOP.

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'read_source'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Reads ABAP source code of an object (class, program, etc.) by type and name.'.
  ENDMETHOD.

  METHOD get_source_includes.
    DATA lv_include TYPE rs38l-include.

    CASE mv_object_type.
      WHEN 'PROG'.
        APPEND mv_object_name TO rt_sources.
      WHEN 'FUNC'.
        CALL FUNCTION 'FUNCTION_EXISTS'
          EXPORTING  funcname = CONV rs38l-name( mv_object_name )
          IMPORTING include   = lv_include
          EXCEPTIONS OTHERS   = 1.
        IF sy-subrc <> 0.
          zcx_ai_error=>raise_syst( ).
        ENDIF.
        APPEND lv_include TO rt_sources.
      WHEN 'CLAS'.
        cl_oo_classname_service=>get_all_class_includes( EXPORTING  class_name = CONV #( mv_object_name )
                                                         RECEIVING result      = rt_sources
                                                         EXCEPTIONS OTHERS     = 1 ).
        IF sy-subrc <> 0.
          zcx_ai_error=>raise_syst( ).
        ENDIF.
        DELETE rt_sources WHERE table_line NP '*=CU'
                                AND table_line NP '*=CO'
                                AND table_line NP '*=CI'
                                AND table_line NP '*=CM+++'.
      WHEN OTHERS.
        zcx_ai_error=>raise( |Unknown object type: { mv_object_type }| ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
