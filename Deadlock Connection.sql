
ALTER SESSION SET "_oracle_script" = true;
SET SERVEROUTPUT ON;

-- Kill the Waiting Session Function
CREATE OR REPLACE PROCEDURE kill_session(p_sid NUMBER, p_serial NUMBER) AS 
BEGIN
    IF p_sid = SYS_CONTEXT('USERENV', 'SID') THEN
        DBMS_OUTPUT.PUT_LINE('Cannot kill the current session');
    ELSE
        BEGIN
            EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || p_sid || ',' || p_serial || ''' IMMEDIATE';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Failed to kill session: ' || SQLERRM);
        END;
    END IF;
END;

SHOW ERRORS PROCEDURE kill_session;


CREATE OR REPLACE FUNCTION update_salary_deadlock_handling(n_department VARCHAR) RETURN VARCHAR IS
    blocking_sid     NUMBER;
    blocking_serial  NUMBER;
BEGIN
    BEGIN
        -- Attempt to update salary
        UPDATE "User1".Employees
        SET salary = salary + salary * 0.1
        WHERE department = n_department;

        -- If successful, return success message
        RETURN 'Salary updated for department: ' || n_department;

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -60 THEN -- ORA-00060: Deadlock Detected
                -- Find blocking session details
                DBMS_OUTPUT.PUT_LINE('Deadlock detected. Fetching blocking session...');
                BEGIN
                    SELECT
                        v$lock.sid,
                        v$session.serial#
--                    INTO
--                        blocking_sid,
--                        blocking_serial
                    FROM
                        v$session
                        JOIN v$lock ON v$session.sid = v$lock.sid
                    WHERE
                        v$lock.block = 1; -- Use `block = 1` to identify the blocking session

                    DBMS_OUTPUT.PUT_LINE('Blocking SID: ' || blocking_sid || ', Serial#: ' || blocking_serial);

                    -- Call the procedure to kill the session
                    kill_session(blocking_sid, blocking_serial);
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        RETURN 'No blocking session found.';
                    WHEN OTHERS THEN
                        RETURN 'Error identifying blocking session: ' || SQLERRM;
                END;

                ROLLBACK; -- Rollback the current transaction
                RETURN 'Deadlock detected. Blocking session killed and rolled back.';
            ELSE
                ROLLBACK; -- Ensure transaction rollback for unexpected errors
                RETURN 'Unexpected error: ' || SQLERRM;
            END IF;
    END;
END update_salary_deadlock_handling;


SHOW ERRORS FUNCTION update_salary_deadlock_handling;