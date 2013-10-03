-- 
-- --------------------------------------------------------------------------------------
-- BUILT-IN PACKAGE : DBMS_ERRLOG
-- AUTHOR           : Venkata Bhattaram
-- TINITIATE.COM
-----------------------------------------------------------------------------------------
-- DESCRIPTION      : Automatically log errors using, ERR$ table in Oracle
--                    1) Log DML errors for INSERT, UPDATE, MERGE and DELETE statements.
--                    2) Log data causing Value Too large exceptions
--                    3) Log data causing Constraint violations
--                    4) Log data causing Trigger execution errors
--
-- REQUIREMENTS     : Oracle 10GR2, Execute on dbms_errlog package
-- --------------------------------------------------------------------------------------
--

-- Test case
-- Create the base table
Create table test_tab
    (col1 int
    ,col2 varchar2(2)
    ,col3 date        not null
    ,primary key (col1));

-- Testing with DML causing errors

-- col2 value too large
insert into test_tab (col1, col2, col3) values(1,'ABCDEF',sysdate);
          ORA-12899: value too large for column "TINITIATE"."TEST_TAB"."COL2" (actual: 6, maximum: 2)

-- col3 value null
insert into test_tab (col1, col2, col3) values(1,'A',null);
          ORA-01400: cannot insert NULL into ("TINITIATE"."TEST_TAB"."COL3")
    
-- Use DBMS_ERRLOG to create the err$_ltest_tab
begin  
   dbms_errlog.create_error_log('TEST_TAB');  
end;
/

-- Check if the err$ table is created
select * from err$_test_tab;


-- Syntax: 
-- LOG ERRORS [INTO schema.table] [ (simple_expression) [ REJECT LIMIT {integer|UNLIMITED} ]
-- "REJECT LIMIT" clause is optional, default reject limit is zero, error logging will not work if a reject limit is not specified., Use Unlimited
-- "simple_expression" subclause allows users to specify a statement ID, which will be logged in the ORA_ERR_TAG$ field of the error logging table.

insert into test_tab (col1, col2, col3)
              values (1,'abcdef',sysdate)
    log errors into err$_test_tab  ('activityid-001')  --> (simple_expression)
    reject limit unlimited;

insert into test_tab (col1, col2, col3) 
    values (1,'a',null)
    log errors into err$_test_tab  ('activityid-002')  --> (simple_expression)
    reject limit 1;

-- Query to look at errors in the "ORA_ERR_MESG$" column
select ORA_ERR_MESG$ ,e.* from err$_test_table;
