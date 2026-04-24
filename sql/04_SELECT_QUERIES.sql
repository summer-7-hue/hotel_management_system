-- ============================================================================
-- HOTEL MANAGEMENT SYSTEM - SELECT QUERIES & REPORTS
-- ============================================================================
-- Business intelligence queries for analysis and reporting
-- ============================================================================

-- ============================================================================
-- QUERY 1: COMPLETE RESERVATION PROFILE WITH ALL DETAILS
-- ============================================================================
SELECT
    R.RESERVATION_ID,
    G.GUEST_NAME,
    G.EMAIL,
    RM.ROOM_ID,
    RM.ROOM_TYPE,
    RT.PRICE AS ROOM_PRICE,
    RT.CAPACITY,
    S.STAFF_NAME,
    R.CHECKIN_DATE,
    R.CHECKOUT_DATE,
    (R.CHECKOUT_DATE - R.CHECKIN_DATE) AS STAY_DURATION,
    R.NO_OF_GUESTS,
    R.STATUS,
    R.BOOKING_DATE
FROM
    RESERVATION R
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
    JOIN ROOM RM ON R.ROOM_ID = RM.ROOM_ID
    JOIN ROOM_TYPE RT ON RM.ROOM_TYPE = RT.ROOM_TYPE
    JOIN STAFF S ON R.STAFF_ID = S.STAFF_ID
ORDER BY 
    R.BOOKING_DATE DESC;

-- ============================================================================
-- QUERY 2: CURRENTLY OCCUPIED ROOMS WITH GUEST INFORMATION
-- ============================================================================
SELECT
    RM.ROOM_ID,
    RM.ROOM_TYPE,
    RM.FLOOR_NO,
    G.GUEST_NAME,
    G.EMAIL,
    (R.CHECKOUT_DATE - R.CHECKIN_DATE) AS STAY_DAYS,
    R.CHECKIN_DATE,
    R.CHECKOUT_DATE
FROM
    ROOM RM
    JOIN RESERVATION R ON RM.ROOM_ID = R.ROOM_ID
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
WHERE
    RM.STATUS = 'Occupied'
    AND R.STATUS = 'Booked'
ORDER BY 
    RM.ROOM_ID;

-- ============================================================================
-- QUERY 3: AVAILABLE ROOMS BY TYPE AND FLOOR
-- ============================================================================
SELECT
    RT.ROOM_TYPE,
    RT.PRICE,
    RT.CAPACITY,
    COUNT(RM.ROOM_ID) AS AVAILABLE_COUNT,
    STRING_AGG(RM.ROOM_ID, ', ') AS ROOM_IDS,
    STRING_AGG(RM.FLOOR_NO, ', ') AS FLOORS
FROM
    ROOM RM
    JOIN ROOM_TYPE RT ON RM.ROOM_TYPE = RT.ROOM_TYPE
WHERE
    RM.STATUS = 'Available'
GROUP BY
    RT.ROOM_TYPE,
    RT.PRICE,
    RT.CAPACITY
ORDER BY 
    RT.PRICE DESC;

-- ============================================================================
-- QUERY 4: TOTAL SERVICE CHARGES PER RESERVATION
-- ============================================================================
SELECT
    R.RESERVATION_ID,
    G.GUEST_NAME,
    COUNT(DISTINCT SU.SERVICE_ID) AS SERVICE_COUNT,
    SUM(SU.QUANTITY) AS TOTAL_QUANTITY,
    SUM(SU.QUANTITY * S.PRICE) AS TOTAL_SERVICE_COST
FROM
    RESERVATION R
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
    JOIN SERVICE_USAGE SU ON R.RESERVATION_ID = SU.RESERVATION_ID
    JOIN SERVICE S ON SU.SERVICE_ID = S.SERVICE_ID
GROUP BY
    R.RESERVATION_ID,
    G.GUEST_NAME
ORDER BY 
    TOTAL_SERVICE_COST DESC;

-- ============================================================================
-- QUERY 5: DETAILED BILLING SUMMARY BY GUEST
-- ============================================================================
SELECT
    G.GUEST_NAME,
    G.GUEST_ID,
    COUNT(DISTINCT R.RESERVATION_ID) AS TOTAL_STAYS,
    I.INVOICE_ID,
    I.TOTAL_AMOUNT,
    I.INVOICE_STATUS,
    I.INVOICE_DATE
FROM
    GUEST G
    JOIN RESERVATION R ON G.GUEST_ID = R.GUEST_ID
    JOIN INVOICE I ON R.RESERVATION_ID = I.RESERVATION_ID
ORDER BY 
    G.GUEST_NAME,
    I.INVOICE_DATE DESC;

