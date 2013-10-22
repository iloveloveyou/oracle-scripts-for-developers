--
-- Notes:        Executing a CLOB using DBMS_SQL
-- FileName:     dbms_sql_using_clob.sql
-- Author:       tinitiate.com / Venkata Bhattaram
--
declare
   -- Cursor SQL
   l_dynSQL_clob clob := ' select level as init_val  from dual connect by level < :LevelValue ';
   -- Cursor handle
   l_dynCsr          integer;
   l_dynStatus       integer;
   -- Describe Column Values
   l_intvalue        integer;
   --
   l_level_value     integer := 10;
   --
   type t_refcursor  is ref cursor;
   l_refCursor       t_refcursor;
   --
   l_value           integer;
begin
   l_dynCsr     := dbms_sql.open_cursor;

   dbms_sql.parse(l_dynCsr, l_dynSQL_clob, dbms_sql.native);

   -- Optional
   dbms_sql.define_column(l_dynCsr, 1, l_intvalue);

   -- Set value to the bind variable
   dbms_sql.bind_variable(l_dynCsr, 'LevelValue', l_level_value);

   l_dynStatus := dbms_sql.execute(l_dynCsr);
   l_refCursor := dbms_sql.to_refcursor(l_dynCsr);
   
   loop
      fetch l_refCursor into l_value;
      dbms_output.put_line('Data '||l_value);
      exit when l_refCursor%notfound;
   end loop;   
   close l_refCursor;
end;
