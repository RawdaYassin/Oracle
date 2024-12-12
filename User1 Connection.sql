
 -- Alter User1 session
ALTER SESSION SET "_oracle_script" = true;

SET SERVEROUTPUT ON;

-- Create User2 with unlimited quota with default tablespace USERS and temporary tablesplace TEMP
CREATE USER "User2" IDENTIFIED BY "12345678"  
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";
ALTER USER "User2" QUOTA UNLIMITED ON "USERS";

-- Grant the Manager Role to User2
GRANT Manager TO "User2";



-- CREATE THE DATABASE SCHEME

-- 1] CREATING MAIN TABLES

-- Employees table
CREATE TABLE Employees (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    position VARCHAR2(50),
    department VARCHAR2(50),
    salary NUMBER,
    status VARCHAR2(10) CHECK (status IN ('active', 'suspended'))
);

-- Attendance Table
CREATE TABLE Attendance (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER REFERENCES Employees(id),
    "date" DATE,
    in_time TIMESTAMP,
    out_time TIMESTAMP,
    total_hours NUMBER
);
DROP TABLE Attendance;

-- Payroll Table
CREATE TABLE Payroll (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER REFERENCES Employees(id),
    month VARCHAR2(10),
    total_hours_worked NUMBER,
    deductions NUMBER,
    bonuses NUMBER,
    net_salary NUMBER
);

CREATE SEQUENCE Payroll_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE OR REPLACE TRIGGER Payroll_trigger
BEFORE INSERT ON Payroll
FOR EACH ROW
BEGIN
    -- Automatically set the id from the Payroll_seq sequence
    :NEW.id := Payroll_seq.NEXTVAL;
END Payroll_trigger;



-- LeaveRequests Table
CREATE TABLE LeaveRequests (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER REFERENCES Employees(id),
    leave_date DATE,
    reason VARCHAR2(255),
    approval_status VARCHAR2(10) CHECK (approval_status IN ('approved', 'pending', 'rejected'))
);

-- AuditTrail Table
CREATE TABLE AuditTrail (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    leave_date DATE,
    approval_status VARCHAR2(10) CHECK (approval_status IN ('approved', 'pending', 'rejected')),
    operation VARCHAR2(10),
    timestamp TIMESTAMP
);

CREATE SEQUENCE AuditTrail_sequence
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Before Insertion in Suspended Attendance Attempts Trigger
CREATE OR REPLACE TRIGGER AuditTrail_before_insert
BEFORE INSERT ON AuditTrail
FOR EACH ROW
BEGIN
    :NEW.id := AuditTrail_sequence.NEXTVAL;
END;



-- Deductions Table
CREATE TABLE Deductions (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER REFERENCES Employees(id),
    deduction_reason VARCHAR2(25) CHECK (deduction_reason IN ('absence', 'late arrival', 'unreasoned leaving')),
    amount NUMBER,
    deduction_date DATE
);

-- Deductions Sequence
CREATE SEQUENCE Deductions_sequence
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Before Insertion in Suspended Attendance Attempts Trigger
CREATE OR REPLACE TRIGGER Deductions_before_insert
BEFORE INSERT ON Deductions
FOR EACH ROW
BEGIN
    :NEW.id := Deductions_sequence.NEXTVAL;
END;

-- 2] CREATING SECONDARY TABLES

-- SuspendedAttendanceAttempts Table
CREATE TABLE SuspendedAttendanceAttempts (
    id NUMBER PRIMARY KEY ,
    employee_id NUMBER REFERENCES Employees(id),
    attemptdate DATE
);

-- Suspended Attendance Attempts Sequence
CREATE SEQUENCE SuspendedAttendanceAttempts_sequence
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Before Insertion in Suspended Attendance Attempts Trigger
CREATE OR REPLACE TRIGGER SuspendedAttendanceAttempts_before_insert
BEFORE INSERT ON SuspendedAttendanceAttempts
FOR EACH ROW
BEGIN
    :NEW.id := SuspendedAttendanceAttempts_sequence.NEXTVAL;
