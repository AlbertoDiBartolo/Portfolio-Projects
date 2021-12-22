/*

Cleaning customer info table

	- convert fields to appropriate data type with appropriate constraints
	- clean trailing spaces, unnecessary dots, etc.
	- capitalize names

*/



ALTER TABLE [dbo].[Customer] ALTER COLUMN [DateOfBirth] DATE NOT NULL
ALTER TABLE [dbo].[Customer] ALTER COLUMN [DateOfRegistration] DATETIME NOT NULL
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerID] INT NOT NULL
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerFirstName] NVARCHAR(50) NOT NULL
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerLastName] NVARCHAR(50) NOT NULL
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerEmail] NVARCHAR(320) NOT NULL
ALTER TABLE [dbo].[Customer] ALTER COLUMN [CustomerPhoneNumber] VARCHAR(15) NOT NULL
ALTER TABLE [dbo].[Customer] ADD UNIQUE   ([CustomerID], [CustomerEmail], [CustomerPhoneNumber])

UPDATE [dbo].[Customer]
SET CustomerID = RTRIM(LTRIM(CustomerID)),
	CustomerFirstName = UPPER(REPLACE(RTRIM(LTRIM(CustomerFirstName)), '.', '')),
	CustomerLastName = UPPER(REPLACE(RTRIM(LTRIM(CustomerLastName)), '.', '')),
	CustomerPhoneNumber = REPLACE(REPLACE(REPLACE(REPLACE(CustomerPhoneNumber, '-', ''), ' ', ''), '(', ''), ')', '')



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
GROUP BY CustomerID



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
WHERE OrdersInfo.OrderID IS NULL
