-- ERD Query 
-- Venkata Bhattaram / Tinitiate.com (c) 2012
-- Parent (one-to-many: <) Child
-- Doenst Show tables with out Children or PKs
-- 
SELECT DISTINCT ERD
FROM   (
         SELECT  regexp_replace(
                     regexp_replace(SYS_CONNECT_BY_PATH(CHILD,'<'),'^[<]','')
                    ,'[<]$','') AS ERD   
         FROM    (
                  SELECT    parent
                           ,child
                  FROM (SELECT  pk.TABLE_NAME parent
                               ,pk.constraint_name pk_name
                               ,fk.constraint_name fk_name
                               ,fk.TABLE_NAME child
                        FROM user_constraints pk
                             LEFT OUTER JOIN user_constraints fk
                             ON (    fk.r_constraint_name=pk.constraint_name
                                 AND fk.constraint_type='R'
                                 AND fk.TABLE_NAME NOT LIKE 'BIN$%')
                        WHERE    pk.constraint_type='P'
                        AND      pk.TABLE_NAME NOT LIKE 'BIN$%')
                             --
                  START WITH parent IN (SELECT TABLE_NAME
                                        FROM   user_tables
                                        WHERE  TABLE_NAME NOT IN (SELECT DISTINCT TABLE_NAME
                                                                  FROM   user_constraints
                                                                  WHERE  constraint_type='R'
                                                                  AND    TABLE_NAME NOT LIKE 'BIN$%')
                                        AND    TABLE_NAME NOT LIKE 'BIN$%')
                  CONNECT BY nocycle prior child = parent
                  )
         CONNECT BY nocycle prior child = parent)
WHERE    ERD IS NOT NULL
ORDER BY ERD