END;

SHOW ERRORS TRIGGER SuspendedAttendanceAttempts_before_insert;


-- PerformanceReport Table
CREATE TABLE PerformanceReport (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER REFERENCES Employees(id),
    total_hours_worked NUMBER,
    approved_leaves NUMBER,
    late_arrivals NUMBER,
    report_period DATE
);

-- Performance Report Sequence
CREATE SEQUENCE PerformanceReport_sequence
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Before Insertion in Performance Report Trigger
CREATE OR REPLACE TRIGGER PerformanceReport_before_insert
BEFORE INSERT ON PerformanceReport
FOR EACH ROW
BEGIN
    :NEW.id := PerformanceReport_sequence.NEXTVAL;
END;


-- AdjustmentAudit Table
CREATE TABLE AdjustmentAudit (
    id NUMBER PRIMARY KEY,
    department VARCHAR2(50),
    adjustment_amount NUMBER,
    initiated_by VARCHAR2(50),
    timestamp TIMESTAMP
);

-- Adjustment Audit Sequence
CREATE SEQUENCE AdjustmentAudit_sequence
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Before Insertion in Adjustment Audit Trigger
CREATE OR REPLACE TRIGGER AdjustmentAudit_before_insert
BEFORE INSERT ON AdjustmentAudit
FOR EACH ROW
BEGIN
    :NEW.id := AdjustmentAudit_sequence.NEXTVAL;
END;

SHOW ERRORS TRIGGER AdjustmentAudit_before_insert;

-- MonthlyAttendanceSummary Table
CREATE TABLE MonthlyAttendanceSummary (
    summary_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    employee_id NUMBER REFERENCES Employees(id),
    month_year DATE,
    total_days_worked NUMBER,
    days_late NUMBER,
    avg_daily_hours NUMBER
);

-- Monthly Attendance Summary Sequence
CREATE SEQUENCE MonthlyAttendanceSummary_sequence
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Before Insertion in Monthly Attendance Summary Trigger
CREATE OR REPLACE TRIGGER MonthlyAttendanceSummary_before_insert
BEFORE INSERT ON MonthlyAttendanceSummary
FOR EACH ROW
BEGIN
    :NEW.summary_id := MonthlyAttendanceSummary_sequence.NEXTVAL;
END;

SHOW ERRORS TRIGGER MonthlyAttendanceSummary_before_insert;


-- 1- Attendence Validation Trigger
Create or replace PROCEDURE LogSuspendedAttempt(p_employee_id NUMBER) 
IS PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
        INSERT INTO SuspendedAttendanceAttempts (employee_id, attemptdate)
        VALUES (p_employee_id, SYSDATE);
        COMMIT; -- Commit the autonomous transaction
END LogSuspendedAttempt;
        
SHOW ERRORS PROCEDURE LogSuspendedAttempt;

CREATE OR REPLACE TRIGGER ValidateAttendance
BEFORE INSERT ON Attendance
FOR EACH ROW
DECLARE
    employee_status VARCHAR2(20);
    insert_excp EXCEPTION;
    PRAGMA EXCEPTION_INIT(insert_excp, -20004);
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Checking employee ID: ' || :NEW.employee_id);

    -- Fetch the status of the employee using :NEW.employee_id
    BEGIN
        SELECT status INTO employee_status
        FROM Employees
        WHERE id = :NEW.employee_id;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Employee not found for ID: ' || :NEW.employee_id);
            RAISE_APPLICATION_ERROR(-20002, 'Employee not found.');
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('Multiple employees found for ID: ' || :NEW.employee_id);
            RAISE_APPLICATION_ERROR(-20003, 'Multiple employees found for the same ID.');
    END;

    -- Check if the employee is suspended
    
    IF employee_status = 'suspended' THEN
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Employee ' || :NEW.employee_id || ' is suspended.');
        
        -- Log the attempt to SuspendedAttendanceAttempts table
        LogSuspendedAttempt(:NEW.employee_id);
        DBMS_OUTPUT.PUT_LINE('Inserting into suspended table');
        
    END;
        -- Prevent the insert into Attendance table by raising an error
        RAISE_APPLICATION_ERROR(-20004, 'Cannot complete insertion: Employee is suspended.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Employee ' || :NEW.employee_id || ' is active. Inserting into Attendance.');
    END IF;
