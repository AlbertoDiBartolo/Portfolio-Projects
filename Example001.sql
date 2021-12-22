-- Swapping seats pairs in table seats
-- 1 swap 2, 3 swap 4 etc
-- last number (odd) must remain unswapped

SELECT ID,
	CASE
	WHEN ID % 2 = 0 THEN LAG(Student) OVER(ORDER BY ID)
	WHEN ID % 2 = 1 AND ID=
							(SELECT MAX(ID) FROM Seats)
	THEN Student
	ELSE LEAD(Student) OVER(ORDER BY ID)
	END AS SWAPPED
INTO Swapped_seats  -- Add INTO to CREATE a TABLE from the query
FROM Seats
-----------------------------------------------------------------------------------------------------
Select id,
       case when (id % 2 = 0) then  lag(student, 1) over (order by id)
                when (id % 2 = 1) then coalesce (lead(student, 1) over ( order by id), student)
       end as student
        
from Seats
-----------------------------------------------------------------------------------------------------
SELECT ID,
	CASE
	WHEN ID % 2 = 0 THEN LAG(Student) OVER(ORDER BY ID)
	WHEN ID % 2 = 1 AND ID=last_id  -- a little cool trick
	THEN Student
	ELSE LEAD(Student) OVER(ORDER BY ID)
	END AS SWAPPED
FROM Seats, (SELECT MAX(ID) AS last_id FROM Seats) AS a  -- this is another way to pass the max ID



-----------------------------------------------------------------------------------------------------
-- RESUME skills demo

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



Select *
from Customer


/*
	Find customers that havent made any purchase in >= 10, >= 20 or >= 30 months
	Add the customerID to new table "EligibleForDiscount"
	Store the proposed discount as a field in the table
	- 12 months = 10% discount
	- 20 months = 15% discount
	- 30 months = 20% discount
*/



SELECT	CustomerID,
		CASE	WHEN MIN(DATEDIFF(MONTH, OrderDate, GETDATE())) >= 30 THEN 20
				WHEN MIN(DATEDIFF(MONTH, OrderDate, GETDATE())) >= 20 THEN 15
				WHEN MIN(DATEDIFF(MONTH, OrderDate, GETDATE())) >= 10 THEN 10
		END AS DiscountPercentage
INTO EligibleForDiscount
FROM OrdersInfo
GROUP BY CustomerID