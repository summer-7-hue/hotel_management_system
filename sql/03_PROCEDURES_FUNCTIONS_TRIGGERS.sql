-- ============================================================================
-- HOTEL MANAGEMENT SYSTEM - PROCEDURES, FUNCTIONS & TRIGGERS
-- ============================================================================
-- Business logic automation, calculations, and data integrity enforcement
-- ============================================================================

-- ============================================================================
-- SECTION 1: PROCEDURES
-- ============================================================================

-- ============================================================================
-- PROCEDURE 1: UPDATE ROOM TYPE PRICE
-- Updates price for a specific room type
-- ============================================================================
CREATE OR REPLACE PROCEDURE UPDATE_ROOM_TYPE_PRICE
(
    P_ROOM_TYPE IN VARCHAR2,
    P_NEW_PRICE IN NUMBER
)
AS
BEGIN
    UPDATE ROOM_TYPE
    SET PRICE = P_NEW_PRICE
    WHERE ROOM_TYPE = P_ROOM_TYPE;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Room type not found');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Price updated successfully for room type: ' || P_ROOM_TYPE);
    COMMIT;
END UPDATE_ROOM_TYPE_PRICE;
/

-- ============================================================================
-- PROCEDURE 2: CHECK ROOM STATUS
-- Returns the current status of a specific room
-- ============================================================================
CREATE OR REPLACE PROCEDURE CHECK_ROOM_STATUS
(
    P_ROOM_ID IN NUMBER
)
AS
    V_STATUS ROOM.STATUS%TYPE;
BEGIN
    SELECT STATUS
    INTO V_STATUS
    FROM ROOM
    WHERE ROOM_ID = P_ROOM_ID;
    
    DBMS_OUTPUT.PUT_LINE('Room ' || P_ROOM_ID || ' Status: ' || V_STATUS);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Room not found');
END CHECK_ROOM_STATUS;
/

-- ============================================================================
-- PROCEDURE 3: CALCULATE MONTHLY TAX
-- Calculates 10% tax on all invoices for the current month
-- ============================================================================
CREATE OR REPLACE PROCEDURE CALCULATE_MONTHLY_TAX
AS
    V_TAX_TOTAL NUMBER;
    V_MONTH NUMBER;
    V_YEAR NUMBER;
BEGIN
    V_MONTH := EXTRACT(MONTH FROM SYSDATE);
    V_YEAR := EXTRACT(YEAR FROM SYSDATE);
    
    SELECT SUM(TOTAL_AMOUNT * 0.10)
    INTO V_TAX_TOTAL
    FROM INVOICE
    WHERE EXTRACT(MONTH FROM INVOICE_DATE) = V_MONTH
    AND EXTRACT(YEAR FROM INVOICE_DATE) = V_YEAR;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('MONTHLY TAX REPORT');
    DBMS_OUTPUT.PUT_LINE('Month: ' || V_MONTH || '/' || V_YEAR);
    DBMS_OUTPUT.PUT_LINE('Total Tax Due (10%): PKR ' || NVL(V_TAX_TOTAL, 0));
    DBMS_OUTPUT.PUT_LINE('========================================');
END CALCULATE_MONTHLY_TAX;
/

-- ============================================================================
-- PROCEDURE 4: GENERATE BILLING REPORT
-- Generates comprehensive billing report for a reservation
-- ============================================================================
CREATE OR REPLACE PROCEDURE GENERATE_BILLING_REPORT
(
    P_RESERVATION_ID IN NUMBER
)
AS
    V_ROOM_CHARGE NUMBER;
    V_SERVICE_CHARGE NUMBER;
    V_TOTAL NUMBER;
    V_GUEST_NAME VARCHAR2(50);
