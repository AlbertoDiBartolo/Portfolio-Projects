/*
SQL PRACTICE
Cleaning customer info table, assigning constraints, etc
Table fields:
CustomerID | CustomerFirstName | CustomerLastName | CustomerPhoneNumber | CustomerEmail | DateOfRegistration | DateOfBirth
*/

USE [Practice];

-- Assign NOT NULL and UNIQUE constraints
ALTER TABLE [dbo].[Customer] ALTER COLUMN [DateOfBirth] DATE NOT NULL;
ALTER TABLE [dbo].[Customer] ALTER COLUMN [DateOfRegistration] DATETIME NOT NULL;
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerID] INT NOT NULL;
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerFirstName] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerLastName] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerEmail] NVARCHAR(320) NOT NULL;
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerPhoneNumber] VARCHAR(15) NOT NULL;
ALTER TABLE [dbo].[Customer] ADD UNIQUE   ([CustomerID], [CustomerEmail], [CustomerPhoneNumber]);

-- Add check constraints to not allow certain characters for certain fields in the future
ALTER TABLE [dbo].[Customer] WITH NO CHECK
ADD CONSTRAINT chk_firstname CHECK
(REPLACE(RTRIM(LTRIM(CustomerFirstName)), '.', '') = CustomerFirstName);
ALTER TABLE [dbo].[Customer] WITH NO CHECK
ADD CONSTRAINT chk_lastname CHECK
(REPLACE(RTRIM(LTRIM(CustomerLastName)), '.', '') = CustomerLastName);
ALTER TABLE [dbo].[Customer] WITH NO CHECK
ADD CONSTRAINT chk_phonenumber CHECK
(REPLACE(REPLACE(REPLACE(REPLACE(CustomerPhoneNumber, '-', ''), ' ', ''), '(', ''), ')', '') = CustomerPhoneNumber);

-- Remove unwanted characters
UPDATE [dbo].[Customer]
SET 	CustomerID = RTRIM(LTRIM(CustomerID)),
	CustomerFirstName = UPPER(REPLACE(RTRIM(LTRIM(CustomerFirstName)), '.', '')),
	CustomerLastName = UPPER(REPLACE(RTRIM(LTRIM(CustomerLastName)), '.', '')),
	CustomerPhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(CustomerPhoneNumber, '-', ''), ' ', ''), '(', ''), ')', '');

-- Create check constraint to only allow 18+ years old
ALTER TABLE [dbo].[Customer]
ADD CONSTRAINT chk_adult CHECK
(DATEDIFF(YEAR, DateOfBirth, GETDATE()) >= 18);

-- Create constraint to only allow phonenumbers with length between 9 and 15 digits
ALTER TABLE [dbo].[Customer]
ADD CONSTRAINT chk_phone CHECK
(LEN(CustomerPhoneNumber) BETWEEN 9 and 15);

/*
Manipulating data to create new tables
	Find customers that havent made any purchase in >= 10, >= 20 or >= 30 months (data from OrdersInfo table)
	Add the customerID to new table "EligibleForDiscount"
	Store the proposed discount as a field in the table
	- 12 months = 10% discount
	- 20 months = 15% discount
	- 30 months = 20% discount
*/

SELECT CustomerID,
	CASE	WHEN MIN(DATEDIFF(MONTH, OrderDate, GETDATE())) >= 30 THEN 20
		WHEN MIN(DATEDIFF(MONTH, OrderDate, GETDATE())) >= 20 THEN 15
		WHEN MIN(DATEDIFF(MONTH, OrderDate, GETDATE())) >= 10 THEN 10
	END AS DiscountPercentage
INTO EligibleForDiscount
FROM OrdersInfo
GROUP BY CustomerID;

/*
	Find customers that have no recorded purchases
	Add the customerID to new table "TerminateAccountAlert"
	Add customerEmail to the table
*/

SELECT Customer.CustomerID, CustomerEmail
INTO TerminateAccountAlert
FROM Customer
LEFT JOIN OrdersInfo
ON Customer.CustomerID = OrdersInfo.CustomerID
WHERE OrdersInfo.OrderID IS NULL;

/*
	Update phone number for customer Simon Smith
	old number 333 7722 313
	new phone number 355 4887 122
*/

UPDATE [dbo].[Customer]
SET CustomerPhoneNumber = '3554887122'
WHERE CustomerPhoneNumber = '3337722313';

