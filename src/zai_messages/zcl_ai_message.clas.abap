CLASS zcl_ai_message DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_messages TYPE STANDARD TABLE OF REF TO zcl_ai_message WITH EMPTY KEY.

    METHODS constructor
      IMPORTING iv_role    TYPE string
                iv_name    TYPE string
                iv_content TYPE string.

    METHODS get_role
      RETURNING VALUE(rv_role) TYPE string.

    METHODS get_name
      RETURNING VALUE(rv_name) TYPE string.

    METHODS get_content
      RETURNING VALUE(rv_content) TYPE string.

    METHODS set_content
      IMPORTING iv_content TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA mv_role    TYPE string.
    DATA mv_name    TYPE string.
    DATA mv_content TYPE string.
ENDCLASS.


CLASS zcl_ai_message IMPLEMENTATION.
  METHOD constructor.
    mv_role = iv_role.
    mv_name = iv_name.
    mv_content = iv_content.
  ENDMETHOD.

  METHOD get_content.
    rv_content = mv_content.
  ENDMETHOD.

  METHOD set_content.
    mv_content = iv_content.
  ENDMETHOD.

  METHOD get_name.
    rv_name = mv_name.
  ENDMETHOD.

  METHOD get_role.
    rv_role = mv_role.
  ENDMETHOD.
ENDCLASS.
