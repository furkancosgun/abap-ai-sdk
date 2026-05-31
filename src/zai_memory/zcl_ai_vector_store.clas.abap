CLASS zcl_ai_vector_store DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_chunk,
        id     TYPE string,
        text   TYPE string,
        vector TYPE zif_ai_embedding=>ty_t_vector,
      END OF ty_s_chunk.
    TYPES ty_t_chunks TYPE STANDARD TABLE OF ty_s_chunk WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_result,
        id    TYPE string,
        text  TYPE string,
        score TYPE f,
      END OF ty_s_result.
    TYPES ty_t_results TYPE STANDARD TABLE OF ty_s_result WITH EMPTY KEY.

    METHODS constructor
      IMPORTING io_embedding TYPE REF TO zif_ai_embedding.

    METHODS add
      IMPORTING iv_text   TYPE string
                it_vector TYPE zif_ai_embedding=>ty_t_vector OPTIONAL
      RAISING   zcx_ai_error.

    METHODS search
      IMPORTING iv_query          TYPE string
                iv_top_k          TYPE i DEFAULT 5
      RETURNING VALUE(rv_context) TYPE string
      RAISING   zcx_ai_error.

    METHODS clear.

    METHODS size
      RETURNING VALUE(rv_size) TYPE i.

  PRIVATE SECTION.
    DATA mo_embedding TYPE REF TO zif_ai_embedding.
    DATA mt_chunks    TYPE ty_t_chunks.

    METHODS cosine_similarity
      IMPORTING it_vector_a     TYPE zif_ai_embedding=>ty_t_vector
                it_vector_b     TYPE zif_ai_embedding=>ty_t_vector
      RETURNING VALUE(rv_score) TYPE f.
ENDCLASS.


CLASS zcl_ai_vector_store IMPLEMENTATION.
  METHOD constructor.
    mo_embedding = io_embedding.
  ENDMETHOD.

  METHOD add.
    DATA ls_chunk TYPE ty_s_chunk.

    ls_chunk-text = iv_text.
    IF it_vector IS NOT INITIAL.
      ls_chunk-vector = it_vector.
    ELSE.
      ls_chunk-vector = mo_embedding->embed( iv_text ).
    ENDIF.
    APPEND ls_chunk TO mt_chunks.
  ENDMETHOD.

  METHOD search.
    DATA lt_query_vec TYPE zif_ai_embedding=>ty_t_vector.
    DATA ls_result    TYPE ty_s_result.
    DATA lt_results   TYPE ty_t_results.
    FIELD-SYMBOLS <fs_chunk> LIKE LINE OF mt_chunks.

    lt_query_vec = mo_embedding->embed( iv_query ).

    LOOP AT mt_chunks ASSIGNING <fs_chunk>.
      ls_result-text  = <fs_chunk>-text.
      ls_result-score = cosine_similarity( it_vector_a = lt_query_vec
                                           it_vector_b = <fs_chunk>-vector ).
      APPEND ls_result TO lt_results.
    ENDLOOP.

    SORT lt_results BY score DESCENDING.

    LOOP AT lt_results INTO ls_result TO iv_top_k.
      IF rv_context IS NOT INITIAL.
        rv_context = |{ rv_context }\n\n---\n|.
      ENDIF.
      rv_context = |{ rv_context }{ ls_result-text }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_chunks.
  ENDMETHOD.

  METHOD size.
    rv_size = lines( mt_chunks ).
  ENDMETHOD.

  METHOD cosine_similarity.
    DATA lv_dot    TYPE f VALUE 0.
    DATA lv_norm_a TYPE f VALUE 0.
    DATA lv_norm_b TYPE f VALUE 0.

    FIELD-SYMBOLS <fs_a> LIKE LINE OF it_vector_a.
    FIELD-SYMBOLS <fs_b> LIKE LINE OF it_vector_b.

    IF lines( it_vector_b ) <> lines( it_vector_a ).
      rv_score = 0.
      RETURN.
    ENDIF.

    LOOP AT it_vector_a ASSIGNING <fs_a>.
      ASSIGN it_vector_b[ sy-tabix ] TO <fs_b>.
      IF sy-subrc = 0.
        lv_dot    = lv_dot + ( <fs_a> * <fs_b> ).
        lv_norm_a = lv_norm_a + ( <fs_a> ** 2 ).
        lv_norm_b = lv_norm_b + ( <fs_b> ** 2 ).
      ENDIF.
    ENDLOOP.

    IF lv_norm_a = 0 OR lv_norm_b = 0.
      rv_score = 0.
      RETURN.
    ENDIF.

    rv_score = lv_dot / ( sqrt( lv_norm_a ) * sqrt( lv_norm_b ) ).
  ENDMETHOD.
ENDCLASS.
