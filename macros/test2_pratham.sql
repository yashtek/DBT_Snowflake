{% macro mulesoft_dbt_process_log(
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


{% do exceptions.raise_compiler_error(
    "Invalid action received: " ~ action ~
    ". Allowed values are START_BATCH, START, SUCCESS, FAILED, COMPLETE_BATCH"
) %}


{% endif %}

{# ============================================================
STATUS CHECK
============================================================ #}

{% set ns = namespace(
existing_status='NOT_FOUND',
response_status='',
response_message=''
) %}

{% if action in ['START','SUCCESS','FAILED'] %}


{% set status_sql %}

    SELECT COALESCE(
          ACTION,
        'NOT_FOUND'
    )
    FROM TESTING.DBT_YS.PROCESS_LOG
    WHERE PARENT_PROCESS_NAME = '{{ parent_process_name | replace("'", "''") }}'
      AND CHILD_PROCESS_NAME  = '{{ child_process_name | replace("'", "''") }}'
      AND PROCESSED_DATE      = CURRENT_DATE()
      

{% endset %}

{% set status_result = run_query(status_sql) %}

{% if status_result is not none and status_result.rows | length > 0 %}
    {% set ns.existing_status = status_result.columns[0].values()[0] %}
{% endif %}


{% endif %}

{# ============================================================
START
============================================================ #}

{% if action == 'START' %}


{% if ns.existing_status == 'SUCCESS' %}

    {{ return({
        "status": "SKIPPED",
        "message": "Process already completed successfully today",
        "parent_process_name": parent_process_name,
        "child_process_name": child_process_name
    }) }}

{% elif ns.existing_status == 'RUNNING' %}

    {{ return({
        "status": "ALREADY_RUNNING",
        "message": "Process is already running",
        "parent_process_name": parent_process_name,
        "child_process_name": child_process_name
    }) }}

{% endif %}


{% endif %}

{# ============================================================
SUCCESS / FAILED VALIDATION
============================================================ #}

{% if action in ['SUCCESS','FAILED'] %}


{% if ns.existing_status != 'RUNNING' %}

    {{ return({
        "status": "NO_RUNNING_PROCESS",
        "message": "No RUNNING process found to update",
        "parent_process_name": parent_process_name,
        "child_process_name": child_process_name
    }) }}

{% endif %}


{% endif %}

{# ============================================================
EXISTING INSERT LOGIC
============================================================ #}

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

{# ============================================================
RETURN PAYLOAD
============================================================ #}

{% if action == 'START_BATCH' %}


{{ return({
    "status":"BATCH_STARTED",
    "message":"Batch started successfully"
}) }}


{% elif action == 'START' %}


{{ return({
    "status":"RUNNING",
    "message":"Process started successfully"
}) }}


{% elif action == 'SUCCESS' %}


{{ return({
    "status":"SUCCESS",
    "message":"Process marked successful"
}) }}


{% elif action == 'FAILED' %}


{{ return({
    "status":"FAILED",
    "message":"Process marked failed"
}) }}


{% elif action == 'COMPLETE_BATCH' %}


{{ return({
    "status":"BATCH_COMPLETED",
    "message":"Batch completed successfully"
}) }}


{% endif %}

{% endmacro %}
 