BEGIN
    -- Get guest name
    SELECT G.GUEST_NAME
    INTO V_GUEST_NAME
    FROM GUEST G
    JOIN RESERVATION R ON G.GUEST_ID = R.GUEST_ID
    WHERE R.RESERVATION_ID = P_RESERVATION_ID;
    
    -- Calculate room charge
    SELECT (R.CHECKOUT_DATE - R.CHECKIN_DATE) * RT.PRICE
    INTO V_ROOM_CHARGE
    FROM RESERVATION R
    JOIN ROOM RM ON R.ROOM_ID = RM.ROOM_ID
    JOIN ROOM_TYPE RT ON RM.ROOM_TYPE = RT.ROOM_TYPE
    WHERE R.RESERVATION_ID = P_RESERVATION_ID;
    
    -- Calculate service charge
    SELECT NVL(SUM(SU.QUANTITY * S.PRICE), 0)
    INTO V_SERVICE_CHARGE
    FROM SERVICE_USAGE SU
    JOIN SERVICE S ON SU.SERVICE_ID = S.SERVICE_ID
    WHERE SU.RESERVATION_ID = P_RESERVATION_ID;
    
    V_TOTAL := V_ROOM_CHARGE + V_SERVICE_CHARGE;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('BILLING REPORT');
    DBMS_OUTPUT.PUT_LINE('Guest: ' || V_GUEST_NAME);
    DBMS_OUTPUT.PUT_LINE('Reservation ID: ' || P_RESERVATION_ID);
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Room Charges: PKR ' || V_ROOM_CHARGE);
    DBMS_OUTPUT.PUT_LINE('Service Charges: PKR ' || V_SERVICE_CHARGE);
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Total Amount: PKR ' || V_TOTAL);
    DBMS_OUTPUT.PUT_LINE('========================================');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Reservation not found');
END GENERATE_BILLING_REPORT;
/

-- ============================================================================
-- SECTION 2: FUNCTIONS
-- ============================================================================

-- ============================================================================
-- FUNCTION 1: GET TOTAL BILL
-- Returns the total bill amount for a reservation
-- ============================================================================
CREATE OR REPLACE FUNCTION GET_TOTAL_BILL
(
    P_RESERVATION_ID IN NUMBER
) 
RETURN NUMBER 
IS
    V_TOTAL NUMBER;
BEGIN
    SELECT TOTAL_AMOUNT 
    INTO V_TOTAL 
    FROM INVOICE 
    WHERE RESERVATION_ID = P_RESERVATION_ID;
    
    RETURN V_TOTAL;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END GET_TOTAL_BILL;
/

-- ============================================================================
-- FUNCTION 2: GET ROOM TYPE REVENUE
-- Calculates total revenue from a specific room type
-- ============================================================================
CREATE OR REPLACE FUNCTION GET_ROOM_TYPE_REVENUE
(
    P_ROOM_TYPE IN VARCHAR2
)
RETURN NUMBER
IS
    V_TOTAL_REV NUMBER;
BEGIN
    SELECT SUM(I.TOTAL_AMOUNT)
    INTO V_TOTAL_REV
    FROM INVOICE I
    JOIN RESERVATION R ON I.RESERVATION_ID = R.RESERVATION_ID
    JOIN ROOM RM ON R.ROOM_ID = RM.ROOM_ID
    WHERE RM.ROOM_TYPE = P_ROOM_TYPE;
    
    RETURN NVL(V_TOTAL_REV, 0);
END GET_ROOM_TYPE_REVENUE;
/

-- ============================================================================
-- FUNCTION 3: GET DEPARTMENT SALARY SUM
-- Returns total salary expense for a department
-- ============================================================================
CREATE OR REPLACE FUNCTION GET_DEPT_SALARY
(
    P_DEPT_ID IN NUMBER
) 
RETURN NUMBER 
IS
    V_SUM NUMBER;
BEGIN
    SELECT SUM(SALARY) 
    INTO V_SUM 
    FROM STAFF 
    WHERE DEPT_ID = P_DEPT_ID;
    
    RETURN NVL(V_SUM, 0);
END GET_DEPT_SALARY;
/

