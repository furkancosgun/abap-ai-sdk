CLASS zcl_ai_commit_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.

    METHODS constructor
      IMPORTING iv_wait TYPE abap_bool DEFAULT abap_true.

  PRIVATE SECTION.
    DATA mv_wait TYPE abap_bool.
ENDCLASS.


CLASS zcl_ai_commit_tool IMPLEMENTATION.
  METHOD constructor.
    mv_wait = iv_wait.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        message TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = mv_wait.

    ls_result = VALUE #( message = 'Transaction committed successfully.' ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'transaction_commit'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Commits the current SAP LUW (logical unit of work) transaction.'.
  ENDMETHOD.
ENDCLASS.
