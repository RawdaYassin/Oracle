
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

 

-- Identifying Blocker and Waiting Sessions
SELECT
    V$SESSION.sid,
    v$session.serial#,
    v$lock.request,
    V$lock.block
FROM
    v$session
    JOIN v$LOCK ON V$SESSION.SID = V$LOCK.sid
WHERE
    v$lock.request != 0 or v$lock.block != 0;



 
 /*
 

 -- Connection and Session Privileges
GRANT CREATE SESSION TO Manager;

-- Object Creation Privileges
-- Privileges to Create Procedures, Functions, Triggers, Transactions
GRANT CREATE ANY TABLE, ALTER ANY TABLE, DROP ANY TABLE TO Manager;
GRANT CREATE PROCEDURE, CREATE FUNCTION, CREATE TRIGGER, CREATE TRANSACTION TO Manager;

-- CRUD Privileges on tables
GRANT SELECT ANY TABLE, INSERT ANY TABLE, UPDATE ANY TABLE, DELETE ANY TABLE TO Manager;

-- Privileges for Transactions (COMMIT, ROLLBACK, SAVEPOINT are implicit)
GRANT CREATE TRANSACTION TO manager_rol







-- Step 1: Create the Manager Role
CREATE ROLE Manager;

-- Step 2: Grant Connection Privileges
GRANT CREATE SESSION TO Manager;

-- Step 3: Grant Schema-Level Object Privileges
GRANT CREATE ANY TABLE, ALTER ANY TABLE, DROP ANY TABLE TO Manager;

-- Step 4: Grant Object Creation Privileges
GRANT CREATE PROCEDURE, CREATE FUNCTION, CREATE TRIGGER TO manager_role;
GRANT CREATE PROCEDURE TO Manager;
GRANT CREATE TRIGGER TO Manager;
GRANT CREATE FUNCTIONS TO Manager;
GRANT CREATE TRANSACTION TO Manager;

GRANT CREATE SEQUENCE, CREATE VIEW, CREATE SYNONYM TO manager_role;

-- Step 5: Grant CRUD Privileges on Any Table
GRANT SELECT ANY TABLE, INSERT ANY TABLE, UPDATE ANY TABLE, DELETE ANY TABLE TO manager_role;

-- Step 6: Assign the Role to a User
GRANT manager_role TO some_user;


DROP ROLE Manager;




















-- USER SQL
CREATE USER "Manager" IDENTIFIED BY "12345678"  
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";
-- QUOTAS
ALTER USER "Manager" QUOTA UNLIMITED ON "USERS";
-- ROLES
GRANT "CONNECT" TO "Manager" WITH ADMIN OPTION;
-- SYSTEM PRIVILEGES
GRANT CREATE SESSION TO "Manager" WITH ADMIN OPTION;

GRANT CREATE TABLE TO "Manager" WITH ADMIN OPTION;
GRANT INSERT ANY TABLE TO "Manager" WITH ADMIN OPTION;
GRANT CREATE TRIGGER TO "Manager" WITH ADMIN OPTION;
GRANT ALL PRIVILEGES TO "Manager" WITH ADMIN OPTION;

drop user "Manager";

CREATE ROLE user_creation_role;
-- Grant Privileges to the Role
GRANT CREATE USER, ALTER USER, DROP USER TO user_creation_role;
-- Step 3: Assign the Role to the Manager User
GRANT user_creation_role TO "Manager";



DROP ROLE user_creation_role ;



SELECT * FROM V$LOCK;

SELECT
    V$SESSION.sid,
    v$session.serial#,
    v$lock.request,
    V$lock.block
FROM
    v$session
    JOIN v$LOCK ON V$SESSION.SID = V$LOCK.sid
WHERE
    v$lock.request != 0 or v$lock.block != 0;
    
SELECT * FROM V$SESSION;
grant select on v_$session to "user2";
insert into "user1".employees values(3,'ali', 'HR', 'management', 1500, 'active');
rollback;
grant alter system to "user1";


*/