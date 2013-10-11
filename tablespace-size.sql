-----------------------
-- General Queries
-- Venkata Bhattaram
-- tintiate.com 
-----------------------

-- Get Tablespace usage details
-------------------------------
select 'used_space',tablespace_name,sum(bytes)/1024/1024/1024 gb
from   dba_segments s
where  tablespace_name='my-table-space-name'
group  by tablespace_name
union  all
select 'free space',tablespace_name,sum(bytes)/1024/1024/1024 gb
from   dba_free_space
where  tablespace_name = 'my-table-space-name'
group  by tablespace_name;

--
select *
from   dba_tablespaces
where  tablespace_name in ('my-table-space-name');


-- Create Dynamic queries from system views
select 'select count(1), '||''''||table_name||''''||' from '||table_name||' union all'
from   user_tables;