END;

SHOW ERRORS TRIGGER ValidateAttendance;


-- 2- Work Hours Calculation Function
CREATE OR REPLACE FUNCTION CalculateWorkHours(
    in_time IN TIMESTAMP,
    out_time IN TIMESTAMP,
    employee_id IN NUMBER
) RETURN NUMBER IS
    total_hours NUMBER;
BEGIN
    -- Validate input parameters
    IF in_time IS NULL OR out_time IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'In time or Out time cannot be NULL.');
    END IF;

    IF out_time <= in_time THEN
        RAISE_APPLICATION_ERROR(-20002, 'Out time must be after In time.');
    END IF;

    -- Calculate total hours worked
    total_hours := CAST(out_time AS DATE) - CAST(in_time AS DATE); -- Calculate the difference in days
    total_hours := total_hours * 24; -- Convert days to hours

    -- Apply grace period adjustments
    IF EXTRACT(HOUR FROM in_time) > 8 THEN
        total_hours := total_hours - (EXTRACT(HOUR FROM in_time) - 8); -- Deduct late hours
    END IF;

    IF EXTRACT(MINUTE FROM in_time) > 5 AND EXTRACT(HOUR FROM in_time) >= 8 THEN
        total_hours := total_hours - (EXTRACT(MINUTE FROM in_time) - 5) / 60; -- Deduct late minutes
    END IF;

    -- Update the Attendance table
    UPDATE Attendance
    SET total_hours = total_hours
    WHERE Attendance.employee_id = employee_id;

    -- Return the calculated total hours
    RETURN total_hours;
END;

SHOW ERRORS FUNCTION CalculateWorkHours;


-- 3- Generate Payroll Procedure
CREATE OR REPLACE PROCEDURE GeneratePayroll(selected_month IN VARCHAR2) IS

    CURSOR employee_cursor IS
        SELECT id, salary 
        FROM Employees;

    v_employee_id       Employees.id%TYPE;
    v_base_salary       Employees.salary%TYPE;
    v_total_hours       NUMBER := 0;  -- Initialize to 0
    v_total_deductions  NUMBER := 0;  -- Initialize to 0
    v_total_bonuses     NUMBER;
    v_net_salary        NUMBER;

BEGIN
    FOR employee_rec IN employee_cursor LOOP
        v_employee_id := employee_rec.id;
        v_base_salary := employee_rec.salary;

        -- Get total hours worked in the selected month
        BEGIN
            SELECT total_hours
            INTO v_total_hours
            FROM Attendance
            WHERE employee_id = v_employee_id;
              --AND TO_CHAR(date, 'YYYY-MM') = selected_month;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_total_hours := 0;  -- If no records found, set to 0
        END;

        -- Get total deductions for the selected month
        BEGIN
            SELECT NVL(SUM(amount), 0)
            INTO v_total_deductions
            FROM Deductions
            WHERE employee_id = v_employee_id;
             -- AND TO_CHAR(deduction_date, 'YYYY-MM') = selected_month;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_total_deductions := 0;  -- If no records found, set to 0
        END;

        -- Calculate bonuses as 10% of base salary
        v_total_bonuses := v_base_salary * 0.10;
        -- Calculate net salary
        v_net_salary := v_base_salary + v_total_bonuses - v_total_deductions;

        -- Insert payroll record
        INSERT INTO Payroll (
            employee_id, 
            month, 
            total_hours_worked, 
            deductions, 
            bonuses, 
            net_salary
        ) VALUES (
            v_employee_id, 
            selected_month, 
            v_total_hours, 
            v_total_deductions, 
            v_total_bonuses, 
            v_net_salary
        );

    END LOOP;
