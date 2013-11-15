--===========================================================================================================
-- TOPIC:   Oracle PL/SQL Built-In Package/Proc: OWA_UTIL.who_called_me
--===========================================================================================================
--
-- NOTES: *  OWA_UTIL is a oracle supplied package, which provides various utility functions/Procs
--        *  who_called_me procedure OUT PARAMETERS 
--              OWNER of PL/SQL code that invoked OWA_UTIL.who_called_me
--              NAME of the PL/SQL code. package.(procedure/function), NULL for anonymous block
--              lineno where the call was made in the PL/SQL code
--              caller_t the Object type of program
--        *  To get the output MAKE SURE THIS is called in a wrapper.
--
--===========================================================================================================
--
-- FILE-NAME       : owa_util.who_called_me.sql
-- DEPENDANT-FILES : These are the files and libraries needed to run this program ;
--                   owa_util package
--
-- AUTHOR          : tinitiate.com / Venkata Bhattaram
--                   (c) 2013
--
-- DESC            : Sample usage of the OWA_UTIL.who_called_me built-in package.proc
--
--===========================================================================================================

-- Making a direct call will no return any values
-- Enclose the call to the OWA_UTIL.who_called_me in a wrapper 

create or replace procedure tinproc
as
   l_owner          varchar2(30);
   l_name           varchar2(30);
   l_type           varchar2(30);
   l_source_line_no number;
begin
   -- Call to the owa_util.who_called_me and the ou parameters
   owa_util.who_called_me(l_owner, l_name, l_source_line_no, l_type);
   -- Print the details
   dbms_output.put_line('Owner: '|| l_owner);
   dbms_output.put_line('Name: ' || l_name);
   dbms_output.put_line('Source_line_no: '|| l_source_line_no);
   dbms_output.put_line('Type: ' || l_type);
end tinproc;
/

-- Make a call to the wrapper in Anynomous block
begin
   tinproc;
end;
/

-- Make a call to the wrapper in package.function

-- Create package SPEC
create or replace package tin_pkg
as
   function test_function
   return number;

   procedure test_proc;

end tin_pkg;
/

-- Create package Body
create or replace package body tin_pkg
as
   function test_function
   return number
   as
   begin
      tinproc;
      return 1;   
   end test_function;

   procedure test_proc
   as
   begin
      tinproc;
   end;

end tin_pkg;
/

-- test the pacakage

begin 
   tin_pkg.test_proc;
end;
/

select tin_pkg.test_function from dual;


--===========================================================================================================
--
-- FOOT NOTES: 1) Could be used in Logger packages and Auditing packages
--             2) In case of uisng this feature in LOGGERs, To get error line number 
--                using the source_line_no from owa_util is NOT ideal, use the following instead
--
   create or replace function get_line_number
   return number
   is
      l_callstack varchar2(20000);
   begin
      l_callstack := replace(dbms_utility.format_error_backtrace, chr(10),' ');
      return substr(l_callstack,instr(l_callstack,' line ',-1,1)+ 6,10);
   exception
      when others then
         return null;
   end get_line_number;
--
--
--===========================================================================================================
-- END OF CODE
--===========================================================================================================
