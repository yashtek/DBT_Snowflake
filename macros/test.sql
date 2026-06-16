{% macro mulesoft_dbt_process(
action='',
parent_process_name='',
child_process_name='',
processed_by='',
correlation_id='',
status_desc='',
input_row_count=0,
inserted_count=0,
updated_count=0,
error_count=0,
retry_count=0,
error_reason=''
) %}

{% set action = action | upper %}

{% if action not in ['START_BATCH', 'START', 'SUCCESS', 'FAILED', 'COMPLETE_BATCH'] %}

```
{% do exceptions.raise_compiler_error(
    "Invalid action received: " ~ action ~
    ". Allowed values are START_BATCH, START, SUCCESS, FAILED, COMPLETE_BATCH"
) %}
```

{% endif %}

{% set sql %}
insert into PROCESS_LOG (
ACTION,
PARENT_PROCESS_NAME,
CHILD_PROCESS_NAME,
PROCESSED_BY,
CORRELATION_ID,
STATUS_DESC,
INPUT_ROW_COUNT,
INSERTED_COUNT,
UPDATED_COUNT,
ERROR_COUNT,
RETRY_COUNT,
ERROR_REASON
)
values (
'{{ action | replace("'", "''") }}',
'{{ parent_process_name | replace("'", "''") }}',
'{{ child_process_name | replace("'", "''") }}',
'{{ processed_by | replace("'", "''") }}',
'{{ correlation_id | replace("'", "''") }}',
'{{ status_desc | replace("'", "''") }}',
{{ input_row_count }},
{{ inserted_count }},
{{ updated_count }},
{{ error_count }},
{{ retry_count }},
'{{ error_reason | replace("'", "''") }}'
)
{% endset %}

{% do run_query(sql) %}

{{ log("Inserted PROCESS_LOG record for action: " ~ action, info=True) }}

{% endmacro %}
