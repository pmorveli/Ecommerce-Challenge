-- Creating the database and the tables that I will insert the cleaned data into
CREATE DATABASE Printify
go

USE Printify
go

CREATE TABLE orders
(MERCHANT_ID varchar(7),
ORDER_ID varchar(13),
SHOP_ID varchar(7),
ADDRESS_TO_COUNTRY varchar(4),
ADDRESS_TO_REGION varchar(32),
ORDER_DT datetime2,
FULFILLED_DT datetime2,
REPRINT_FLAG varchar(5),
SALES_CHANNEL_TYPE_ID varchar(4),
TOTAL_COST int,
TOTAL_SHIPPING int,
MERCHANT_REGISTERED_DT datetime2,
SUB_IS_ACTIVE_FLAG varchar(5),
SUB_PLAN varchar(18),
SHIPMENT_CARRIER varchar(20),
SHIPMENT_DELIVERD_DT datetime2,
DUPLICATED_ORDER varchar(5))
go

CREATE TABLE line_items
(ORDER_ID varchar(13),
PRINT_PROVIDER_ID varchar(4),
PRODUCT_BRAND varchar(27),
PRODUCT_TYPE varchar(15),
ITEM_STATUS varchar(29),
QUANTITY smallint)
go