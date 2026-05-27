CLASS zcl_ai_dependencies_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_object_type TYPE tadir-object
                iv_object_name TYPE tadir-obj_name.

  PRIVATE SECTION.
    DATA mv_object_type TYPE tadir-object.
    DATA mv_object_name TYPE tadir-obj_name.
ENDCLASS.


CLASS zcl_ai_dependencies_tool IMPLEMENTATION.
  METHOD constructor.
    mv_object_type = iv_object_type.
    mv_object_name = iv_object_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_s_result,
        object_type TYPE string,
        object_name TYPE string,
      END OF ty_s_result.
    TYPES ty_t_result TYPE STANDARD TABLE OF ty_s_result WITH KEY object_name object_type.
    DATA lt_senvi    TYPE senvi_tab.
    DATA lv_obj_type TYPE euobj-id.
    DATA lv_obj_name TYPE tadir-obj_name.
    DATA lt_tadir    TYPE if_ris_environment_types=>ty_t_senvi_tadir.
    DATA lt_result   TYPE ty_t_result.
    DATA lv_json     TYPE string.

    lv_obj_type = mv_object_type.
    lv_obj_name = mv_object_name.

    CALL FUNCTION 'REPOSITORY_ENVIRONMENT_ALL'
      EXPORTING  obj_type    = lv_obj_type
                 object_name = lv_obj_name
                 deep        = '1'
      TABLES environment_tab = lt_senvi
      EXCEPTIONS OTHERS      = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    cl_wb_ris_environment=>convert_senvi_to_tadir( EXPORTING senvi       = lt_senvi
                                                   IMPORTING senvi_tadir = lt_tadir ).

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<fs_tadir>).
      COLLECT VALUE ty_s_result( object_type = <fs_tadir>-ref_obj_type
                                 object_name = <fs_tadir>-ref_obj_name ) INTO lt_result.
      COLLECT VALUE ty_s_result( object_type = <fs_tadir>-obj_type
                                 object_name = <fs_tadir>-obj_name ) INTO lt_result.
    ENDLOOP.

    lv_json = zcl_ai_serializer=>serialize( iv_data = lt_result
                                            iv_mode = zcl_ai_serializer=>mc_pretty_mode-camel_case ).
    rv_result = lv_json.
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'get_dependencies'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Returns all dependencies (where-used) of an ABAP object by type and name.'.
  ENDMETHOD.
ENDCLASS.
