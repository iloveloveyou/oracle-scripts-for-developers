-- Grants and Privs system views
-------------------------------
select * from dba_roles;
select * from dba_role_privs where grantee in ('my-schema-name')
select * from dba_sys_privs;
select * from dba_sys_grants;
select * from dba_col_privs;
select * from dba_users;
select * from dba_ts_quotas;
select * from dba_profiles ;
select * from dba_tab_privs;
