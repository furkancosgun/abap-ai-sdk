CLASS zcl_ai_inactive_objects_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_object_type TYPE tadir-object   OPTIONAL
                iv_object_name TYPE tadir-obj_name OPTIONAL.

  PRIVATE SECTION.
    DATA mv_object_type TYPE tadir-object.
    DATA mv_object_name TYPE tadir-obj_name.
ENDCLASS.


CLASS zcl_ai_inactive_objects_tool IMPLEMENTATION.
  METHOD constructor.
    mv_object_type = iv_object_type.
    mv_object_name = iv_object_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_s_inactive,
        uname       TYPE string,
        object_type TYPE string,
        object_name TYPE string,
      END OF ty_s_inactive.
    TYPES ty_t_inactive TYPE STANDARD TABLE OF ty_s_inactive WITH EMPTY KEY.
    DATA lr_object_type TYPE RANGE OF dwinactiv-object.
    DATA lr_object_name TYPE RANGE OF dwinactiv-obj_name.
    DATA lt_objects     TYPE ty_t_inactive.

    IF mv_object_type IS NOT INITIAL.
      lr_object_type = VALUE #( ( sign = 'I' option = 'EQ' low = mv_object_type ) ).
    ENDIF.

    IF mv_object_name IS NOT INITIAL.
      lr_object_name = VALUE #( ( sign = 'I' option = 'EQ' low = mv_object_name ) ).
    ENDIF.

    SELECT uname, object, obj_name FROM dwinactiv
      WHERE object   IN @lr_object_type
        AND obj_name IN @lr_object_name
      ORDER BY PRIMARY KEY
      INTO TABLE @lt_objects.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise( |No inactive objects found.| ).
    ENDIF.

    rv_result = zcl_ai_serializer=>serialize( lt_objects ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'find_inactive_objects'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Finds inactive ABAP objects, optionally filtered by object type and name.'.
  ENDMETHOD.
ENDCLASS.
