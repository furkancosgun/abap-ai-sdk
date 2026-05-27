CLASS zcl_ai_activate_tool DEFINITION
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


CLASS zcl_ai_activate_tool IMPLEMENTATION.
  METHOD constructor.
    mv_object_type = iv_object_type.
    mv_object_name = iv_object_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lt_objects TYPE STANDARD TABLE OF dwinactiv WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_result,
        activated TYPE i,
        message   TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.
    DATA lv_json   TYPE string.

    SELECT object, obj_name FROM dwinactiv
      WHERE (    object  = @mv_object_type
              OR object IN ( SELECT e071 FROM euobjedit WHERE tadir = @mv_object_type ) )
        AND obj_name = @mv_object_name
      ORDER BY PRIMARY KEY
      INTO CORRESPONDING FIELDS OF TABLE @lt_objects.
    IF sy-subrc <> 0.
      ls_result = VALUE #( message = 'No inactive objects found.' ).
      lv_json = zcl_ai_serializer=>serialize( iv_data = ls_result
                                              iv_mode = zcl_ai_serializer=>mc_pretty_mode-camel_case ).
      rv_result = lv_json.
      RETURN.
    ENDIF.

    CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
      TABLES objects    = lt_objects
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    ls_result = VALUE #( activated = lines( lt_objects )
                         message   = |{ lines( lt_objects ) } object(s) activated.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'activate_object'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Activates inactive ABAP objects (class, program, function group, etc.) by type and name.'.
  ENDMETHOD.
ENDCLASS.
