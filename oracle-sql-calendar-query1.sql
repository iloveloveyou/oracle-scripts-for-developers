--
-- Yet another SQL for oracle-sql-calendar-query
-- by Venkata Bhattaram / Tinitiate.com
--

with info as
(
select to_char(to_date( to_char(dt,'yyyymm')||'01','yyyymmdd'),'D') pos,
max(sys_connect_by_path( lpad(level,2,'0'),' ')) month,
lpad(' ',10,' ')||to_char(dt,'YYYY/MON')||lpad(' ',10,' ') title
from dual, (select sysdate dt from dual)
connect by level <= to_number(to_char(last_day(dt),'DD'))
),
title as
(
select ww from (
select ww from (
select sys_connect_by_path( substr(w,2),' ') ww from (
select to_char(sysdate+level,'D')||substr(to_char(sysdate+level,'DAY'),1,3) w from dual connect by level <= 7 order by 1)
connect by to_number(substr(w,1,1))=prior to_number(substr(w,1,1)+1)
)
order by length(ww) desc
) where rownum=1
)
select title||chr(10)||title.ww||chr(10)||regexp_replace(m,'(.{28})','\1'||chr(10)) cal from (
select pos, title, month, substr(rpad( lpad(' --',4*(pos-1),' --')||month, 35*4,' --'),1,4*35) m from info
), title;
