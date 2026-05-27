CLASS zcl_ai_tool_schema DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS resolve
      IMPORTING iv_class_name    TYPE string
      RETURNING VALUE(rs_schema) TYPE zif_ai_tool=>ty_s_schema
      RAISING   zcx_ai_error.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_prop,
        type        TYPE string,
        description TYPE string,
        properties  TYPE REF TO data,
        items       TYPE REF TO data,
      END OF ty_s_prop.
    TYPES:
      BEGIN OF ty_s_param,
        name        TYPE string,
        type        TYPE string,
        description TYPE string,
        properties  TYPE REF TO data,
        items       TYPE REF TO data,
        required    TYPE abap_bool,
      END OF ty_s_param.
    TYPES ty_t_params TYPE STANDARD TABLE OF ty_s_param WITH EMPTY KEY.

    CONSTANTS:
      BEGIN OF mc_types,
        string  TYPE string VALUE 'string',
        number  TYPE string VALUE 'number',
        integer TYPE string VALUE 'integer',
        boolean TYPE string VALUE 'boolean',
        object  TYPE string VALUE 'object',
        array   TYPE string VALUE 'array',
      END OF mc_types.

    CLASS-METHODS build_param
      IMPORTING iv_name  TYPE clike
                io_type  TYPE REF TO cl_abap_typedescr
      CHANGING  cs_param TYPE ty_s_param
      RAISING   zcx_ai_error.

    CLASS-METHODS build_elem
      IMPORTING iv_name  TYPE clike
                io_elem  TYPE REF TO cl_abap_elemdescr
      CHANGING  cs_param TYPE ty_s_param
      RAISING   zcx_ai_error.

    CLASS-METHODS build_struct
      IMPORTING iv_name   TYPE clike
                io_struct TYPE REF TO cl_abap_structdescr
      CHANGING  cs_param  TYPE ty_s_param
      RAISING   zcx_ai_error.

    CLASS-METHODS build_table
      IMPORTING iv_name  TYPE clike
                io_table TYPE REF TO cl_abap_tabledescr
      CHANGING  cs_param TYPE ty_s_param
      RAISING   zcx_ai_error.

    CLASS-METHODS map_params
      IMPORTING it_params      TYPE ty_t_params
      RETURNING VALUE(rr_data) TYPE REF TO data.
ENDCLASS.


