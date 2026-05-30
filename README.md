# ABAP AI SDK

ABAP framework for integrating Large Language Models (LLMs) into SAP systems. Supports OpenAI, Gemini, Anthropic (Claude), and Ollama with a pluggable tool system.

## Quick Start

```abap
DATA(lo_agent) = zcl_ai_agent_factory=>create_openai(
  iv_api_key = 'sk-...'
  iv_model   = 'gpt-4o' ).

DATA(lo_response) = lo_agent->execute( 'List all users in table USR01.' ).
```

## Architecture

```
zai_core         Interfaces (provider, tool, agent, memory, middleware, http_client)
zai_common       Shared utilities (serializer, error class)
zai_runtime      Agent, pipeline, context, middleware implementations
zai_memory       Memory store & strategies
zai_messages     Message types (system, user, assistant, tool)
zai_providers    LLM providers & HTTP client
zai_tools        Tool implementations
zai_tool_ext     Provider-specific tool formatters
```

## Providers

| Provider | Factory Method | Default Model |
|----------|---------------|---------------|
| OpenAI / Compatible | `create_openai` | `gpt-4o` |
| Google Gemini | `create_gemini` | `gemini-2.0-flash` |
| Anthropic Claude | `create_anthropic` | `claude-sonnet-4-20250514` |
| Ollama (local) | `create_ollama` | `llama3.2` |
| Default (Ollama) | `create_default` | `gemma4:latest` |

OpenAI-compatible provider also works with Mistral, DeepSeek, Groq — just pass the appropriate `base_url` and model.

## Tools

Tools are typed ABAP classes implementing `zif_ai_tool`. Each tool declares its parameters via constructor — schema is auto-generated via RTTI.

### Usage with tools

```abap
DATA(lo_agent) = zcl_ai_agent_factory=>create_openai(
  iv_api_key       = 'sk-...'
  iv_model         = 'gpt-4o'
  iv_system_prompt = 'You are an SAP assistant.'
  it_tools         = VALUE #( ( 'ZCL_AI_SQL_TOOL' )
                              ( 'ZCL_AI_SYSTEM_TOOL' ) ) ).
```

### Built-in Tools

**System & Development**

| Class | Tool Name | Parameters | Description |
|-------|-----------|------------|-------------|
| `zcl_ai_system_tool` | `get_system_info` | *(none)* | SAP system info (SID, client, release, user, date, time) |
| `zcl_ai_sql_tool` | `execute_sql` | `iv_query` | Dynamic SQL SELECT query execution |
| `zcl_ai_read_src_tool` | `read_source` | `iv_object_type`, `iv_object_name` | Read ABAP source code by type + name |
| `zcl_ai_table_def_tool` | `get_table_definition` | `iv_table_name` | Returns DDIC table field metadata via `DDIF_FIELDINFO_GET` |
| `zcl_ai_syntax_check_tool` | `syntax_check` | `iv_source`, `iv_program` | Validates ABAP source code syntax |
| `zcl_ai_where_used_tool` | `where_used` | `iv_object_type`, `iv_object_name` | Cross-reference search via `RS_EU_CROSSREF` |
| `zcl_ai_dependencies_tool` | `get_dependencies` | `iv_object_type`, `iv_object_name` | Returns object dependencies |
| `zcl_ai_unit_test_tool` | `run_unit_tests` | `iv_object_type`, `iv_object_name` | Run AUNIT unit tests |
| `zcl_ai_activate_tool` | `activate_object` | `iv_object_type`, `iv_object_name` | Activate inactive ABAP objects |
| `zcl_ai_inactive_objects_tool` | `find_inactive_objects` | `iv_object_type?`, `iv_object_name?` | Lists inactive objects from `DWINACTIV` |

**Transport Management**

| Class | Tool Name | Parameters | Description |
|-------|-----------|------------|-------------|
| `zcl_ai_tr_create_tool` | `create_transport` | `iv_description`, `iv_type` | Create transport request |
| `zcl_ai_tr_release_tool` | `release_transport` | `iv_trkorr` | Release transport request |
| `zcl_ai_tr_delete_tool` | `delete_transport` | `iv_trkorr` | Delete transport request |
| `zcl_ai_tr_copy_tool` | `copy_transport` | `iv_from_trkorr`, `iv_to_trkorr` | Copy transport request |
| `zcl_ai_tr_compress_tool` | `compress_transport` | `iv_trkorr` | Sort & compress transport |
| `zcl_ai_tr_addobj_tool` | `add_to_transport` | `iv_trkorr`, `iv_object_clas`, `iv_object_type`, `iv_object_name` | Add object to transport |
| `zcl_ai_tr_import_tool` | `import_transport_request` | `iv_trkorr` | Import transport request into system |

**Monitoring & Diagnostics**

