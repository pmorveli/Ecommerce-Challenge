-- Changing the blank spaces from the ADDRESS_TO_COUNTRY column to proper Nulls

UPDATE Orders
SET ADDRESS_TO_COUNTRY = NULL
WHERE ADDRESS_TO_COUNTRY = ''
GO

-- Changing the blank spaces from the ADDRESS_TO_REGION column to proper Nulls

UPDATE Orders
SET ADDRESS_TO_REGION = NULL
WHERE ADDRESS_TO_REGION = ''
GO

-- Changing the blank spaces from the FULFILLED_DT column to proper Nulls

UPDATE Orders
SET FULFILLED_DT = NULL
WHERE FULFILLED_DT = '1900-01-01 00:00:01'
GO

-- Changing the blank spaces from the SUB_PLAN column to proper Nulls

UPDATE Orders
SET SUB_PLAN = NULL
WHERE SUB_PLAN = ''
GO

-- Changing the blank spaces from the SHIPMENT_CARRIER column to proper Nulls

UPDATE Orders
SET SHIPMENT_CARRIER = NULL
WHERE SHIPMENT_CARRIER = ''
GO

-- Changing the blank spaces from the SHIPMENT_DELIVERD_DT column to proper Nulls

UPDATE Orders
SET SHIPMENT_DELIVERD_DT = NULL
WHERE SHIPMENT_DELIVERD_DT = '1900-01-01 00:00:01'
GO