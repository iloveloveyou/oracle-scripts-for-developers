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

ORACLE TABLESPACES

1) Tablespaces in Oracle holds all the objects: Tables, Indexes, LOB Segments.., They are called segments.
2) Each sits on data file(s).
3) There could be multiple TableSpaces in a single Database.

Below are Queries to use for various tablespace mertics


-- List out details of all TableSpaces
SELECT *
FROM   dba_tablespaces;

SELECT *
FROM   v$tablespace;

-- Query to check TableSpace usage
SELECT dtm.tablespace_name,
       dtm.used_space*dts.block_size                     AS used_bytes,
       dtm.tablespace_size*dts.block_size                AS total_bytes,
       (dtm.used_space*dts.block_size)/(1024*1024)       AS used_bytes_in_MB,
       (dtm.tablespace_size*dts.block_size)/(1024*1024)  AS total_bytes_in_MB,
       dtm.used_percent
FROM    dba_tablespace_usage_metrics dtm
       ,dba_tablespaces              dts
WHERE  dtm.tablespace_name = dts.tablespace_name
AND    dtm.tablespace_name = '<MY-TABLE-SPACE-NAME>'; -- OPTIONAL FILTER


-- Query to check History of TableSpace usage
SELECT vts.name,
       dth.rtime,
       (dth.tablespace_maxsize*dts.block_size)  AS max_size_in_bytes,
       (dth.tablespace_usedsize*dts.block_size) AS used_size_in_bytes
FROM    dba_hist_tbspc_space_usage dth
       ,v$tablespace               vts
       ,dba_tablespaces            dts
WHERE  dth.tablespace_id   = vts.ts#
AND    vts.name = dts.tablespace_name
AND    name = '<MY-TABLE-SPACE-NAME>'
ORDER  BY vts.name,dth.rtime;


-- Free Space ina  give TableSpace
SELECT  tablespace_name
       ,SUM(bytes)      AS bytes_free
FROM   sys.dba_free_space
WHERE  name = '<MY-TABLE-SPACE-NAME>'
GROUP  BY tablespace_name;



-- Table space usage by object, by Percent Used
SELECT dbs.owner,
       dbs.segment_name,
       dbs.segment_type,
       dbs.size_in_MB,
       ROUND((100 / tbs.tablespace_size) * dbs.size_in_MB) AS pct
FROM  (SELECT dbs.owner,
              dbs.segment_name,
              dbs.segment_type,
              ROUND(SUM(dbs.bytes)/(1024*1024)) size_in_MB
       FROM   dba_segments   dbs              
       WHERE  dbs.tablespace_name = '<MY-TABLE-SPACE-NAME>'
       GROUP  BY dbs.owner, dbs.segment_name, dbs.segment_type)   dbs,
       --
      (SELECT SUM(bytes)/(1024*1024)  AS tablespace_size
       FROM   dba_data_files
       WHERE  tablespace_name = '<MY-TABLE-SPACE-NAME>')          tbs      
ORDER BY 4 DESC;



-- TableSpace Usage by Table Partition
-- PreRequisite table partitions are analyzed
SELECT p.partition_name,
       CEIL(s.bytes / 1024 / 1204) size_in_mb,
       CEIL((p.blocks - p.empty_blocks) / p.blocks * s.bytes / 1024 / 1204) used_in_mb,
       CEIL(p.empty_blocks / p.blocks * s.bytes / 1024 / 1204) free_in_mb,
       CEIL((p.blocks - p.empty_blocks) / p.blocks * 100) pct_used
FROM    dba_tab_partitions p
       ,dba_segments s
WHERE  p.table_owner    = s.owner
AND    p.partition_name = s.partition_name
AND    p.table_name     = s.segment_name
AND    p.table_owner    = '<OWNER>'
AND    p.table_name     = '<TABLE_NAME>'
ORDER  BY partition_position;

-- TableSpace Usage by Table subPartition
-- PreRequisite table subpartitions are analyzed
SELECT p.subpartition_name,
       CEIL(s.bytes / 1024 / 1204) size_in_mb,
       CEIL((p.blocks - p.empty_blocks) / p.blocks * s.bytes / 1024 / 1204) used_in_mb,
       CEIL(p.empty_blocks / p.blocks * s.bytes / 1024 / 1204) free_in_mb,
       CEIL((p.blocks - p.empty_blocks) / p.blocks * 100) pct_used
FROM    dba_tab_subpartitions p
       ,dba_segments s
WHERE  p.table_owner       = s.owner
AND    p.subpartition_name = s.partition_name
AND    p.table_name        = s.segment_name
AND    p.table_owner       = '<OWNER>'
AND    p.table_name        = '<TABLE_NAME>'
ORDER  BY subpartition_position;