| Class | Tool Name | Parameters | Description |
|-------|-----------|------------|-------------|
| `zcl_ai_short_dump_list_tool` | `list_short_dump` | `iv_max_count?` | Lists recent ST22 short dumps |
| `zcl_ai_short_dump_read_tool` | `read_short_dump` | `iv_snap_id` | Reads full details of a specific short dump |
| `zcl_ai_locked_objects_tool` | `get_locked_objects` | `iv_username?` | Lists system locks via `ENQUEUE_READ` |

**User & Communication**

| Class | Tool Name | Parameters | Description |
|-------|-----------|------------|-------------|
| `zcl_ai_user_detail_tool` | `get_user_detail` | `iv_username` | SAP user details via `BAPI_USER_GET_DETAIL` |
| `zcl_ai_mail_tool` | `send_mail` | `iv_subject`, `iv_body`, `it_to`, `it_cc?`, `it_bcc?`, `iv_sender?` | Sends email via SAP mail system |
| `zcl_ai_ext_api_tool` | `call_external_api` | `iv_url`, `iv_method?`, `iv_body?`, `it_headers?` | Calls external HTTP APIs |

**Transaction & Commit**

| Class | Tool Name | Parameters | Description |
|-------|-----------|------------|-------------|
| `zcl_ai_commit_tool` | `transaction_commit` | `iv_wait?` | Calls `BAPI_TRANSACTION_COMMIT` |
| `zcl_ai_rollback_tool` | `transaction_rollback` | *(none)* | Calls `BAPI_TRANSACTION_ROLLBACK` |
| `zcl_ai_call_trx_tool` | `call_transaction` | `iv_tcode` | Validates and calls an SAP transaction |
| `zcl_ai_maint_table_tool` | `call_maintenance_table` | `iv_table_name` | Opens SM30 table maintenance dialog |

**Agentic**

| Class | Tool Name | Parameters | Description |
|-------|-----------|------------|-------------|
| `zcl_ai_agent_tool` | `delegate_task` | `iv_task`, `iv_system_prompt?` | Spawns a sub-agent for task delegation |

### Agent Tool (Sub-Agent)

The `zcl_ai_agent_tool` lets the LLM spawn a sub-agent. It uses Ollama + Gemma 4 locally — no API key needed.

### Creating a custom tool

Create a class implementing `zif_ai_tool`:

```abap
CLASS zcl_ai_weather_tool DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_ai_tool.
    METHODS constructor IMPORTING iv_city TYPE string.
  PRIVATE SECTION.
    DATA mv_city TYPE string.
ENDCLASS.
```

Schema is auto-generated from constructor parameters — no manual schema code needed.

## Advanced Usage

```abap
" Direct construction without factory
DATA(lo_http) = NEW zcl_ai_onprem_http_client(
  iv_base_url = 'https://api.openai.com' ).
DATA(lo_provider) = NEW zcl_ai_openai_provider(
  io_client  = lo_http
  io_format  = NEW zcl_ai_openai_formatter( )
  iv_model   = 'gpt-4o'
  iv_api_key = 'sk-...' ).
DATA(lo_agent) = NEW zcl_ai_agent(
  io_provider = lo_provider ).
```

### Middleware

```abap
DATA(lo_pipeline) = NEW zcl_ai_pipeline( ).
lo_pipeline->add( NEW zcl_ai_logging_middleware( ) ).
lo_pipeline->add( NEW zcl_ai_timer_middleware( ) ).

DATA(lo_agent) = NEW zcl_ai_agent(
  io_provider = lo_provider
  io_pipeline = lo_pipeline ).
```

### Memory Strategies

The SDK includes three memory strategies injected into `zcl_ai_memory_store`:

| Class | Behavior |
|-------|----------|
| `zcl_ai_noop_memory` | Default — keeps all messages unchanged |
| `zcl_ai_window_memory` | Sliding window — keeps system messages + last N non-system messages |
| `zcl_ai_summarize_memory` | Summarization — replaces older messages with an LLM-generated summary |

### Message Types

| Class | Role | Description |
|-------|------|-------------|
| `zcl_ai_system_message` | `system` | System prompt |
| `zcl_ai_user_message` | `user` | User input |
| `zcl_ai_assistant_message` | `assistant` | LLM response (may carry tool calls) |
| `zcl_ai_tool_message` | `tool` | Tool execution result |

### Error Handling

All errors are raised via `zcx_ai_error` (extends `cx_static_check`):

```abap
RAISE EXCEPTION TYPE zcx_ai_error EXPORTING iv_message = 'Custom error'.
" or
zcx_ai_error=>raise( |Error: { lv_details }| ).
" capture sy-msg*
zcx_ai_error=>raise_syst( ).
```

## Requirements

- SAP NetWeaver 7.50+ (or S/4HANA)
- abapGit for installation

## License

MIT
