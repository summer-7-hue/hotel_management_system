-- ============================================================================
-- HOTEL MANAGEMENT SYSTEM - DATABASE CREATION SCRIPT
-- Course: Database System
-- Project: Hotel Management System
-- ============================================================================
-- This script creates all necessary tables for the HMS with proper
-- normalization (3NF), constraints, and relationships
-- ============================================================================

-- Drop existing tables (optional - for fresh setup)
-- DROP TABLE RESERVATION_LOG;
-- DROP TABLE HOUSEKEEPING;
-- DROP TABLE MAINTENANCE;
-- DROP TABLE FEEDBACK;
-- DROP TABLE SERVICE_USAGE;
-- DROP TABLE INVENTORY_PURCHASE;
-- DROP TABLE PAYMENT;
-- DROP TABLE INVOICE;
-- DROP TABLE RESERVATION;
-- DROP TABLE GUEST_CONTACT;
-- DROP TABLE GUEST_ID_PROOF;
-- DROP TABLE GUEST;
-- DROP TABLE ROOM;
-- DROP TABLE ROOM_TYPE;
-- DROP TABLE INVENTORY_ITEM;
-- DROP TABLE SUPPLIER;
-- DROP TABLE STAFF;
-- DROP TABLE DEPARTMENT;

-- ============================================================================
-- TABLE 1: DEPARTMENT
-- ============================================================================
CREATE TABLE DEPARTMENT
(
    DEPT_ID     NUMBER(4) PRIMARY KEY,
    DEPT_NAME   VARCHAR2(30) NOT NULL
);

-- ============================================================================
-- TABLE 2: STAFF
-- ============================================================================
CREATE TABLE STAFF (
    STAFF_ID        NUMBER(4) PRIMARY KEY,
    STAFF_NAME      VARCHAR2(50) NOT NULL,
    ROLE            VARCHAR2(20) NOT NULL,
    SALARY          NUMBER(10,2) CHECK (SALARY > 0),
    SHIFT_TIMING    VARCHAR2(20),
    DEPT_ID         NUMBER(4),
    CONSTRAINT FK_DEPT
        FOREIGN KEY (DEPT_ID)
        REFERENCES DEPARTMENT(DEPT_ID)
);

-- ============================================================================
-- TABLE 3: ROOM_TYPE
-- ============================================================================
CREATE TABLE ROOM_TYPE (
    ROOM_TYPE       VARCHAR2(20) PRIMARY KEY,
    PRICE           NUMBER(8,2) NOT NULL CHECK (PRICE > 0),
    CAPACITY        NUMBER(2) NOT NULL CHECK (CAPACITY > 0)
);

-- ============================================================================
-- TABLE 4: ROOM
-- ============================================================================
CREATE TABLE ROOM (
    ROOM_ID         NUMBER(4) PRIMARY KEY,
    ROOM_TYPE       VARCHAR2(20) REFERENCES ROOM_TYPE(ROOM_TYPE),
    STATUS          VARCHAR2(10) DEFAULT 'Available',
    FLOOR_NO        NUMBER(2) NOT NULL
);

-- ============================================================================
-- TABLE 5: GUEST
-- ============================================================================
CREATE TABLE GUEST (
    GUEST_ID        NUMBER(4) PRIMARY KEY,
    GUEST_NAME      VARCHAR2(50) NOT NULL,
    EMAIL           VARCHAR2(255) UNIQUE NOT NULL
);

-- ============================================================================
-- TABLE 6: GUEST_CONTACT (Separated for multi-valued attribute)
-- ============================================================================
CREATE TABLE GUEST_CONTACT (
    GUEST_ID        NUMBER(4) REFERENCES GUEST(GUEST_ID),
    CONTACT         VARCHAR2(15),
    PRIMARY KEY (GUEST_ID, CONTACT)
);