CLASS zcl_ai_tool_schema IMPLEMENTATION.
  METHOD resolve.
    DATA lo_typer  TYPE REF TO cl_abap_typedescr.
    DATA lo_descr  TYPE REF TO cl_abap_classdescr.
    DATA lo_type   TYPE REF TO cl_abap_typedescr.
    DATA lt_params TYPE ty_t_params.
    FIELD-SYMBOLS <fs_method> TYPE abap_methdescr.
    FIELD-SYMBOLS <fs_param>  TYPE abap_parmdescr.
    FIELD-SYMBOLS <fs_item>   TYPE ty_s_param.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name     = iv_class_name
                                         RECEIVING p_descr_ref = lo_typer
                                         EXCEPTIONS OTHERS     = 1 ).
    IF sy-subrc <> 0 OR lo_typer->kind <> cl_abap_typedescr=>kind_class.
      zcx_ai_error=>raise(
          |Metadata Resolution Error: Class '{ iv_class_name }' could not be found or is not a valid class.| ).
    ENDIF.

    lo_descr ?= lo_typer.

    IF NOT lo_descr->is_instantiatable( ).
      zcx_ai_error=>raise( |Validation Error: Class '{ iv_class_name }' is abstract or cannot be instantiated.| ).
    ENDIF.

    IF NOT line_exists( lo_descr->interfaces[ name = 'ZIF_AI_TOOL' ] ).
      zcx_ai_error=>raise( |Interface Error: Class '{ iv_class_name }' must implement 'ZIF_AI_TOOL' interface.| ).
    ENDIF.

    ASSIGN lo_descr->methods[ name = 'CONSTRUCTOR' ] TO <fs_method>.
    IF sy-subrc <> 0.
      rs_schema-type = mc_types-object.
      RETURN.
    ENDIF.

    LOOP AT <fs_method>-parameters ASSIGNING <fs_param>.
      IF <fs_param>-parm_kind <> cl_abap_classdescr=>importing.
        zcx_ai_error=>raise(
            |Architecture Error: Constructor parameter '{ <fs_param>-name }' must be an IMPORTING parameter.| ).
      ENDIF.

      lo_type = lo_descr->get_method_parameter_type( p_method_name    = 'CONSTRUCTOR'
                                                     p_parameter_name = <fs_param>-name ).

      APPEND INITIAL LINE TO lt_params ASSIGNING <fs_item>.
      build_param( EXPORTING iv_name  = <fs_param>-name
                             io_type  = lo_type
                   CHANGING  cs_param = <fs_item> ).
      <fs_item>-required = xsdbool( <fs_param>-is_optional = abap_false ).
    ENDLOOP.

    rs_schema-type       = mc_types-object.
    rs_schema-properties = map_params( lt_params ).
    rs_schema-required   = VALUE #( FOR p IN lt_params WHERE ( required = abap_true )
                                    ( p-name ) ).
  ENDMETHOD.

  METHOD build_param.
    DATA lo_elem   TYPE REF TO cl_abap_elemdescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lo_table  TYPE REF TO cl_abap_tabledescr.

    cs_param-name = iv_name.
    CASE io_type->kind.
      WHEN cl_abap_typedescr=>kind_elem.
        lo_elem ?= io_type.
        build_elem( EXPORTING iv_name  = iv_name
                              io_elem  = lo_elem
                    CHANGING  cs_param = cs_param ).
      WHEN cl_abap_typedescr=>kind_struct.
        lo_struct ?= io_type.
        build_struct( EXPORTING iv_name   = iv_name
                                io_struct = lo_struct
                      CHANGING  cs_param  = cs_param ).
      WHEN cl_abap_typedescr=>kind_table.
        lo_table ?= io_type.
        build_table( EXPORTING iv_name  = iv_name
                               io_table = lo_table
                     CHANGING  cs_param = cs_param ).
      WHEN OTHERS.
        zcx_ai_error=>raise( |Type Error: Parameter '{ iv_name }' has an unsupported ABAP Type Kind.| ).
    ENDCASE.
  ENDMETHOD.

  METHOD build_elem.
    DATA ls_dfies TYPE dfies.

    io_elem->get_ddic_field( RECEIVING p_flddescr = ls_dfies
                             EXCEPTIONS OTHERS    = 1 ).
    IF sy-subrc = 0.
      cs_param-description = ls_dfies-scrtext_m.
    ELSE.
      cs_param-description = |Parameter { iv_name }|.
    ENDIF.
    CASE io_elem->type_kind.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2.
        cs_param-type = mc_types-integer.
      WHEN cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_packed.
        cs_param-type = mc_types-number.
      WHEN cl_abap_typedescr=>typekind_char
          OR cl_abap_typedescr=>typekind_string.
        IF io_elem->length = 1 AND (    io_elem->absolute_name CS 'ABAP_BOOL'
                                     OR io_elem->absolute_name CS 'BOOLEAN' ).
          cs_param-type = mc_types-boolean.
        ELSE.
          cs_param-type = mc_types-string.
        ENDIF.
      WHEN OTHERS.
        cs_param-type = mc_types-string.
    ENDCASE.
  ENDMETHOD.

  METHOD build_struct.
    DATA lo_comp TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <fs_sub>        TYPE ty_s_param.
    FIELD-SYMBOLS <fs_comp>       TYPE abap_compdescr.
    FIELD-SYMBOLS <fs_sub_params> TYPE ty_t_params.

    cs_param-description = |{ iv_name }|.
    cs_param-type        = mc_types-object.
    CREATE DATA cs_param-properties TYPE ty_t_params.
    ASSIGN cs_param-properties->* TO <fs_sub_params>.

    LOOP AT io_struct->components ASSIGNING <fs_comp>.
      lo_comp = io_struct->get_component_type( <fs_comp>-name ).
      APPEND INITIAL LINE TO <fs_sub_params> ASSIGNING <fs_sub>.
      build_param( EXPORTING iv_name  = <fs_comp>-name
                             io_type  = lo_comp
                   CHANGING  cs_param = <fs_sub> ).
    ENDLOOP.
  ENDMETHOD.

  METHOD build_table.
    DATA lo_line   TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lo_elem   TYPE REF TO cl_abap_elemdescr.
    FIELD-SYMBOLS <fs_sub> TYPE ty_s_param.

    cs_param-description = |{ iv_name }|.
    cs_param-type        = mc_types-array.
    CREATE DATA cs_param-items TYPE ty_s_param.
    ASSIGN cs_param-items->* TO <fs_sub>.

    lo_line = io_table->get_table_line_type( ).

    IF lo_line->kind = cl_abap_typedescr=>kind_struct.
      lo_struct ?= lo_line.
      build_struct( EXPORTING iv_name   = ''
                              io_struct = lo_struct
                    CHANGING  cs_param  = <fs_sub> ).
      RETURN.
    ENDIF.

    IF lo_line->kind = cl_abap_typedescr=>kind_elem.
      lo_elem ?= lo_line.
      build_elem( EXPORTING iv_name  = ''
                            io_elem  = lo_elem
                  CHANGING  cs_param = <fs_sub> ).
      RETURN.
    ENDIF.
    zcx_ai_error=>raise( 'Unsupported type.' ).
  ENDMETHOD.

  METHOD map_params.
    FIELD-SYMBOLS <fs_data>       TYPE any.
    FIELD-SYMBOLS <fs_field>      TYPE ty_s_prop.
    FIELD-SYMBOLS <fs_props>      TYPE STANDARD TABLE.
    FIELD-SYMBOLS <fs_p>          TYPE ty_s_param.
    FIELD-SYMBOLS <fs_sub_param>  TYPE ty_s_param.
    FIELD-SYMBOLS <fs_final_item> TYPE ty_s_prop.
    FIELD-SYMBOLS <fs_flat_final> TYPE ty_s_prop.

    DATA lr_stru            TYPE REF TO cl_abap_structdescr.
    DATA lr_sub_item_schema TYPE REF TO ty_s_prop.
    DATA lr_flat_item       TYPE REF TO ty_s_prop.
    DATA lt_comp            TYPE cl_abap_structdescr=>component_table.
    DATA ls_body            TYPE ty_s_prop.
    DATA ls_comp            TYPE cl_abap_structdescr=>component.

    IF it_params IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_params ASSIGNING <fs_p>.
      ls_comp-name = <fs_p>-name.
      ls_comp-type = CAST #( cl_abap_typedescr=>describe_by_data( ls_body ) ).
      APPEND ls_comp TO lt_comp.
    ENDLOOP.

    lr_stru = cl_abap_structdescr=>create( lt_comp ).
    CREATE DATA rr_data TYPE HANDLE lr_stru.
    ASSIGN rr_data->* TO <fs_data>.

    LOOP AT it_params ASSIGNING <fs_p>.
      ASSIGN COMPONENT <fs_p>-name OF STRUCTURE <fs_data> TO <fs_field>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      <fs_field>-type        = <fs_p>-type.
      <fs_field>-description = <fs_p>-description.

      IF <fs_p>-properties IS NOT INITIAL.
        ASSIGN <fs_p>-properties->* TO <fs_props>.
        <fs_field>-properties = map_params( <fs_props> ).
      ENDIF.

      IF <fs_p>-items IS INITIAL.
        CONTINUE.
      ENDIF.

      ASSIGN <fs_p>-items->* TO <fs_sub_param>.
      IF <fs_sub_param>-properties IS NOT INITIAL.
        CREATE DATA lr_sub_item_schema.
        lr_sub_item_schema->type        = <fs_sub_param>-type.
        lr_sub_item_schema->description = <fs_sub_param>-description.

        ASSIGN <fs_sub_param>-properties->* TO <fs_props>.
        lr_sub_item_schema->properties = map_params( <fs_props> ).

        CREATE DATA <fs_field>-items TYPE ty_s_prop.
        ASSIGN <fs_field>-items->* TO <fs_final_item>.
        <fs_final_item> = lr_sub_item_schema->*.
      ELSE.
        CREATE DATA lr_flat_item.
        lr_flat_item->type        = <fs_sub_param>-type.
        lr_flat_item->description = <fs_sub_param>-description.

        CREATE DATA <fs_field>-items TYPE ty_s_prop.
        ASSIGN <fs_field>-items->* TO <fs_flat_final>.
        <fs_flat_final> = lr_flat_item->*.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