END GeneratePayroll;

SHOW ERRORS PROCEDURE GeneratePayroll;


-- 4- Insert Leaves Audit Trigger
CREATE OR REPLACE TRIGGER LeavesAuditInsert
BEFORE INSERT ON LeaveRequests
FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail(employee_id, leave_date, approval_status, operation, timestamp)
    VALUES (:NEW.employee_id, :NEW.leave_date,  :NEW.approval_status,'INSERT', SYSDATE);
END;

SHOW ERRORS TRIGGER LeavesAuditInsert;


-- 5- Update Leaves Audit Trigger
CREATE OR REPLACE TRIGGER LeavesAuditUpdate
AFTER UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail(employee_id, leave_date, approval_status, operation, timestamp)
    VALUES (:NEW.employee_id, :NEW.leave_date,  :NEW.approval_status,'UPDATE', SYSDATE);
END;

SHOW ERRORS TRIGGER LeavesAuditUpdate;

-- 6- Generate Performance Report Procedure
CREATE OR REPLACE PROCEDURE GeneratePerformanceReport(start_date IN DATE, end_date IN DATE) IS
BEGIN
    -- Fetch total hours worked, approved leaves, and late arrivals
    FOR rec IN (
        SELECT a.employee_id, 
               SUM(a.total_hours) AS total_hours_worked, 
               COUNT(CASE WHEN l.approval_status = 'approved' THEN 1 END) AS approved_leaves,
               COUNT(CASE WHEN (EXTRACT(HOUR FROM a.in_time) > 8) 
                            OR (EXTRACT(MINUTE FROM a.in_time) > 5 AND EXTRACT(HOUR FROM a.in_time) >= 8) THEN 1 END) AS late_arrivals
        FROM Attendance a
        LEFT JOIN LeaveRequests l 
            ON a.employee_id = l.employee_id 
            AND l.leave_date BETWEEN start_date AND end_date -- Assuming leave date falls within report period
        WHERE a."date" BETWEEN start_date AND end_date
        GROUP BY a.employee_id
    ) LOOP
        -- Insert data into PerformanceReport
        INSERT INTO PerformanceReport (
            employee_id, 
            total_hours_worked, 
            approved_leaves, 
            late_arrivals, 
            report_period
        )
        VALUES (
            rec.employee_id, 
            rec.total_hours_worked, 
            rec.approved_leaves, 
            rec.late_arrivals, 
            SYSDATE
        );
    END LOOP;
END;

SHOW ERRORS PROCEDURE GeneratePerformanceReport;

-- 7- Process Leave Deductions Procedure
CREATE OR REPLACE PROCEDURE ProcessLeaveDeductions (deduction_reason varchar) IS
BEGIN
    FOR rec IN (SELECT * FROM LeaveRequests WHERE approval_status != 'approved') LOOP
        IF deduction_reason = 'absence' THEN
            INSERT INTO Deductions (employee_id, deduction_reason, amount, deduction_date)
            VALUES (rec.employee_id, deduction_reason , 200, rec.leave_date);
        ELSIF deduction_reason = 'unreasoned leaving' THEN
            INSERT INTO Deductions (employee_id, deduction_reason, amount, deduction_date)
            VALUES (rec.employee_id, deduction_reason , 100, rec.leave_date);
        ELSIF deduction_reason = 'late arrival' THEN              
            INSERT INTO Deductions (employee_id, deduction_reason, amount, deduction_date)
            VALUES (rec.employee_id, deduction_reason , 50, rec.leave_date);
        END IF;
    END LOOP;
END;

SHOW ERRORS PROCEDURE ProcessLeaveDeductions;

-- 8- Attendance Summary
DECLARE
    v_month_start DATE := TO_DATE('2024-12-01', 'YYYY-MM-DD'); 
    v_month_end   DATE := TO_DATE('2024-12-31', 'YYYY-MM-DD');
