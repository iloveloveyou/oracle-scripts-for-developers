--
------------------------------------------------------------
--
-- Topic:      Code Parser to get all occurences of DML ona table
--
-- File Name:  table_DML_usage.sql
-- Author:     tinitiate.com, Venkata Bhattaram
--             (c) on all CODE EXAMPLES
-- Notes:      1) Code Parser to get all occurences of DML ona table
--             2) Assumes that the DML type and table name are 
--                in the same line.
--
------------------------------------------------------------
--
declare
   -------------------------- 
   -- Venkata Bhattaram
   -- TINITIATE.COM (c) 2013
   --------------------------
   l_table_name    varchar2(45) := :l_table_name;
   l_table_owner   varchar2(45) := :l_owner;
begin
   for c1 in (select '%'||upper(table_name)||'%' tn
              from   dba_tables
              where  table_name = l_table_name
              and    owner      = l_table_owner)
   loop
      for c2 in (select *
                 from   dba_source
                 where  owner = l_table_owner
                 and    upper(text) like '%INSERT%'||c1.tn
                 union  all
                 select *
                 from   dba_source
                 where  owner = l_table_owner
                 and    upper(text) like '%MERGE%'||c1.tn
                 union all
                 select *
                 from   dba_source
                 where  owner = l_table_owner
                 and    upper(text) like '%UPDATE%'||c1.tn
                 union all
                 select *
                 from   dba_source
                 where  owner = l_table_owner
                 and    upper(text) like '%DELETE%'||c1.tn)
      loop
         if trim(c2.text) not like '--%'
         then
            dbms_output.put_line(c2.NAME||' '||c2.TYPE||' '||c2.LINE||' '||c2.TEXT);
         end if;   
      end loop;
   end loop;
end;
/
