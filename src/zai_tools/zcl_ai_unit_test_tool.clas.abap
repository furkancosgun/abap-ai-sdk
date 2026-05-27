CLASS zcl_ai_unit_test_tool DEFINITION
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

    TYPES:
      BEGIN OF ty_result,
        object_type  TYPE tadir-object,
        object_name  TYPE tadir-obj_name,
        is_success   TYPE abap_bool,
        failed_count TYPE i,
      END OF ty_result.
ENDCLASS.


CLASS zcl_ai_unit_test_tool IMPLEMENTATION.
  METHOD constructor.
    mv_object_type = iv_object_type.
    mv_object_name = iv_object_name.
  ENDMETHOD.

  METHOD zif_ai_tool~execute.
    DATA lo_listener TYPE REF TO if_saunit_internal_listener.
    DATA lo_factory  TYPE REF TO cl_aunit_factory.
    DATA lo_task     TYPE REF TO if_aunit_task.
    DATA lo_result   TYPE REF TO cl_saunit_internal_result.
    DATA ls_result   TYPE ty_result.

    lo_listener = cl_saunit_gui_service=>create_listener( ).
    lo_factory = NEW cl_aunit_factory( ).
    lo_task = lo_factory->create_task( lo_listener ).

    CASE mv_object_type.
      WHEN 'CLAS'.
        lo_task->add_class_pool( mv_object_name ).
      WHEN 'PROG'.
        lo_task->add_program( mv_object_name ).
      WHEN 'FUGR'.
        lo_task->add_function_group( mv_object_name ).
      WHEN OTHERS.
        zcx_ai_error=>raise( |Unknown object type: { mv_object_type }| ).
    ENDCASE.

    lo_task->run( if_aunit_task=>c_run_mode-external ).
    lo_result ?= lo_listener->get_result_after_end_of_task( ).

    LOOP AT lo_result->f_task_data-alerts_by_indicies
         ASSIGNING FIELD-SYMBOL(<fs_alert>)
         WHERE class_ndx > 0 OR method_ndx > 0 OR program_ndx > 0.
      ls_result-failed_count = ls_result-failed_count + lines( <fs_alert>-alerts ).
    ENDLOOP.

    ls_result-object_type = mv_object_type.
    ls_result-object_name = mv_object_name.
    ls_result-is_success  = xsdbool( ls_result-failed_count = 0 ).

    rv_result = zcl_ai_serializer=>serialize( ls_result ).
  ENDMETHOD.

  METHOD zif_ai_tool~get_name.
    rv_name = 'run_unit_tests'.
  ENDMETHOD.

  METHOD zif_ai_tool~get_description.
    rv_description = 'Runs ABAP unit tests (AUNIT) for a given object type and name, returns pass/fail result.'.
  ENDMETHOD.
ENDCLASS.
