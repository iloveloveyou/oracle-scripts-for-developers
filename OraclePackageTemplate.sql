-- Oracle Object design structure
-- FileName: OraclePackageTemplate.sql
---
create or replace package mypackage as


   -- Package Name and Version
   c_packagename       constant  varchar2(30 char) := 'mypackage.';
   c_version           constant  varchar2(30 char) := '1.00';

   -- variable that holds the debug level for the package.
   -- this is set in the initialization section of the package.
   g_debug_level       pls_integer;
   g_log_level         pls_integer;

   -- Session Run (For DBMS_OUTPUT and GTT table inserts
   -- for Step by Step IDE debugging
   g_session_debug     number(20);

end mypackage;
/

CREATE OR REPLACE PACKAGE BODY mypackage as
   ------------------------------------------------------------------------------------------------------------------------
   -- Program     : mypackage
   --
   -- Description : Details of what this does
   --
   -- Modification History:
   --
   -- Date         Who               Version   QC       Description
   -- -----------  -------------     --------  -------  ----------------------------------------------------------------------
   -- 01-JAN-2013  My Name           1.0                Initial version


   procedure MyProc
   begin
      -- log start Activity
      null;
      -- log end Activity      
   end;
   
   funciton MyFunc
   return integer
   begin
      -- log start Activity
      return 1;
      -- log end Activity
   exception
      limit_util.log_error();
   end;
      
   
-- Package initialization section.  This block will be called
-- when this package is loaded for the first time in a session.
begin
   declare
      l_proc            varchar2(100) := c_packagename||' initialization section';
      l_linenum         pls_integer;
      l_activity_id     activity_log.activity_id%type := null;
   begin
      -- Get the debug level for this package
      begin
         select to_number(key_string) into g_debug_level
         from   parameter_table
         where  key_name = 'mypackage-debug-level';
      exception
         when no_data_found then
            g_debug_level := 0;
         when others then
      limit_util.log_error();
            raise;
      end;

      -- Get the log level for this package
      begin
         select to_number(key_string) into g_log_level
         from parameter
         where key_name = 'mypackage-log-level';
      exception
          when no_data_found then
             g_log_level := 0;
          when others then
             limit_util.log_error();
             raise;
      end;
   end;
exception
   when others then
      limit_util.log_error();
      raise;
end mypackage; 
/
