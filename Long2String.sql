--
-- Reading High_value from Partition table
-- LONG to VARCHAR
-- LONG2VARCHAR
-- Rename Interval Partition Names to meaningful names
-- 
declare
   l_HighValue                date;
   l_PartitionName            varchar2(30);
   l_sql                      varchar2(4000);
   -- Long2String
   -- Convert Long to Varchar2
   function long2string (iLong in long)
   return varchar2
   as
      l_StringValue varchar2(4000);
   begin
       execute immediate 'select ' || iLong || ' from dual' into l_StringValue;
       return l_StringValue;
   end long2string;
begin
   for c1 in (select table_name,
                     partition_name,
                     high_value
              from   user_tab_partitions
              where  partition_name like 'SYS_P%') loop
      begin
         execute immediate 'select ' || c1.high_value || ' from dual' into l_HighValue;

         l_PartitionName := substr(replace(c1.table_name,'_',''),1,23) || '_' || to_char(l_HighValue-1,'YYMMDD');
         if c1.partition_name != l_PartitionName then
            l_sql := 'alter table ' || c1.table_name || ' rename partition ' || c1.partition_name || ' to ' || l_PartitionName;
            -- execute immediate l_sql;
            dbms_output.put_line(l_sql);
         end if;
      exception
         when others then
            null;
      end;
   end loop;
exception
   when others then
      raise;
end;
