
 -- Alter User2 session
ALTER SESSION SET "_oracle_script" = true;

SET SERVEROUTPUT ON;


INSERT INTO "User1".Employees (id, name, position, department, salary, status)
VALUES 
(1, 'Ahmed Hassan', 'Manager', 'HR', 20000, 'active'),
(2, 'Mona Khaled', 'Developer', 'IT', 15000, 'active'),
(3, 'Omar Fathy', 'Analyst', 'Finance', 18000, 'suspended'),
(4, 'Salma Said', 'HR Specialist', 'HR', 12000, 'active'),
(5, 'Youssef Adel', 'Technician', 'Operations', 10000, 'active');

-- Display the Employees table
SELECT * FROM "User1".Employees;
SELECT * FROM "User1".Attendance;
SELECT * FROM "User1".SuspendedAttendanceAttempts;

-- Test the Attendence Validation Trigger
-- Case 1: Employee is active

INSERT INTO "User1".Attendance (id, employee_id, "date", in_time, out_time, total_hours)
VALUES 
(1, 1, TO_DATE('2024-12-01', 'YYYY-MM-DD'), TO_TIMESTAMP('2024-12-01 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-12-01 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), 8);

-- Case 2: Employee is suspended
INSERT INTO "User1".Attendance (id, employee_id, "date", in_time, out_time, total_hours)
VALUES 
(2, 3, TO_DATE('2024-12-01', 'YYYY-MM-DD'), TO_TIMESTAMP('2024-12-01 08:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-12-01 16:45:00', 'YYYY-MM-DD HH24:MI:SS'), 8);

DELETE 
FROM  "User1".SuspendedAttendanceAttempts 
WHERE employee_id = 3;


DELETE 
FROM  "User1".Attendance 
WHERE employee_id = 3 or employee_id = 1 OR employee_id is null;


-- Test the Work Hours Calculation Function
DECLARE
    worked_hours NUMBER;
BEGIN
    worked_hours := "User1".CalculateWorkHours(
        TO_TIMESTAMP('2024-12-09 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2024-12-09 17:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        1
    );
    DBMS_OUTPUT.PUT_LINE('Total Worked Hours: ' || worked_hours);
END;

-- Test Generate Payroll Procedure
BEGIN
    "User1".GeneratePayroll('2024-12');
END;
SELECT * FROM  "User1".Payroll;

-- Test Insert Leaves Audit Trigger
INSERT INTO "User1".LeaveRequests (id, employee_id, leave_date, reason, approval_status)
VALUES 
(1, 1, TO_DATE('2024-12-05', 'YYYY-MM-DD'), 'Medical Leave', 'approved'),
(2, 2, TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'Family Emergency', 'pending'),
(3, 4, TO_DATE('2024-12-12', 'YYYY-MM-DD'), 'Vacation', 'rejected');

SELECT * FROM "User1".AuditTrail;


-- Test Update Leaves Audit Trigger
UPDATE "User1".LeaveRequests
SET approval_status = 'rejected'
WHERE id = 1;

UPDATE "User1".LeaveRequests
SET approval_status = 'approved'
WHERE id = 2;

UPDATE "User1".LeaveRequests
SET approval_status = 'pending'
WHERE id = 3;

SELECT * FROM "User1".AuditTrail;
SELECT * FROM "User1".LeaveRequests;

-- Test Generate Performance Report Procedure
BEGIN
    "User1".GeneratePerformanceReport( TO_DATE('2023-12-05', 'YYYY-MM-DD'),TO_DATE('2024-12-10', 'YYYY-MM-DD') );
END;
SELECT * FROM  "User1".PerformanceReport;


-- Test Process Leave Deductionse Procedure
BEGIN
    "User1".ProcessLeaveDeductions( 'absence' );
    "User1".ProcessLeaveDeductions( 'unreasoned leaving' );
    "User1".ProcessLeaveDeductions( 'late arrival' );
END;
SELECT * FROM  "User1".Deductions;


-- TEST CASE: Blocker-Waiting Situation
-- Start Transaction
-- Transaction 2 (User 2):
-- Attempt to update the same department, which will be blocked by User 1
DECLARE
    message VARCHAR(100);
BEGIN
    message:= "User1".update_salary('HR');
    DBMS_OUTPUT.PUT_LINE(message);
    -- Wait without commit to simulate blocking
    DBMS_SESSION.SLEEP(10);
END;


-- TEST CASE: Deadlock Scenario
-- Transaction 2 (User 2):
-- Start Transaction
-- Kill the Waiting Session
DECLARE
    message VARCHAR(100);
BEGIN
    message := "deadlock_manager".update_salary_deadlock_handling('HR');
    DBMS_OUTPUT.PUT_LINE(message);
    DBMS_SESSION.SLEEP(10); -- Simulate holding lock
    message := "deadlock_manager".update_salary_deadlock_handling('Finance');
    DBMS_OUTPUT.PUT_LINE(message);
END;


COMMIT;

--INSERT INTO Attendance (id, employee_id, "date", in_time, out_time, total_hours)
--VALUES 
--(1, 1, '2024-12-01', '2024-12-01 09:00:00', '2024-12-01 17:00:00', 8),
--(2, 2, '2024-12-01', '2024-12-01 09:30:00', '2024-12-01 18:00:00', 8),
--(3, 4, '2024-12-01', '2024-12-01 08:45:00', '2024-12-01 16:45:00', 8);
--
--COMMIT;


/*
INSERT INTO Payroll (id, employee_id, month, total_hours_worked, deductions, bonuses, net_salary)
VALUES 
(1, 1, 'December', 160, 500, 2000, 21500),
(2, 2, 'December', 170, 300, 1500, 26200),
(3, 4, 'December', 150, 200, 1200, 21000);


INSERT INTO "User1".LeaveRequests (id, employee_id, leave_date, reason, approval_status)
VALUES 
(1, 1, TO_DATE('2024-12-05', 'YYYY-MM-DD'), 'Medical Leave', 'approved'),
(2, 2, TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'Family Emergency', 'pending'),
(3, 4, TO_DATE('2024-12-12', 'YYYY-MM-DD'), 'Vacation', 'rejected');


INSERT INTO AuditTrail (id, employee_id, leave_date, approval_status, operation, timestamp)
VALUES 
(1, 1, TO_DATE('2024-12-05', 'YYYY-MM-DD'), 'approved', 'insert', SYSTIMESTAMP),
(2, 2, TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'pending', 'update', SYSTIMESTAMP);


INSERT INTO Deductions (id, employee_id, deduction_reason, amount, deduction_date)
VALUES 
(1, 1, 'late arrival', 200, TO_DATE('2024-12-01', 'YYYY-MM-DD')),
(2, 4, 'absence', 300, TO_DATE('2024-12-03', 'YYYY-MM-DD'));


INSERT INTO SuspendedAttendanceAttempts (id, employee_id, attemptdate)
VALUES 
(1, 3, TO_DATE('2024-12-01', 'YYYY-MM-DD'));


INSERT INTO PerformanceReport (id, employee_id, total_hours_worked, approved_leaves, late_arrivals, report_period)
VALUES 
(1, 1, 160, 2, 1, TO_DATE('2024-11-01', 'YYYY-MM-DD')),
(2, 2, 170, 1, 0, TO_DATE('2024-11-01', 'YYYY-MM-DD'));


INSERT INTO AdjustmentAudit (id, department, adjustment_amount, initiated_by, timestamp)
VALUES 
(1, 'Finance', 5000, 'Heba Ibrahim', SYSTIMESTAMP),
(2, 'IT', -2000, 'Khaled Mostafa', SYSTIMESTAMP);


INSERT INTO MonthlyAttendanceSummary (employee_id, month_year, total_days_worked, days_late, avg_daily_hours)
VALUES 
(1, TO_DATE('2024-11-01', 'YYYY-MM-DD'), 22, 1, 8.0),
(2, TO_DATE('2024-11-01', 'YYYY-MM-DD'), 21, 0, 8.1),
(4, TO_DATE('2024-11-01', 'YYYY-MM-DD'), 20, 2, 7.5);


*/