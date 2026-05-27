CLASS zcl_ai_rollback_tool DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ai_tool.
ENDCLASS.


CLASS zcl_ai_rollback_tool IMPLEMENTATION.
  METHOD zif_ai_tool~execute.
    TYPES:
      BEGIN OF ty_result,
        message TYPE string,
      END OF ty_result.
    DATA ls_result TYPE ty_result.

    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

    ls_result = VALUE #( message = 'Transaction rolled back successfully.' ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'transaction_rollback'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Rolls back the current SAP LUW (logical unit of work) transaction.'.
  ENDMETHOD.
ENDCLASS.