-- ============================================================================
-- TABLE 7: GUEST_ID_PROOF (Separated for multi-valued attribute)
-- ============================================================================
CREATE TABLE GUEST_ID_PROOF (
    GUEST_ID        NUMBER(4) REFERENCES GUEST(GUEST_ID),
    ID_PROOF        VARCHAR2(20),
    PRIMARY KEY (GUEST_ID, ID_PROOF)
);

-- ============================================================================
-- TABLE 8: SERVICE
-- ============================================================================
CREATE TABLE SERVICE (
    SERVICE_ID      NUMBER(4) PRIMARY KEY,
    SERVICE_NAME    VARCHAR2(30) NOT NULL,
    PRICE           NUMBER(8,2) NOT NULL
);

-- ============================================================================
-- TABLE 9: RESERVATION
-- ============================================================================
CREATE TABLE RESERVATION (
    RESERVATION_ID  NUMBER(4) PRIMARY KEY,
    GUEST_ID        NUMBER(4) REFERENCES GUEST(GUEST_ID),
    ROOM_ID         NUMBER(4) REFERENCES ROOM(ROOM_ID),
    STAFF_ID        NUMBER(4) REFERENCES STAFF(STAFF_ID),
    CHECKIN_DATE    DATE NOT NULL,
    CHECKOUT_DATE   DATE NOT NULL,
    STATUS          VARCHAR2(15) DEFAULT 'Booked',
    NO_OF_GUESTS    NUMBER(2) CHECK (NO_OF_GUESTS > 0),
    BOOKING_DATE    DATE DEFAULT SYSDATE,
    CONSTRAINT CHK_DATES CHECK (CHECKOUT_DATE > CHECKIN_DATE)
);

-- ============================================================================
-- TABLE 10: SERVICE_USAGE (Many-to-Many Relationship)
-- ============================================================================
CREATE TABLE SERVICE_USAGE (
    RESERVATION_ID  NUMBER(4) REFERENCES RESERVATION(RESERVATION_ID),
    SERVICE_ID      NUMBER(4) REFERENCES SERVICE(SERVICE_ID),
    QUANTITY        NUMBER(3) DEFAULT 1 CHECK (QUANTITY > 0),
    USAGE_DATE      DATE DEFAULT SYSDATE,
    PRIMARY KEY (RESERVATION_ID, SERVICE_ID, USAGE_DATE)
);

-- ============================================================================
-- TABLE 11: INVOICE
-- ============================================================================
CREATE TABLE INVOICE (
    INVOICE_ID      NUMBER(4) PRIMARY KEY,
    RESERVATION_ID  NUMBER(4) NOT NULL,
    INVOICE_DATE    DATE NOT NULL,
    TOTAL_AMOUNT    NUMBER(10,2) DEFAULT 0 CHECK (TOTAL_AMOUNT >= 0),
    INVOICE_STATUS  VARCHAR2(15) NOT NULL,
    CONSTRAINT FK_RESERVATION 
        FOREIGN KEY (RESERVATION_ID) 
        REFERENCES RESERVATION(RESERVATION_ID)
);

-- ============================================================================
-- TABLE 12: PAYMENT
-- ============================================================================
CREATE TABLE PAYMENT (
    PAYMENT_ID      NUMBER(4) PRIMARY KEY,
    INVOICE_ID      NUMBER(4) REFERENCES INVOICE(INVOICE_ID),
    PAYMENT_METHOD  VARCHAR2(20) NOT NULL CHECK (PAYMENT_METHOD IN ('Cash', 'Card', 'Online')),
    PAYMENT_DATE    DATE DEFAULT SYSDATE,
    AMOUNT          NUMBER(10,2) NOT NULL CHECK (AMOUNT > 0)
);

-- ============================================================================
-- TABLE 13: SUPPLIER
-- ============================================================================
CREATE TABLE SUPPLIER (
    SUPPLIER_ID     NUMBER(4) PRIMARY KEY,
    SUPPLIER_NAME   VARCHAR2(50) NOT NULL,
    CONTACT         VARCHAR2(15),
    ADDRESS         VARCHAR2(100)
);

