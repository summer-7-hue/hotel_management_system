-- ============================================================================
-- HOTEL MANAGEMENT SYSTEM - VIEWS CREATION SCRIPT
-- ============================================================================
-- These views provide simplified access to complex queries and business logic
-- ============================================================================

-- ============================================================================
-- VIEW 1: GUEST STAY DETAILS
-- Shows guest names with room and check-in/out dates
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_GUEST_STAY_DETAILS AS
SELECT 
    G.GUEST_NAME,
    R.RESERVATION_ID,
    R.ROOM_ID,
    RM.ROOM_TYPE,
    R.CHECKIN_DATE,
    R.CHECKOUT_DATE,
    R.STATUS,
    (R.CHECKOUT_DATE - R.CHECKIN_DATE) AS STAY_DURATION_DAYS
FROM 
    GUEST G
    JOIN RESERVATION R ON G.GUEST_ID = R.GUEST_ID
    JOIN ROOM RM ON R.ROOM_ID = RM.ROOM_ID;

-- ============================================================================
-- VIEW 2: ROOM PRICING AND AVAILABILITY
-- Shows each room with its category, price, and current status
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_ROOM_PRICING AS
SELECT 
    RM.ROOM_ID,
    RT.ROOM_TYPE,
    RT.PRICE,
    RT.CAPACITY,
    RM.STATUS,
    RM.FLOOR_NO
FROM 
    ROOM RM
    JOIN ROOM_TYPE RT ON RM.ROOM_TYPE = RT.ROOM_TYPE
ORDER BY 
    RM.ROOM_ID;

-- ============================================================================
-- VIEW 3: PENDING PAYMENTS
-- Shows invoices with unpaid or partial payment status
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_PENDING_PAYMENTS AS
SELECT 
    I.INVOICE_ID,
    I.RESERVATION_ID,
    G.GUEST_NAME,
    I.TOTAL_AMOUNT,
    I.INVOICE_STATUS,
    I.INVOICE_DATE
FROM 
    INVOICE I
    JOIN RESERVATION R ON I.RESERVATION_ID = R.RESERVATION_ID
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
WHERE 
    I.INVOICE_STATUS IN ('Unpaid', 'Partial')
ORDER BY 
    I.INVOICE_DATE DESC;

-- ============================================================================
-- VIEW 4: STAFF WORKLOAD
-- Shows staff names with count of reservations processed
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_STAFF_WORKLOAD AS
SELECT 
    S.STAFF_ID,
    S.STAFF_NAME,
    S.ROLE,
    D.DEPT_NAME,
    COUNT(R.RESERVATION_ID) AS TOTAL_BOOKINGS
FROM 
    STAFF S
    LEFT JOIN DEPARTMENT D ON S.DEPT_ID = D.DEPT_ID
    LEFT JOIN RESERVATION R ON S.STAFF_ID = R.STAFF_ID
GROUP BY 
    S.STAFF_ID,
    S.STAFF_NAME,
    S.ROLE,
    D.DEPT_NAME
ORDER BY 
    TOTAL_BOOKINGS DESC;

-- ============================================================================
-- VIEW 5: DAILY FINANCE SUMMARY
-- Shows total amount collected per day with payment method breakdown
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_DAILY_FINANCE AS
SELECT 
    P.PAYMENT_DATE,
    P.PAYMENT_METHOD,
    COUNT(P.PAYMENT_ID) AS TRANSACTION_COUNT,
    SUM(P.AMOUNT) AS DAILY_TOTAL
FROM 
    PAYMENT P
GROUP BY 
    P.PAYMENT_DATE,
    P.PAYMENT_METHOD
ORDER BY 
    P.PAYMENT_DATE DESC;

-- ============================================================================
-- VIEW 6: INVENTORY PURCHASE HISTORY
-- Shows detailed purchase history with supplier and staff information
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_PURCHASE_HISTORY AS
SELECT
    P.PURCHASE_ID,
    I.ITEM_NAME,
    S.SUPPLIER_NAME,
    P.QTY_PURCHASED,
    I.UNIT_PRICE,
    P.TOTAL_COST,
    ST.STAFF_NAME AS MANAGED_BY,
    P.PURCHASE_DATE
FROM 
    INVENTORY_PURCHASE P
    JOIN INVENTORY_ITEM I ON P.INVENTORY_ID = I.INVENTORY_ID
    JOIN SUPPLIER S ON P.SUPPLIER_ID = S.SUPPLIER_ID
    JOIN STAFF ST ON P.STAFF_ID = ST.STAFF_ID
ORDER BY 
    P.PURCHASE_DATE DESC;

