-- Oracle Comma Seperated Values to Collection
-------------------------------------------
-- Venkata Bhattaram
-- tinitiate.com
--
------------------------------------------------
-- The Ojects required to handle the Collections
------------------------------------------------

CREATE OR REPLACE TYPE STRING_OBJ as object
   ( string VARCHAR2(4000 CHAR) );
CREATE OR REPLACE TYPE STRING_TAB as table of string_obj;

CREATE OR REPLACE TYPE ID_OBJ AS OBJECT
   ( id NUMBER );
CREATE OR REPLACE TYPE ID_TAB as table of id_obj;

------------------------------------------
-- Functions to convert CSV to Collections
------------------------------------------
create or replace function csv2stringcoll
   (p_string      in varchar2, 
    p_separator   in varchar2 := ',') 
 return string_tab
is 
   l_returnValue         string_tab; 
   l_pattern             varchar2(250); 
   l_string              varchar2(32767) := p_string;
begin 
   l_pattern := '[^"' || p_separator || '"]+' ; 
   l_string  := replace(replace(l_string,',,',', ,'),',,',', ,');
   
   select string_obj(trim(regexp_substr(l_string, l_pattern, 1, level))) as token 
   bulk collect into l_returnValue 
   from   dual 
   where  regexp_substr (l_string, l_pattern, 1, level) is not null 
   connect by regexp_instr (l_string, l_pattern, 1, level) > 0; 

   return l_returnValue; 
end csv2stringcoll;
/

------------------------------------------
-- Functions to convert CSV to Collections
------------------------------------------
create or replace function csv2intcoll
   (p_string      in varchar2, 
    p_separator   in varchar2 := ',')
return id_tab
is 
   l_returnValue         id_tab; 
   l_pattern             varchar2(250); 
   l_string              varchar2(32767) := p_string;
begin 
   l_pattern := '[^"' || p_separator || '"]+' ; 
   l_string  := replace(replace(l_string,',,',', ,'),',,',', ,');

   select id_obj(trim(regexp_substr(l_string, l_pattern, 1, level))) as token 
   bulk collect into l_returnValue 
   from   dual 
   where  regexp_substr (l_string, l_pattern, 1, level) is not null 
   connect by regexp_instr (l_string, l_pattern, 1, level) > 0; 

   return l_returnValue; 
end csv2intcoll;
/

-- Usage Example --
-------------------
declare
   l_id_tab    id_tab();
begin
   -- Generate Comma Seperated Values data   
   select REGEXP_REPLACE ( sys.stragg( ','  || TRIM (level)), '(^,)', '')
   into   l_data_csv
   from   dual
   connect by level < 11;

   l_id_tab := csv2intcoll(l_data_csv);

   dbms_output.put_line('Printing the CSV from the collection');
   dbms_output.put_line('----');
   -- Use the tab;e function to select the values from collection
   for c1 in ( select  * 
               from table(l_id_tab) )
   loop
      dbms_output.put_line(c1.id);
   end loop;
end;
/
