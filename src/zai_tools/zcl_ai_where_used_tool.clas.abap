CLASS zcl_ai_where_used_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_object_type TYPE tadir-object
                iv_object_name TYPE tadir-obj_name.

  PRIVATE SECTION.
    DATA mv_object_type TYPE string.
    DATA mv_object_name TYPE string.
ENDCLASS.


CLASS zcl_ai_where_used_tool IMPLEMENTATION.
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
    TYPES ty_t_result TYPE STANDARD TABLE OF ty_s_result WITH KEY object_type object_name.
    DATA lt_result      TYPE ty_t_result.
    DATA lt_findstrings TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_found       TYPE STANDARD TABLE OF rsfindlst WITH EMPTY KEY.
    DATA lt_euobjedit   TYPE STANDARD TABLE OF euobjedit WITH EMPTY KEY.

    lt_findstrings = VALUE #( ( mv_object_name ) ).

    CALL FUNCTION 'RS_EU_CROSSREF'
      EXPORTING  i_find_obj_cls = CONV euobj-id( mv_object_type )
                 no_dialog      = abap_true
                 without_text   = abap_true
      TABLES i_findstrings      = lt_findstrings
                 o_founds       = lt_found
      EXCEPTIONS OTHERS         = 1.
    IF sy-subrc <> 0.
      zcx_ai_error=>raise_syst( ).
    ENDIF.

    IF lt_found IS INITIAL.
      zcx_ai_error=>raise( 'Not found anywhere.' ).
    ENDIF.

    SELECT type,
           tadir,
           conttype
      FROM euobjedit
      FOR ALL ENTRIES IN @lt_found
      WHERE type   = @lt_found-object_cls(3)
        AND tadir <> ''
      ORDER BY PRIMARY KEY
      INTO TABLE @lt_euobjedit.

    IF sy-subrc <> 0.
      zcx_ai_error=>raise( 'No references found.' ).
    ENDIF.

    LOOP AT lt_found ASSIGNING FIELD-SYMBOL(<fs_found>).
      ASSIGN lt_euobjedit[ type = <fs_found>-object_cls ] TO FIELD-SYMBOL(<fs_euobjedit>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      COLLECT VALUE ty_s_result( object_type = <fs_euobjedit>-tadir
                                 object_name = COND #( WHEN <fs_euobjedit>-conttype IS INITIAL
                                                       THEN <fs_found>-object
                                                       ELSE <fs_found>-encl_objec ) )
              INTO lt_result.
    ENDLOOP.

    rv_result = zcl_ai_serializer=>serialize( lt_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'where_used'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Finds where an ABAP object (class, program, table, etc.) is used in the system.'.
  ENDMETHOD.
ENDCLASS.
