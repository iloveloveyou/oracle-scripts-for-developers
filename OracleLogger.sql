-- 
-- --------------------------------------------------------------------------------------
-- BUILT-IN PACKAGE : DBMS_ERRLOG
-- AUTHOR           : Venkata Bhattaram
-- TINITIATE.COM
-----------------------------------------------------------------------------------------
-- DESCRIPTION      : Table and Package to log events and errors
--                    1) Log Custom Event/Activity Log messages
--                    2) Configure Function /Proc / Anynomyous Block level Logging
--                    3) Event-Log and Error-Log tables, Automatic Partition Management
--
-- REQUIREMENTS     : Oracle 10GR2, Execute on dbms_errlog package
-- --------------------------------------------------------------------------------------
--

-- ----------------------------------------------------------------------------------------
-- Program     : ACTIVITY_SEQ (SEQUENCE DDL)
--
-- ----------------------------------------------------------------------------------------

-- Create sequence 
create sequence LOG_ID_SEQ
maxvalue 99999999999999
start with 1
increment by 1
cache 50;

-- ----------------------------------------------------------------------------------------
-- Program     : ACTIVITY_LOG (TABLE DDL)
--
-- ----------------------------------------------------------------------------------------

-- Create table
create table EVENT_LOG
(
  EVENT_SEQ    NUMBER(20) not null,
  INSERT_TIME  TIMESTAMP(6) not null,
  INSERT_DATE  DATE not null,
  EVENT_ID     NUMBER(20) not null,
  EVENT_NAME   VARCHAR2(200 CHAR),
  MODULE       VARCHAR2(200 CHAR),
  ACTION       VARCHAR2(200 CHAR),
  DESCRIPTION  VARCHAR2(1300 CHAR),
  VERSION      VARCHAR2(50 CHAR),
  STATUS_CODE  NUMBER(20),
  STATUS_TEXT  VARCHAR2(1000 CHAR),
  ROW_COUNT    NUMBER(20),
  AUDSID       NUMBER(20),
  SID          NUMBER(20),
  USERNAME     VARCHAR2(100 CHAR),
  DBNAME       VARCHAR2(50 CHAR),
  HOST         VARCHAR2(100 CHAR),
  IP_ADDRESS   VARCHAR2(50 CHAR),
  OS_USER      VARCHAR2(50 CHAR),
  CLIENT       VARCHAR2(100 CHAR),
  LINE         INTEGER
)
partition by range (INSERT_DATE)
(
  partition EVENTLOG_1 values less than (TO_DATE(' 2012-11-11 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))
);

-- ----------------------------------------------------------------------------------------
-- Program     : ERROR_LOG (TABLE DDL)
--
-- ----------------------------------------------------------------------------------------

-- Create table
create table ERROR_LOG
(
  ERROR_SEQ     NUMBER(20) not null,
  INSERT_TIME   TIMESTAMP(6) not null,
  INSERT_DATE   DATE not null,
  DBNAME        VARCHAR2(50 CHAR) not null,
  AUDSID        NUMBER(20) not null,
  SID           NUMBER(20) not null,
  USERNAME      VARCHAR2(50 CHAR) not null,
  MODULE        VARCHAR2(200 CHAR),
  LINE          NUMBER,
  ERROR_CODE    NUMBER,
  ERROR_MESSAGE VARCHAR2(2000 CHAR),
  ACTIVITY_ID   NUMBER(20),
  DESCRIPTION   VARCHAR2(1300 CHAR),
  VERSION       VARCHAR2(50 CHAR),
  ERROR_STACK   CLOB
)
partition by range (INSERT_DATE)
(
  partition ERRORLOG_1 values less than (TO_DATE(' 2012-11-11 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))
);

-- ----------------------------------------------------------------------------------------
-- Program     : util_logger_pkg (PACKAGE SPEC)
--
-- ----------------------------------------------------------------------------------------
--
create or replace package util_logger_pkg as

   -- Variable that holds the package name of this code.
   -- Used in debug messages.
   l_package_name constant  varchar2(30) := 'UTIL_LOGGER_PKG'
   c_packagename  constant  varchar2(30) := 'util_logger_pkg.';
   c_version      constant  activity_log.version%type := '1.0';

   type t_refcursor is ref cursor;

   procedure createErrLogTable
     (p_tableName       in     varchar2);

    procedure log_error
      (p_module         in     varchar2,
       p_linenum        in     number,
       p_errornum       in     number,
       p_errormsg       in     varchar2,
       p_descrip        in     varchar2,
       p_activity_id    in     number    default null,
       p_version        in     varchar2  default null);

    procedure log_activity
      (p_activity_id    in out number,
       p_activity       in     varchar2,
       p_module         in     varchar2,
       p_action         in     varchar2,
       p_description    in     varchar2,
       p_status_code    in     number,
       p_status_text    in     varchar2,
       p_row_count      in     number,
       p_version        in     varchar2);

   procedure log_debug
      (p_activity_id    in out number,
       p_module         in     varchar2,
       p_action         in     varchar2,
       p_description    in     varchar2,
       p_version        in     varchar2);

   function bitor
      (x                in     number,
       y                in     number)
    return number;

end util_logger_pkg;
/

-- ----------------------------------------------------------------------------------------
-- Program     : util_logger_pkg (PACKAGE BODY)
--
-- ----------------------------------------------------------------------------------------
--
create or replace package body util_logger_pkg as

   -- ----------------------------------------------------------------------------------------
   -- Program     : util_logger_pkg.pkb
   --
   -- Description : General purpose Logger
   --
   -- ----------------------------------------------------------------------------------------


   type typCallerInfo    is record (module_name     varchar2(30),
                                    procedure_name  varchar2(30),
                                    line_number     pls_integer);
   type typStackLine_tab is table of varchar2(100);

   function stringToTable 
     (p_string    in varchar2,
      p_delimiter in varchar2 default ',') 
    return typStackLine_tab 
   is
      l_wkgStr          varchar2(32767) := p_string || p_delimiter;
      l_posStart        pls_integer := 1;
      l_posEnd          pls_integer := 1;
      l_stringToTable   typStackLine_tab := typStackLine_tab();
   begin
      loop
         -- find the next delimiter
         l_posEnd := instr(l_wkgStr, p_delimiter, l_posStart);

         -- exit if no more delimiters found
         exit when nvl(l_posEnd, 0) = 0;

         -- store the delimited value
         l_stringToTable.extend;

         l_stringToTable(l_stringToTable.last) := trim(substr(l_wkgStr, l_posStart, l_PosEnd-l_posStart));
         l_posStart := l_posEnd + 1;
      end loop;

      return l_stringToTable;
   end stringToTable;



   -- this function uses the format_call_stack routine to identify the calling procedure and line number
   -- the position in the stack varies and hence the function get passed a parameter to determin which to get
   function callerdetails 
     (p_isError   in boolean default FALSE)
    return typCallerInfo
   is
      l_stacklines             typStackLine_tab;

      c_recsep        constant varchar2(1) := chr(10); -- seperator used to break stack into lines
      c_colsep        constant varchar2(2) := '  ';    -- seperator used to break columns up
      c_headlines     constant pls_integer := 3;       -- number of lines that make up the header in a call stack

      l_callstack              varchar2(4096);         -- temporary store for call stack
      l_callinfo               varchar2(256);
      l_proginfo               varchar2(100);
      l_lineinfo               pls_integer;
      l_callerinfo             typcallerinfo;
      l_stackDepth             pls_integer;
   begin
      -- Get the call stack, removing the trailing newline
      l_callstack := rtrim(dbms_utility.format_call_stack, c_recsep);

      -- Turn the call stack into a collection of lines...
      l_stacklines := stringTotable(l_callstack, c_recsep);

      l_stackDepth := 4; -- skip past the header lines      
      while l_stackDepth <= l_stacklines.count loop
         l_callinfo := l_stacklines(l_stackDepth);
         exit when instr(upper(l_callinfo), 'PACKAGE BODY '||USER||'.'||l_package_name) = 0;
         l_stackDepth := l_stackDepth +1;
      end loop;

      -- if this has been called because of an error then we need to increase the
      -- stack depth otherwise we will just be recording the line number of the call to 
      -- log the error and not the error line itself
      if p_isError and l_stackDepth < l_stacklines.count then
         l_stackDepth := l_stackDepth +1;
      end if;
         
     
      
      -- now extract the program and line number info
      if l_callinfo is not null then
         l_proginfo := trim(substr(l_callinfo, instr(l_callinfo, c_colsep,- 1) + length(c_colsep)));

         l_lineinfo := to_number(trim(substr(l_callinfo
                                            ,instr(l_callinfo, c_colsep)
                                            ,instr(l_callinfo, c_colsep || l_proginfo) - instr(l_callinfo, c_colsep))));

         l_callerinfo.module_name := substr(l_proginfo, instr(l_proginfo,'.')+1);
         l_callerinfo.line_number := l_lineinfo;
      else
         l_callerinfo.module_name := null;
         l_callerinfo.line_number := 0;
      end if;

      -- Return the depth required (ignoring the header lines)
      return l_callerinfo;
   exception
      when subscript_beyond_count then
         return null;
      when others then 
         return null;
   end callerdetails;



   procedure setApplicationInfo
     (p_modulename   in     varchar2,
      p_activityID   in     pls_integer,
      p_linenum      in out pls_integer,
      p_isError      in     boolean default FALSE) 
   is   
      l_callerinfo                 typCallerInfo;
   begin
      -- get the module and line number for the calling routine
      l_callerinfo := callerDetails(p_isError);

      dbms_application_info.set_module(l_callerinfo.module_name, p_modulename || '.' || to_char(l_callerinfo.line_number));
      dbms_application_info.set_client_info('LogRunID:' || p_activityID);
      p_linenum := l_callerinfo.line_number;
   exception
      when others then
         null;
   end setApplicationInfo;



   procedure log_error
     (p_module       in     varchar2,
      p_linenum      in     number,
      p_errornum     in     number,
      p_errormsg     in     varchar2,
      p_descrip      in     varchar2,
      p_activity_id  in     number   default null,
      p_version      in     varchar2 default null)
   is
      pragma autonomous_transaction;
      
      l_module   error_log.module%type;
      l_err_msg  error_log.error_message%type;
      l_descrip  error_log.description%type;
      l_linenum  error_log.line%type;
   begin
      l_module  := substr(p_module,1,200);
      l_descrip := substr(p_descrip,1,1300);

      -- If an error message was passed to this routine, then use it, else
      -- compute a message from the error number.
      if p_errormsg is null then
         l_err_msg := dbms_utility.format_error_stack;
      else
         l_err_msg := substr(p_errormsg,1,2000);
      end if;
      
      
      if p_linenum is null then
         setApplicationInfo
           (p_modulename   => p_module,
            p_activityID   => p_activity_id,
            p_linenum      => l_linenum,
            p_isError      => TRUE);
      else 
         l_linenum := p_linenum;
      end if;
          

      insert into error_log
          (error_seq,
           insert_time,
           insert_date,
           dbname,
           audsid,
           sid,
           username,
           module,
           line,
           error_code,
           error_message,
           activity_id,
           description,
           version,
           error_stack)
       values
          (errorlog_seq.nextval,                     -- error_seq
           systimestamp,                             -- insert_time
           trunc(sysdate),                           -- insert_date
           sys_context('USERENV', 'DB_NAME'),        -- dbname
           sys_context('USERENV', 'SESSIONID'),      -- audsid
           sys_context('USERENV', 'SID'),            -- sid
           sys_context('USERENV', 'SESSION_USER'),   -- username
           l_module,                                 -- module
           l_linenum,                                -- line
           p_errornum,                               -- error_code
           l_err_msg,                                -- error_message
           p_activity_id,                            -- activity_id
           l_descrip,                                -- description
           p_version,                                -- version
           dbms_utility.format_error_backtrace);     -- error_stack      

       commit;
    end log_error;


   procedure log_activity
      (p_activity_id    in out number,
       p_activity       in     varchar2,
       p_module         in     varchar2,
       p_action         in     varchar2,
       p_description    in     varchar2,
       p_status_code    in     number,
       p_status_text    in     varchar2,
       p_row_count      in     number,
       p_version        in     varchar2)
   is
      pragma autonomous_transaction;
      
      l_proc           varchar2(100)  := c_packagename || 'log_activity';
      l_linenum        pls_integer;
      l_modlinenum     pls_integer;
      
      l_activity       activity_log.activity%type;
      l_module         activity_log.module%type;
      l_action         activity_log.action%type;
      l_description    activity_log.description%type;
      l_status_text    activity_log.status_text%type;
           
   begin
      l_linenum := 1000;
      if p_activity_id is null then
         -- Generate an activity_id value for this log message
         select activity_id_seq.nextval into p_activity_id from dual;
      end if;

      setApplicationInfo
           (p_modulename   => p_module,
            p_activityID   => p_activity_id,
            p_linenum      => l_modlinenum);
            
      l_linenum := 1500;
      -- trim the input parameters using PL/SQL otherwise will have issue if any exceed 4000 chars
      l_activity    := substr(p_activity,    1, 200);           -- activity
      l_module      := substr(p_module,      1, 200);           -- module
      l_action      := substr(p_action,      1, 200);           -- action
      l_description := substr(p_description, 1, 1300);          -- description
      l_status_text := substr(p_status_text, 1, 1000);          -- status_text
            

      l_linenum := 2000;
      insert into activity_log
          (activity_seq,
           insert_time,
           insert_date,
           activity_id,
           activity,
           module,
           action,
           description,
           version,
           status_code,
           status_text,
           row_count,
           audsid,
           sid,
           username,
           dbname,
           host,
           ip_address,
           os_user,
           client,
           line)
      values
          (activitylog_seq.nextval,                 -- activity_seq
           systimestamp,                            -- insert_time
           trunc(sysdate),                          -- insert_date
           p_activity_id,                           -- activity_id
           l_activity,                              -- activity
           l_module,                                -- module
           l_action,                                -- action
           l_description,                           -- description
           p_version,                               -- version
           p_status_code,                           -- status_code
           l_status_text,                           -- status_text
           p_row_count,                             -- row_count
           sys_context('USERENV', 'SESSIONID'),     -- audsid
           sys_context('USERENV', 'SID'),           -- sid
           sys_context('USERENV', 'SESSION_USER'),  -- username
           sys_context('USERENV', 'DB_NAME'),       -- dbname
           sys_context('USERENV', 'HOST'),          -- host
           sys_context('USERENV', 'IP_ADDRESS'),    -- ip_address
           sys_context('USERENV', 'OS_USER'),       -- os_user
           sys_context('USERENV', 'MODULE'),        -- client
           l_modlinenum);                           -- line number      

        l_linenum := 9000;
        commit;
   exception
      when others then
         util_logger_pkg.log_error
               (
                l_proc,
                l_linenum,
                sqlcode,
                null,
                'Catchall end of procedure handler. ' ||
                'IN PARAMS: ' ||
                'p_activity_id:['     || to_char(p_activity_id)         || ']  ' ||
                'p_module:['          || substr(p_module,      1, 100)  || ']  ' ||
                'p_action:['          || substr(p_action,      1, 100)  || ']  ' ||
                'p_description:['     || substr(p_description, 1, 100)  || ']  ' ||
                'p_status_code:['     || to_char(p_status_code)         || ']  ' ||
                'p_status_text:['     || substr(p_status_text, 1, 100)  || ']  ' ||
                'p_row_count:['       || to_char(p_row_count)           || ']  ' ||
                'p_version:['         || substr(p_version,     1, 50)   || ']  ' ||
                'p_module len:['      || to_char(length(p_module))      || ']  ' ||
                'p_action len:['      || to_char(length(p_action))      || ']  ' ||
                'p_description len:[' || to_char(length(p_description)) || ']  ' ||
                'p_status_text len:[' || to_char(length(p_status_text)) || ']  ' ||
                'p_version len:['     || to_char(length(p_version))     || ']',
                p_activity_id,
                c_version
            );
            raise;

    end log_activity;


   procedure log_debug
      (p_activity_id    in out number,
       p_module         in     varchar2,
       p_action         in     varchar2,
       p_description    in     varchar2,
       p_version        in     varchar2)
   is      
   begin
      log_activity
         (p_activity_id => p_activity_id,
          p_activity    => 'DEBUG',     
          p_module      => p_module,   
          p_action      => p_action,       
          p_description => p_description,
          p_status_code => null,
          p_status_text => null,
          p_row_count   => null, 
          p_version     => p_version);
   end log_debug;


   function bitor
      (x in number,
       y in number)
    return number
   is
   begin
      return (x + y - bitand(x, y));
   end;

end util_logger_pkg;
/


-- ----------------------------------------------------------------------------------------
-- LOGGER Usage     : Test Block

-- ----------------------------------------------------------------------------------------

declare 
	-- Mandatory Params
	l_activity_id int:=null;
	l_proc        varchar2(100):='Test Block';
	c_version varchar2(10):='1.0';
	-- Custom Params
	p_a1 int  :=1;
	p_a2 date :=sysdate;

begin
         util_logger_pkg.log_activity(l_activity_id, 'DEBUG', l_proc, 'PROC START', 'IN PARAMS: ' ||
                                      'p_a1:['       || p_a1      || ']  '||
                                      'p_a2:['       || p_a2      || ']  ',
                                      null, null, null, c_version);
exception
	when others then
         util_logger_pkg.log_error(l_proc, null, sqlcode, null,
	                               'Error in load_daily_pnl_data. IN PARAMS: ' ||
	                               'p_a1:['       || p_a1      || ']  ' ||
	                               'p_a2:['       || p_a2      || ']  ',
	                               l_activity_id, c_version);
       raise;
end;
/
