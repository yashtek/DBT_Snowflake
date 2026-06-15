{{ config(materialized='view') }}

select
    action,
    parent_process_name,
    child_process_name,
    processed_by,
    correlation_id,
    status_desc,
    input_row_count,
    inserted_count,
    updated_count,
    error_count,
    retry_count,
    error_reason,
    created_ts
from PROCESS_LOG