BEGIN
    FOR rec IN (
        SELECT 
            a.employee_id,
            COUNT(DISTINCT a."date") AS total_days_worked,
            COUNT(CASE 
                    WHEN EXTRACT(HOUR FROM a.in_time) > 8 
                      OR (EXTRACT(HOUR FROM a.in_time) = 8 AND EXTRACT(MINUTE FROM a.in_time) > 5)
                    THEN 1 
                 END) AS days_late,
            NVL(ROUND(AVG(a.total_hours), 2), 0) AS avg_daily_hours
        FROM Attendance a
        WHERE a."date" BETWEEN v_month_start AND v_month_end  
        GROUP BY a.employee_id
    ) LOOP
        INSERT INTO MonthlyAttendanceSummary (
            employee_id, 
            month_year, 
            total_days_worked, 
            days_late, 
            avg_daily_hours
        ) 
        VALUES (
            rec.employee_id, 
            v_month_start,  -- Format for month-year
            rec.total_days_worked, 
            rec.days_late, 
            rec.avg_daily_hours
        );
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

-- Test Attendance Summary Block
SELECT * FROM MonthlyAttendanceSummary;


-- 9- Transactional Payroll Adjustment
DECLARE
    v_department        VARCHAR2(50) := 'HR';        
    v_bonus_amount      NUMBER := 250;                 
    v_initiated_by      VARCHAR2(50) := USER;          
BEGIN
    -- Update the employees' salary in the specified department
    UPDATE Employees
    SET salary = salary + v_bonus_amount
    WHERE department = v_department;

    -- Insert the audit record in the AdjustmentAudit table
    INSERT INTO AdjustmentAudit (department, adjustment_amount, initiated_by, timestamp)
    VALUES (v_department, v_bonus_amount, v_initiated_by, CURRENT_TIMESTAMP);

    -- Commit the changes if everything is successful
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback in case of any error
        ROLLBACK;
END;

-- Test Attendance Summary Block
SELECT * FROM AdjustmentAudit;


-- 10. Blocker-Waiting Situation
-- This section demonstrates a blocker-waiting scenario with two transactions.
-- Two users (User 1 and User 2) attempt to update employees' salaries in the same department.
-- EXPECTED RESULT:
-- User 2 is blocked until User 1 commits or rolls back.

-- FUNCTION: Update salary by 10%
CREATE OR REPLACE FUNCTION update_salary(n_department VARCHAR) RETURN VARCHAR IS
BEGIN
    UPDATE Employees
    SET salary = salary + salary * 0.1
    WHERE department = n_department;

    RETURN 'Salary updated for department: ' || n_department;
END update_salary;

SHOW ERRORS FUNCTION update_salary;

-- TEST CASE: Blocker-Waiting Situation
-- Transaction 1 (User 1):
-- Start Transaction
DECLARE
    message VARCHAR(100);
BEGIN
    message:= update_salary('HR');
    DBMS_OUTPUT.PUT_LINE(message);
    -- Wait without commit to simulate blocking
    DBMS_SESSION.SLEEP(5);
END;

-- 11. Identifying Blocker and Waiting Sessions
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



-- 12. Deadlock Demonstration
-- This section demonstrates a deadlock scenario with two transactions.
-- Two users (User 1 and User 2) attempt to lock resources in reverse order.
-- EXPECTED RESULT:
-- A deadlock occurs as each session is waiting for the other to release the lock.
-- Oracle raises ORA-00060: deadlock detected.

-- TEST CASE: Deadlock Scenario
-- Transaction 1 (User 1):
-- Start Transaction
-- Kill the Block Session
DECLARE
    message VARCHAR(100);
BEGIN
    message := "deadlock_manager".update_salary_deadlock_handling('Finance');
    DBMS_OUTPUT.PUT_LINE(message);
    DBMS_SESSION.SLEEP(10); -- Simulate holding lock
    message := "deadlock_manager".update_salary_deadlock_handling('HR');
    DBMS_OUTPUT.PUT_LINE(message);
END;


COMMIT;