-- ============================================================================
-- FUNCTION 4: GET STAY DURATION
-- Calculates number of nights in a reservation
-- ============================================================================
CREATE OR REPLACE FUNCTION GET_STAY_DURATION
(
    P_RESERVATION_ID IN NUMBER
)
RETURN NUMBER
IS
    V_DAYS NUMBER;
BEGIN
    SELECT (CHECKOUT_DATE - CHECKIN_DATE)
    INTO V_DAYS
    FROM RESERVATION
    WHERE RESERVATION_ID = P_RESERVATION_ID;
    
    RETURN V_DAYS;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END GET_STAY_DURATION;
/

-- ============================================================================
-- FUNCTION 5: CHECK ROOM AVAILABILITY
-- Returns 1 if room is available, 0 otherwise
-- ============================================================================
CREATE OR REPLACE FUNCTION IS_ROOM_AVAILABLE
(
    P_ROOM_ID IN NUMBER
)
RETURN NUMBER
IS
    V_STATUS VARCHAR2(10);
BEGIN
    SELECT STATUS
    INTO V_STATUS
    FROM ROOM
    WHERE ROOM_ID = P_ROOM_ID;
    
    IF V_STATUS = 'Available' THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END IS_ROOM_AVAILABLE;
/

-- ============================================================================
-- SECTION 3: TRIGGERS
-- ============================================================================

-- ============================================================================
-- TRIGGER 1: UPDATE ROOM STATUS ON BOOKING
-- Automatically marks room as occupied when reservation is created
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_ROOM_BOOKED
AFTER INSERT ON RESERVATION
FOR EACH ROW
BEGIN
    UPDATE ROOM
    SET STATUS = 'Occupied'
    WHERE ROOM_ID = :NEW.ROOM_ID;
    
    DBMS_OUTPUT.PUT_LINE('Room ' || :NEW.ROOM_ID || ' marked as Occupied');
END TRG_ROOM_BOOKED;
/

-- ============================================================================
-- TRIGGER 2: PREVENT BOOKING ON UNAVAILABLE ROOM
-- Blocks reservation creation if room is not available
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_PREVENT_INVALID_BOOKING
BEFORE INSERT ON RESERVATION
FOR EACH ROW
DECLARE
    V_STATUS VARCHAR2(20);
BEGIN
    SELECT STATUS 
    INTO V_STATUS 
    FROM ROOM 
    WHERE ROOM_ID = :NEW.ROOM_ID;
    
    IF V_STATUS != 'Available' THEN
        RAISE_APPLICATION_ERROR(-20004, 'ERROR: Room ' || :NEW.ROOM_ID || ' is not available for booking');
    END IF;
END TRG_PREVENT_INVALID_BOOKING;
/

-- ============================================================================
-- TRIGGER 3: VALIDATE CHECKOUT AFTER CHECKIN
-- Ensures checkout date is always after checkin date
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_VALIDATE_DATES
BEFORE INSERT ON RESERVATION
FOR EACH ROW
BEGIN
    IF :NEW.CHECKOUT_DATE <= :NEW.CHECKIN_DATE THEN
        RAISE_APPLICATION_ERROR(-20005, 'ERROR: Checkout date must be after checkin date');
    END IF;
END TRG_VALIDATE_DATES;
/

-- ============================================================================
-- TRIGGER 4: LOG RESERVATION CHANGES
-- Creates audit trail for all reservation modifications
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_LOG_RESERVATION_CHANGES
AFTER INSERT OR UPDATE ON RESERVATION
FOR EACH ROW
DECLARE
    V_ACTION VARCHAR2(50);
BEGIN
    IF INSERTING THEN
        V_ACTION := 'CREATED';
    ELSIF UPDATING THEN
        V_ACTION := 'UPDATED';
    END IF;
    
    INSERT INTO RESERVATION_LOG 
    (LOG_ID, RESERVATION_ID, ACTION, ACTION_DATE)
    VALUES 
    (RESERVATION_LOG_SEQ.NEXTVAL, :NEW.RESERVATION_ID, V_ACTION, SYSDATE);
