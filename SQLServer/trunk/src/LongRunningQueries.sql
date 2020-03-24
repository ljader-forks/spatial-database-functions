use DEVDB
go

SELECT creation_time 
      ,last_execution_time
      ,total_physical_reads
      ,total_logical_reads 
      ,total_logical_writes
      ,execution_count
      ,total_worker_time
      ,total_elapsed_time
      ,total_elapsed_time / execution_count avg_elapsed_time
      ,SUBSTRING(st.text, 
                 (qs.statement_start_offset/2) + 1,
                 ((CASE statement_end_offset
                   WHEN -1 THEN DATALENGTH(st.text)
                   ELSE qs.statement_end_offset 
                    END - qs.statement_start_offset)/2) + 1
       ) AS statement_text
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY 
       sys.dm_exec_sql_text(qs.sql_handle) st
 ORDER BY total_elapsed_time / execution_count DESC;


SELECT t.[text], s.last_execution_time
FROM sys.dm_exec_cached_plans AS p
INNER JOIN sys.dm_exec_query_stats AS s
   ON p.plan_handle = s.plan_handle
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS t
WHERE t.[text] LIKE N'%STGeomFromText(''CIRCULARSTRING%'
ORDER BY s.last_execution_time DESC;
GO