-- ============================================================================
-- QUERY 6: IDENTIFY OVERDUE/UNPAID INVOICES
-- ============================================================================
SELECT
    I.INVOICE_ID,
    I.RESERVATION_ID,
    G.GUEST_NAME,
    R.CHECKIN_DATE,
    R.CHECKOUT_DATE,
    I.TOTAL_AMOUNT,
    I.INVOICE_STATUS,
    I.INVOICE_DATE,
    (SYSDATE - I.INVOICE_DATE) AS DAYS_PENDING,
    CASE 
        WHEN SYSDATE - I.INVOICE_DATE > 30 THEN 'OVERDUE'
        WHEN SYSDATE - I.INVOICE_DATE > 15 THEN 'DUE SOON'
        ELSE 'PENDING'
    END AS PAYMENT_STATUS
FROM
    INVOICE I
    JOIN RESERVATION R ON I.RESERVATION_ID = R.RESERVATION_ID
    JOIN GUEST G ON R.GUEST_ID = G.GUEST_ID
WHERE
    I.INVOICE_STATUS IN ('Unpaid', 'Partial')
ORDER BY 
    I.INVOICE_DATE ASC;

-- ============================================================================
-- QUERY 7: TOP SERVICES BY USAGE AND REVENUE
-- ============================================================================
SELECT
    S.SERVICE_ID,
    S.SERVICE_NAME,
    S.PRICE,
    COUNT(SU.SERVICE_ID) AS TOTAL_ORDERS,
    SUM(SU.QUANTITY) AS TOTAL_QUANTITY,
    SUM(SU.QUANTITY * S.PRICE) AS TOTAL_REVENUE
FROM
    SERVICE S
    LEFT JOIN SERVICE_USAGE SU ON S.SERVICE_ID = SU.SERVICE_ID
GROUP BY
    S.SERVICE_ID,
    S.SERVICE_NAME,
    S.PRICE
ORDER BY 
    TOTAL_REVENUE DESC;

-- ============================================================================
-- QUERY 8: ROOMS CURRENTLY UNDER MAINTENANCE
-- ============================================================================
SELECT
    M.MAINTENANCE_ID,
    RM.ROOM_ID,
    RM.ROOM_TYPE,
    RM.FLOOR_NO,
    S.STAFF_NAME,
    S.ROLE,
    M.DESCRIPTION,
    M.STATUS,
    M.REQUEST_DATE,
    (SYSDATE - M.REQUEST_DATE) AS DAYS_OUTSTANDING
FROM
    MAINTENANCE M
    JOIN ROOM RM ON M.ROOM_ID = RM.ROOM_ID
    JOIN STAFF S ON M.STAFF_ID = S.STAFF_ID
WHERE
    M.STATUS != 'Resolved'
ORDER BY 
    M.REQUEST_DATE ASC;

-- ============================================================================
-- QUERY 9: INVENTORY ITEMS REQUIRING REORDER
-- ============================================================================
SELECT
    INVENTORY_ID,
    ITEM_NAME,
    CATEGORY,
    UNIT_PRICE,
    STOCK_QTY,
    (SELECT AVG(STOCK_QTY) FROM INVENTORY_ITEM) AS AVG_STOCK,
    (UNIT_PRICE * STOCK_QTY) AS TOTAL_VALUE,
    CASE 
        WHEN STOCK_QTY = 0 THEN 'CRITICAL - ORDER IMMEDIATELY'
        WHEN STOCK_QTY < (SELECT AVG(STOCK_QTY) FROM INVENTORY_ITEM) * 0.5 THEN 'LOW - ORDER SOON'
        ELSE 'ADEQUATE'
    END AS STOCK_STATUS
FROM
    INVENTORY_ITEM
WHERE
    STOCK_QTY < (SELECT AVG(STOCK_QTY) FROM INVENTORY_ITEM)
ORDER BY 
    STOCK_QTY ASC;

-- ============================================================================
-- QUERY 10: DEPARTMENT-WISE STAFF AND SALARY ANALYSIS
-- ============================================================================
SELECT
    D.DEPT_ID,
    D.DEPT_NAME,
    COUNT(S.STAFF_ID) AS TOTAL_STAFF,
    SUM(S.SALARY) AS TOTAL_SALARY,
    AVG(S.SALARY) AS AVERAGE_SALARY,
    MIN(S.SALARY) AS MIN_SALARY,
    MAX(S.SALARY) AS MAX_SALARY
FROM
    DEPARTMENT D
    LEFT JOIN STAFF S ON D.DEPT_ID = S.DEPT_ID
GROUP BY
    D.DEPT_ID,
    D.DEPT_NAME
ORDER BY 
    TOTAL_SALARY DESC;