END TRG_LOG_RESERVATION_CHANGES;
/

-- ============================================================================
-- TRIGGER 5: UPDATE INVENTORY ON PURCHASE
-- Automatically updates stock quantity when purchase is recorded
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_UPDATE_INVENTORY_ON_PURCHASE
AFTER INSERT ON INVENTORY_PURCHASE
FOR EACH ROW
BEGIN
    UPDATE INVENTORY_ITEM
    SET STOCK_QTY = STOCK_QTY + :NEW.QTY_PURCHASED
    WHERE INVENTORY_ID = :NEW.INVENTORY_ID;
    
    DBMS_OUTPUT.PUT_LINE('Inventory updated: +' || :NEW.QTY_PURCHASED || ' units');
END TRG_UPDATE_INVENTORY_ON_PURCHASE;
/

-- ============================================================================
-- TRIGGER 6: MARK ROOM AVAILABLE AFTER MAINTENANCE
-- Automatically marks room as available when maintenance is completed
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_ROOM_AVAILABLE_AFTER_MAINTENANCE
AFTER UPDATE OF STATUS ON MAINTENANCE
FOR EACH ROW
WHEN (NEW.STATUS = 'Resolved')
BEGIN
    UPDATE ROOM 
    SET STATUS = 'Available' 
    WHERE ROOM_ID = :NEW.ROOM_ID;
    
    DBMS_OUTPUT.PUT_LINE('Room ' || :NEW.ROOM_ID || ' marked as Available after maintenance');
END TRG_ROOM_AVAILABLE_AFTER_MAINTENANCE;
/

-- ============================================================================
-- TRIGGER 7: VALIDATE SALARY UPDATES
-- Ensures salary is always positive
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_VALIDATE_SALARY
BEFORE INSERT OR UPDATE ON STAFF
FOR EACH ROW
BEGIN
    IF :NEW.SALARY <= 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'ERROR: Salary must be greater than 0');
    END IF;
END TRG_VALIDATE_SALARY;
/

-- ============================================================================
-- TRIGGER 8: VALIDATE ROOM CAPACITY
-- Ensures no_of_guests does not exceed room capacity
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_VALIDATE_ROOM_CAPACITY
BEFORE INSERT ON RESERVATION
FOR EACH ROW
DECLARE
    V_CAPACITY NUMBER;
BEGIN
    SELECT CAPACITY
    INTO V_CAPACITY
    FROM ROOM RM
    JOIN ROOM_TYPE RT ON RM.ROOM_TYPE = RT.ROOM_TYPE
    WHERE RM.ROOM_ID = :NEW.ROOM_ID;
    
    IF :NEW.NO_OF_GUESTS > V_CAPACITY THEN
        RAISE_APPLICATION_ERROR(-20007, 'ERROR: Number of guests exceeds room capacity');
    END IF;
END TRG_VALIDATE_ROOM_CAPACITY;
/

-- ============================================================================
-- TRIGGER 9: AUTO-LOG PAYMENT RECORDS
-- Logs all payment transactions for audit
-- ============================================================================
CREATE OR REPLACE TRIGGER TRG_LOG_PAYMENTS
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    INSERT INTO RESERVATION_LOG 
    (LOG_ID, RESERVATION_ID, ACTION, ACTION_DATE, REMARKS)
    SELECT 
        RESERVATION_LOG_SEQ.NEXTVAL,
        I.RESERVATION_ID,
        'PAYMENT_RECEIVED',
        SYSDATE,
        'Amount: PKR ' || :NEW.AMOUNT
    FROM INVOICE I
    WHERE I.INVOICE_ID = :NEW.INVOICE_ID;
END TRG_LOG_PAYMENTS;
/

-- ============================================================================
-- END OF PROCEDURES, FUNCTIONS & TRIGGERS SCRIPT
-- ============================================================================