-- ============================================================================
-- TABLE 14: INVENTORY_ITEM
-- ============================================================================
CREATE TABLE INVENTORY_ITEM (
    INVENTORY_ID    NUMBER(4) PRIMARY KEY,
    ITEM_NAME       VARCHAR2(50) NOT NULL,
    CATEGORY        VARCHAR2(30),
    UNIT_PRICE      NUMBER(8,2) CHECK (UNIT_PRICE >= 0),
    STOCK_QTY       NUMBER(5) DEFAULT 0
);

-- ============================================================================
-- TABLE 15: INVENTORY_PURCHASE
-- ============================================================================
CREATE TABLE INVENTORY_PURCHASE (
    PURCHASE_ID     NUMBER(4) PRIMARY KEY,
    INVENTORY_ID    NUMBER(4) REFERENCES INVENTORY_ITEM(INVENTORY_ID),
    SUPPLIER_ID     NUMBER(4) REFERENCES SUPPLIER(SUPPLIER_ID),
    STAFF_ID        NUMBER(4) REFERENCES STAFF(STAFF_ID),
    QTY_PURCHASED   NUMBER(5) NOT NULL CHECK (QTY_PURCHASED > 0),
    TOTAL_COST      NUMBER(10,2),
    PURCHASE_DATE   DATE DEFAULT SYSDATE
);

-- ============================================================================
-- TABLE 16: HOUSEKEEPING
-- ============================================================================
CREATE TABLE HOUSEKEEPING (
    HK_ID           NUMBER(4) PRIMARY KEY,
    ROOM_ID         NUMBER(4) REFERENCES ROOM(ROOM_ID),
    STAFF_ID        NUMBER(4) REFERENCES STAFF(STAFF_ID),
    CLEANING_DATE   DATE DEFAULT SYSDATE,
    STATUS          VARCHAR2(15) CHECK (STATUS IN ('Clean', 'Dirty', 'In-Progress'))
);

-- ============================================================================
-- TABLE 17: MAINTENANCE
-- ============================================================================
CREATE TABLE MAINTENANCE (
    MAINTENANCE_ID  NUMBER(4) PRIMARY KEY,
    ROOM_ID         NUMBER(4) REFERENCES ROOM(ROOM_ID),
    STAFF_ID        NUMBER(4) REFERENCES STAFF(STAFF_ID),
    DESCRIPTION     VARCHAR2(200) NOT NULL,
    STATUS          VARCHAR2(15) CHECK (STATUS IN ('Reported', 'In-Progress', 'Resolved')),
    REQUEST_DATE    DATE DEFAULT SYSDATE
);

-- ============================================================================
-- TABLE 18: FEEDBACK
-- ============================================================================
CREATE TABLE FEEDBACK (
    FEEDBACK_ID     NUMBER(4) PRIMARY KEY,
    GUEST_ID        NUMBER(4) REFERENCES GUEST(GUEST_ID),
    RATING          NUMBER(1) NOT NULL CHECK (RATING BETWEEN 1 AND 5),
    COMMENT         VARCHAR2(200),
    FEEDBACK_DATE   DATE DEFAULT SYSDATE
);

-- ============================================================================
-- TABLE 19: RESERVATION_LOG
-- ============================================================================
CREATE TABLE RESERVATION_LOG (
    LOG_ID          NUMBER(6) PRIMARY KEY,
    RESERVATION_ID  NUMBER(4) REFERENCES RESERVATION(RESERVATION_ID),
    ACTION          VARCHAR2(50) NOT NULL,
    ACTION_DATE     DATE DEFAULT SYSDATE,
    REMARKS         VARCHAR2(255)
);

-- ============================================================================
-- END OF TABLE CREATION SCRIPT
-- ============================================================================
