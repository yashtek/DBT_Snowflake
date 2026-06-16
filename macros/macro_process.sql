{% macro check_process_completed(parent_process_name) %}

select count(*) as cnt
from process_log
where parent_process_name = '{{ parent_process_name }}'
  and action = 'COMPLETE_BATCH'
  and cast(created_at as date) = current_date

{% endmacro %}