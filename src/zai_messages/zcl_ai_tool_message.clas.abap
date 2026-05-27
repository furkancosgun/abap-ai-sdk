CLASS zcl_ai_tool_message DEFINITION
  PUBLIC
  INHERITING FROM zcl_ai_message FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_id     TYPE string
                iv_name   TYPE string
                iv_result TYPE any.

    METHODS get_id
      RETURNING VALUE(rv_id) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA mv_id TYPE string.

ENDCLASS.


CLASS zcl_ai_tool_message IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_role    = 'tool'
                        iv_name    = iv_name
                        iv_content = zcl_ai_serializer=>serialize( iv_data = iv_result ) ).
    mv_id = iv_id.
  ENDMETHOD.

  METHOD get_id.
    rv_id = mv_id.
  ENDMETHOD.
ENDCLASS.
