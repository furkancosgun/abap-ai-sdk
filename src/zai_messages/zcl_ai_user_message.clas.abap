CLASS zcl_ai_user_message DEFINITION
  PUBLIC
  INHERITING FROM zcl_ai_message FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_content TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_ai_user_message IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_role    = 'user'
                        iv_name    = ''
                        iv_content = iv_content ).
  ENDMETHOD.
ENDCLASS.
