CLASS zcl_ai_tool_registry DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool_registry.

  PRIVATE SECTION.
    DATA mt_defs TYPE zif_ai_tool=>ty_t_tool_def.

    METHODS build_binding_table
      IMPORTING io_class       TYPE REF TO cl_abap_classdescr
                it_params      TYPE abap_parmdescr_tab
                iv_input       TYPE any
      RETURNING VALUE(rt_bind) TYPE abap_parmbind_tab.
ENDCLASS.


CLASS zcl_ai_tool_registry IMPLEMENTATION.
  METHOD zif_ai_tool_registry~add.
    DATA lv_name   TYPE string.
    DATA lv_desc   TYPE string.
    DATA ls_schema TYPE zif_ai_tool=>ty_s_schema.

    ls_schema = zcl_ai_tool_schema=>resolve( iv_class_name ).

    CALL METHOD (iv_class_name)=>('ZIF_AI_TOOL~GET_NAME')
      RECEIVING rv_name = lv_name.

    CALL METHOD (iv_class_name)=>('ZIF_AI_TOOL~GET_DESCRIPTION')
      RECEIVING rv_description = lv_desc.

    INSERT VALUE #( name        = lv_name
                    class_name  = iv_class_name
                    description = lv_desc
                    schema      = ls_schema )
           INTO TABLE mt_defs.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise( |Registry Error: Tool '{ lv_name }' is already registered in the registry.| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_ai_tool_registry~add_all.
    FIELD-SYMBOLS <fs_class> LIKE LINE OF it_class_names.

    LOOP AT it_class_names ASSIGNING <fs_class>.
      zif_ai_tool_registry~add( <fs_class> ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ai_tool_registry~remove.
    DELETE mt_defs WHERE name = iv_name.
  ENDMETHOD.

  METHOD zif_ai_tool_registry~get.
    DATA lo_descr  TYPE REF TO cl_abap_classdescr.
    DATA lt_params TYPE abap_parmdescr_tab.
    DATA lt_bind   TYPE abap_parmbind_tab.
    FIELD-SYMBOLS <fs_def>    TYPE zif_ai_tool=>ty_s_tool_def.
    FIELD-SYMBOLS <fs_method> TYPE abap_methdescr.

    ASSIGN mt_defs[ name = iv_name ] TO <fs_def>.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise( |Registry Error: Tool '{ iv_name }' could not be found in the registry.| ).
    ENDIF.

    lo_descr ?= cl_abap_typedescr=>describe_by_name( <fs_def>-class_name ).

    ASSIGN lo_descr->methods[ name = 'CONSTRUCTOR' ] TO <fs_method>.
    IF sy-subrc = 0.
      lt_params = <fs_method>-parameters.
    ENDIF.

    IF lt_params IS NOT INITIAL.
      lt_bind = build_binding_table( io_class  = lo_descr
                                     it_params = lt_params
                                     iv_input  = iv_input ).
    ENDIF.

    IF lt_bind IS INITIAL.
      CREATE OBJECT ro_tool TYPE (<fs_def>-class_name).
    ELSE.
      CREATE OBJECT ro_tool TYPE (<fs_def>-class_name)
        PARAMETER-TABLE lt_bind.
    ENDIF.
  ENDMETHOD.

  METHOD zif_ai_tool_registry~has.
    rv_have = xsdbool( line_exists( mt_defs[ name = iv_name ] ) ).
  ENDMETHOD.

  METHOD zif_ai_tool_registry~size.
    rv_size = lines( mt_defs ).
  ENDMETHOD.

  METHOD zif_ai_tool_registry~clear.
    CLEAR mt_defs.
  ENDMETHOD.

  METHOD zif_ai_tool_registry~get_all_definitions.
    rt_defs = mt_defs.
  ENDMETHOD.

  METHOD build_binding_table.
    DATA lr_data      TYPE REF TO data.
    DATA lt_component TYPE cl_abap_structdescr=>component_table.
    DATA lo_struct    TYPE REF TO cl_abap_structdescr.
    DATA lo_type      TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <fs_data>  TYPE any.
    FIELD-SYMBOLS <fs_param> TYPE abap_parmdescr.

    LOOP AT it_params ASSIGNING <fs_param>.
      lo_type = io_class->get_method_parameter_type( p_method_name    = 'CONSTRUCTOR'
                                                     p_parameter_name = <fs_param>-name ).
      APPEND VALUE #( name = <fs_param>-name
                      type = CAST #( lo_type ) )
             TO lt_component.
    ENDLOOP.

    lo_struct = cl_abap_structdescr=>create( lt_component ).
    CREATE DATA lr_data TYPE HANDLE lo_struct.
    ASSIGN lr_data->* TO <fs_data>.

    zcl_ai_serializer=>cast( EXPORTING iv_data = iv_input
                             IMPORTING ev_data = <fs_data> ).

    LOOP AT it_params ASSIGNING <fs_param>.
      ASSIGN COMPONENT <fs_param>-name OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_val>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name  = <fs_param>-name
                      kind  = cl_abap_objectdescr=>exporting
                      value = REF #( <fs_val> ) ) INTO TABLE rt_bind.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