-- ============================================================================
-- VIEW 7: RESERVATION ACTION HISTORY
-- Shows complete history of actions taken on each reservation
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_RESERVATION_HISTORY AS
SELECT 
    RL.LOG_ID,
    RL.RESERVATION_ID,
    R.GUEST_ID,
    G.GUEST_NAME,
    RL.ACTION,
    RL.ACTION_DATE,
    RL.REMARKS
FROM 
    RESERVATION_LOG RL
    JOIN RESERVATION R ON RL.RESERVATION_ID = R.RESERVATION_ID
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
ORDER BY 
    RL.ACTION_DATE DESC;

-- ============================================================================
-- VIEW 8: CLEANING SCHEDULE
-- Shows cleaning status of each room with assigned staff
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_CLEANING_SCHEDULE AS
SELECT 
    H.HK_ID,
    H.ROOM_ID,
    RM.ROOM_TYPE,
    S.STAFF_NAME AS CLEANER,
    H.STATUS,
    H.CLEANING_DATE
FROM 
    HOUSEKEEPING H
    JOIN STAFF S ON H.STAFF_ID = S.STAFF_ID
    JOIN ROOM RM ON H.ROOM_ID = RM.ROOM_ID
ORDER BY 
    H.CLEANING_DATE DESC;

-- ============================================================================
-- VIEW 9: SERVICE CONSUMPTION ANALYSIS
-- Shows guest service usage with total cost calculations
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_SERVICE_CONSUMPTION AS
SELECT
    R.RESERVATION_ID,
    G.GUEST_NAME,
    R.GUEST_ID,
    S.SERVICE_ID,
    S.SERVICE_NAME,
    SU.QUANTITY,
    S.PRICE AS UNIT_PRICE,
    (S.PRICE * SU.QUANTITY) AS TOTAL_SERVICE_COST,
    SU.USAGE_DATE
FROM 
    SERVICE_USAGE SU
    JOIN SERVICE S ON SU.SERVICE_ID = S.SERVICE_ID
    JOIN RESERVATION R ON SU.RESERVATION_ID = R.RESERVATION_ID
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
ORDER BY 
    R.RESERVATION_ID,
    SU.USAGE_DATE;

-- ============================================================================
-- VIEW 10: ACTIVE MAINTENANCE ISSUES
-- Shows room maintenance issues with assigned technician and status
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_ACTIVE_MAINTENANCE AS
SELECT 
    M.MAINTENANCE_ID,
    M.ROOM_ID,
    RM.ROOM_TYPE,
    S.STAFF_NAME AS TECHNICIAN,
    M.DESCRIPTION,
    M.STATUS,
    M.REQUEST_DATE
FROM 
    MAINTENANCE M
    JOIN STAFF S ON M.STAFF_ID = S.STAFF_ID
    JOIN ROOM RM ON M.ROOM_ID = RM.ROOM_ID
WHERE 
    M.STATUS != 'Resolved'
ORDER BY 
    M.REQUEST_DATE ASC;

-- ============================================================================
-- VIEW 11: OCCUPANCY RATE
-- Shows current occupancy statistics
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_OCCUPANCY_RATE AS
SELECT 
    'Occupied' AS STATUS,
    COUNT(ROOM_ID) AS ROOM_COUNT,
    ROUND(COUNT(ROOM_ID) * 100.0 / (SELECT COUNT(*) FROM ROOM), 2) AS PERCENTAGE
FROM 
    ROOM
WHERE 
    STATUS = 'Occupied'
UNION ALL
SELECT 
    'Available' AS STATUS,
    COUNT(ROOM_ID) AS ROOM_COUNT,
    ROUND(COUNT(ROOM_ID) * 100.0 / (SELECT COUNT(*) FROM ROOM), 2) AS PERCENTAGE
FROM 
    ROOM
WHERE 
    STATUS = 'Available';

-- ============================================================================
-- VIEW 12: LOW INVENTORY ITEMS
-- Shows inventory items below average stock level
-- ============================================================================
CREATE OR REPLACE VIEW VIEW_LOW_INVENTORY_ITEMS AS
SELECT 
    INVENTORY_ID,
    ITEM_NAME,
    CATEGORY,
    STOCK_QTY,
    UNIT_PRICE,
    (STOCK_QTY * UNIT_PRICE) AS TOTAL_VALUE
FROM 
    INVENTORY_ITEM
WHERE 
    STOCK_QTY < (SELECT AVG(STOCK_QTY) FROM INVENTORY_ITEM)
ORDER BY 
    STOCK_QTY ASC;

-- ============================================================================
-- END OF VIEWS CREATION SCRIPT
-- ============================================================================
