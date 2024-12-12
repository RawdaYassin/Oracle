
 -- Alter Admin session
ALTER SESSION SET "_oracle_script" = true;

 -- Create the Manager Role
 CREATE ROLE Manager;

 -- Grant Priveliges to the Manger role
 GRANT ALL PRIVILEGES TO Manager WITH ADMIN OPTION;
 
 -- Drop Role if needed
 DROP ROLE Manager;
 
-- Create User1 with unlimited quota with default tablespace USERS and temporary tablesplace TEMP
CREATE USER "User1" IDENTIFIED BY "12345678"  
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";
ALTER USER "User1" QUOTA UNLIMITED ON "USERS";

-- Grant the Manager Role to User 1
GRANT Manager TO "User1";


GRANT SELECT ON V_$SESSION TO "User1";
GRANT SELECT ON V_$LOCK TO "User1";
GRANT ALTER SYSTEM TO "User1";
GRANT EXECUTE ON "User1".kill_session TO "User1";


-- Create User1 with unlimited quota with default tablespace USERS and temporary tablesplace TEMP
CREATE USER "deadlock_manager" IDENTIFIED BY "12345678"  
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";
ALTER USER "deadlock_manager" QUOTA UNLIMITED ON "USERS";

-- Grant the Manager Role to User 1
GRANT Manager TO "deadlock_manager";


GRANT SELECT ON V_$SESSION TO "deadlock_manager";
GRANT SELECT ON V_$LOCK TO "deadlock_manager";
GRANT UPDATE ON "User1".Employees TO "deadlock_manager";
GRANT ALTER SYSTEM TO "deadlock_manager";
GRANT EXECUTE ON "deadlock_manager".kill_session TO "deadlock_manager";



