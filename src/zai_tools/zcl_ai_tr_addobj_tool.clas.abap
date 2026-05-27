CLASS zcl_ai_tr_addobj_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_trkorr      TYPE e071-trkorr
                iv_object_clas TYPE e071-pgmid
                iv_object_type TYPE e071-object
                iv_object_name TYPE e071-obj_name.

  PRIVATE SECTION.
    DATA mv_trkorr      TYPE e071-trkorr.
    DATA mv_object_clas TYPE e071-pgmid.
    DATA mv_object_type TYPE e071-object.
    DATA mv_object_name TYPE e071-obj_name.
ENDCLASS.


CLASS zcl_ai_tr_addobj_tool IMPLEMENTATION.
  METHOD constructor.
    mv_trkorr      = iv_trkorr.
    mv_object_clas = iv_object_clas.
    mv_object_type = iv_object_type.
    mv_object_name = iv_object_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        trkorr      TYPE string,
        object_type TYPE string,
        object_name TYPE string,
        message     TYPE string,
      END OF ty_result.
    DATA ls_result  TYPE ty_result.
    DATA lt_objects TYPE tr_objects.

    lt_objects = VALUE #( ( pgmid    = mv_object_clas
                            object   = mv_object_type
                            obj_name = mv_object_name ) ).

    CALL FUNCTION 'TR_REQUEST_CHOICE'
      EXPORTING  iv_request = mv_trkorr
      TABLES it_e071        = lt_objects
      EXCEPTIONS OTHERS     = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    ls_result = VALUE #( trkorr      = mv_trkorr
                         object_type = mv_object_type
                         object_name = mv_object_name
                         message     = |{ mv_object_type } { mv_object_name } added to { mv_trkorr }.| ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Adds an ABAP object to an existing transport request.'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'add_to_transport'.
  ENDMETHOD.
ENDCLASS.