-- ============================================================================
-- QUERY 11: STAFF PERFORMANCE - RESERVATIONS HANDLED
-- ============================================================================
SELECT
    S.STAFF_ID,
    S.STAFF_NAME,
    S.ROLE,
    D.DEPT_NAME,
    COUNT(R.RESERVATION_ID) AS RESERVATIONS_HANDLED,
    COUNT(DISTINCT R.GUEST_ID) AS UNIQUE_GUESTS,
    SUM(I.TOTAL_AMOUNT) AS TOTAL_REVENUE_GENERATED
FROM
    STAFF S
    LEFT JOIN DEPARTMENT D ON S.DEPT_ID = D.DEPT_ID
    LEFT JOIN RESERVATION R ON S.STAFF_ID = R.STAFF_ID
    LEFT JOIN INVOICE I ON R.RESERVATION_ID = I.RESERVATION_ID
GROUP BY
    S.STAFF_ID,
    S.STAFF_NAME,
    S.ROLE,
    D.DEPT_NAME
ORDER BY 
    RESERVATIONS_HANDLED DESC;

-- ============================================================================
-- QUERY 12: DAILY REVENUE REPORT
-- ============================================================================
SELECT
    P.PAYMENT_DATE,
    P.PAYMENT_METHOD,
    COUNT(P.PAYMENT_ID) AS TRANSACTION_COUNT,
    SUM(P.AMOUNT) AS DAILY_TOTAL,
    ROUND(SUM(P.AMOUNT) / COUNT(P.PAYMENT_ID), 2) AS AVERAGE_TRANSACTION
FROM
    PAYMENT P
GROUP BY
    P.PAYMENT_DATE,
    P.PAYMENT_METHOD
ORDER BY 
    P.PAYMENT_DATE DESC;

-- ============================================================================
-- QUERY 13: MONTHLY REVENUE COMPARISON
-- ============================================================================
SELECT
    EXTRACT(MONTH FROM I.INVOICE_DATE) AS MONTH,
    EXTRACT(YEAR FROM I.INVOICE_DATE) AS YEAR,
    COUNT(DISTINCT I.INVOICE_ID) AS INVOICE_COUNT,
    COUNT(DISTINCT R.RESERVATION_ID) AS RESERVATION_COUNT,
    SUM(I.TOTAL_AMOUNT) AS TOTAL_REVENUE,
    ROUND(AVG(I.TOTAL_AMOUNT), 2) AS AVERAGE_INVOICE
FROM
    INVOICE I
    JOIN RESERVATION R ON I.RESERVATION_ID = R.RESERVATION_ID
GROUP BY
    EXTRACT(YEAR FROM I.INVOICE_DATE),
    EXTRACT(MONTH FROM I.INVOICE_DATE)
ORDER BY 
    YEAR DESC,
    MONTH DESC;

-- ============================================================================
-- QUERY 14: ROOM UTILIZATION ANALYSIS
-- ============================================================================
SELECT
    RM.ROOM_TYPE,
    COUNT(RM.ROOM_ID) AS TOTAL_ROOMS,
    SUM(CASE WHEN RM.STATUS = 'Occupied' THEN 1 ELSE 0 END) AS OCCUPIED_ROOMS,
    SUM(CASE WHEN RM.STATUS = 'Available' THEN 1 ELSE 0 END) AS AVAILABLE_ROOMS,
    ROUND(SUM(CASE WHEN RM.STATUS = 'Occupied' THEN 1 ELSE 0 END) * 100.0 / 
          COUNT(RM.ROOM_ID), 2) AS OCCUPANCY_PERCENTAGE
FROM
    ROOM RM
GROUP BY
    RM.ROOM_TYPE
ORDER BY 
    OCCUPANCY_PERCENTAGE DESC;

-- ============================================================================
-- QUERY 15: GUEST FEEDBACK AND RATINGS SUMMARY
-- ============================================================================
SELECT
    G.GUEST_ID,
    G.GUEST_NAME,
    COUNT(F.FEEDBACK_ID) AS TOTAL_FEEDBACKS,
    AVG(F.RATING) AS AVERAGE_RATING,
    MIN(F.RATING) AS MIN_RATING,
    MAX(F.RATING) AS MAX_RATING,
    MAX(F.FEEDBACK_DATE) AS LAST_FEEDBACK_DATE
FROM
    GUEST G
    LEFT JOIN FEEDBACK F ON G.GUEST_ID = F.GUEST_ID
GROUP BY
    G.GUEST_ID,
    G.GUEST_NAME
HAVING 
    COUNT(F.FEEDBACK_ID) > 0
ORDER BY 
    AVERAGE_RATING DESC;

-- ============================================================================
-- END OF SELECT QUERIES & REPORTS
-- ============================================================================
