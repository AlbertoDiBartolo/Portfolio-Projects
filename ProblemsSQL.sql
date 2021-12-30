/*

https://leetcode.com/problems/department-highest-salary/
Table Employee
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| id           | int     |
| name         | varchar |
| salary       | int     |
| departmentId | int     |
+--------------+---------+
id is the primary key column for this table.
departmentId is a foreign key of the ID from the Department table.
Each row of this table indicates the ID, name, and salary of an employee. It also contains the ID of their department.

Table Department
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
+-------------+---------+
id is the primary key column for this table.
Each row of this table indicates the ID of a department and its name.

Write an SQL query to find employees who have the highest salary in each of the departments.
Return the result table in any order.
The query result format is in the following example.

Desired Output Format: 
+------------+----------+--------+
| Department | Employee | Salary |
+------------+----------+--------+
| IT         | Jim      | 90000  |
| Sales      | Henry    | 80000  |
| IT         | Max      | 90000  |
+------------+----------+--------+

*/
USE [Practice];

-- setup

CREATE TABLE Employee (
	id int NOT NULL,
	name nvarchar(50) NOT NULL,
	salary int NOT NULL,
	departmentId int NOT NULL);

INSERT INTO Employee VALUES
	(1,'Jon',60000,1),(2,'Al',60000,1),(3,'Amy',45000,1),(4,'Sarah',60000,2),(5,'Rob',60000,2),(6,'Matt',60000,2),(7,'Eva',55000,2),(8,'Nick',45000,3)

CREATE TABLE Department (
	id int NOT NULL,
	name varchar(50) NOT NULL);

INSERT INTO Department VALUES
	(1, 'Sales'), (2, 'Marketing'), (3, 'IT');
	
-- solution

WITH RankedSalary AS
(
	SELECT Department.name AS Department, Employee.name AS Employee, Employee.salary AS Salary,
		RANK() OVER (PARTITION BY department.name ORDER BY employee.salary DESC) AS TopSalary
	FROM Department
	JOIN Employee
	ON Department.id = Employee.departmentId
)

SELECT Department, Employee, Salary
FROM RankedSalary
WHERE TopSalary = 1
ORDER BY 1

/*
PROBLEM 2
https://leetcode.com/problems/trips-and-users/

Table: Trips

+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| id          | int      |
| client_id   | int      |
| driver_id   | int      |
| city_id     | int      |
| status      | enum     |
| request_at  | date     |     
+-------------+----------+
id is the primary key for this table.
The table holds all taxi trips. Each trip has a unique id, while client_id and driver_id are foreign keys to the users_id at the Users table.
Status is an ENUM type of ('completed', 'cancelled_by_driver', 'cancelled_by_client').

Table: Users

+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| users_id    | int      |
| banned      | enum     |
| role        | enum     |
+-------------+----------+
users_id is the primary key for this table.
The table holds all users. Each user has a unique users_id, and role is an ENUM type of ('client', 'driver', 'partner').
banned is an ENUM type of ('Yes', 'No').

The cancellation rate is computed by dividing the number of canceled (by client or driver) requests
with unbanned users by the total number of requests with unbanned users on that day.
Write a SQL query to find the cancellation rate of requests with unbanned users (both client and driver must not be banned)
each day between "2013-10-01" and "2013-10-03". Round Cancellation Rate to two decimal points.
Return the result table in any order.

*/

USE [Practice];

-- setup

CREATE TABLE Trips (
	id int NOT NULL,
	client_id int NOT NULL,
	driver_id int NOT NULL,
	city_id int NOT NULL,
	status varchar(50) NULL,
	request_at date NOT NULL);

INSERT INTO Trips VALUES
	(1,1,10,1,'completed','2013-10-01'),
	(2,2,11,1,'cancelled_by_driver','2013-10-01'),
	(3,3,12,6,'completed','2013-10-01'),
	(4,4,13,6,'cancelled_by_client','2013-10-01'),
	(5,1,10,1,'completed','2013-10-02'),
	(6,2,11,6,'completed','2013-10-02'),
	(7,3,12,6,'completed','2013-10-02'),
	(8,2,12,12,'completed','2013-10-03'),
	(9,3,10,12,'completed','2013-10-03'),
	(10,4,13,12,'cancelled_by_driver','2013-10-03');

CREATE TABLE Users (
	users_id int NOT NULL,
	banned varchar(50) NOT NULL,
	role varchar(50) NOT NULL);

INSERT INTO Users VALUES
	(1,'No','client'),
	(2,'Yes','client'),
	(3,'No','client'),
	(4,'No','client'),
	(10,'No','driver'),
	(11,'No','driver'),
	(12,'No','driver'),
	(13,'No','driver');

-- solution

SELECT request_at AS "Day",
       CAST(ROUND(SUM(CASE
					       WHEN status LIKE 'can%' THEN 1.00 ELSE 0.00
					  END) / Count(*),2) AS DECIMAL(3,2)) AS "Cancellation Rate"
FROM
(
 SELECT *
 FROM Trips
 WHERE client_id NOT IN (SELECT users_id FROM Users WHERE role = 'client' AND banned = 'Yes')
 AND driver_id NOT IN (SELECT users_id FROM Users WHERE role = 'driver' AND banned = 'Yes')
 AND request_at BETWEEN '2013-10-01' AND '2013-10-03'
) subquery  -- subquery with not banned and in time range
GROUP BY request_at

/*
PROBLEM 4
https://www.hackerrank.com/challenges/15-days-of-learning-sql/problem
Write a query to print total number of unique hackers who made at least one submission each day
(starting on the first day of the contest), and find the hacker_id and name of the hacker
who made maximum number of submissions each day. If more than one such hacker has a maximum
number of submissions, print the lowest hacker_id. The query should print this information
for each day of the contest, sorted by the date.
*/

USE [Practice];

-- setup

CREATE TABLE submissions (
	submission_date date,
	submission_id int,
	hacker_id int,
	score int);

INSERT INTO submissions VALUES 
	('2016-03-01', 8494, 20703, 0),('2016-03-01', 22403, 53473,15),
	('2016-03-01',23965,79722,60),('2016-03-01',30173,36396,70),
	('2016-03-02',34928,20703,0),('2016-03-02',38740,15758,60),
	('2016-03-02',42769,79722,25),('2016-03-02',44364,79722,60),
	('2016-03-03',45440,20703,0),('2016-03-03',49050,36396,70),
	('2016-03-03',50273,79722,5),('2016-03-04',50344,20703,0),
	('2016-03-04',51360,44065,90),('2016-03-04',54404,53473,65),
	('2016-03-04',61533,79722,45),('2016-03-05',72852,20703,0),
	('2016-03-05',74546,38289,0),('2016-03-05',76487,62529,0),
	('2016-03-05',82439,36396,10),('2016-03-05',90006,36396,40),
	('2016-03-06',90404,20703,0);

CREATE TABLE hackers (
	hacker_id int, name varchar(50));

INSERT INTO hackers VALUES 
	(15758, 'Rose'),(20703, 'Angela'),
	(36396,'Frank'),(38289, 'Patrick'),
	(44065, 'Lisa'),(53473,'Kimberly'),
	(62529, 'Bonnie'),(79722, 'Michael');

-- solution

SELECT q1.submission_date, q1.recurring_users, q2.hacker_id, hackers.name
FROM
(
	SELECT submission_date,
		SUM(CASE
			 WHEN rolling_count = date_order THEN 1 ELSE 0  -- if a user submitted on each day until the day with rank = date_order
		    END) AS recurring_users				-- then the user's rolling_count at that date is = to the date_order
									-- therefore we count the user, otherwise we don't
	FROM
	(
		SELECT submission_date, hacker_id,
			COUNT(hacker_id) OVER (PARTITION BY hacker_id ORDER BY submission_date ASC) AS rolling_count,  -- rolling count
			DENSE_RANK() OVER (ORDER BY submission_date ASC) AS date_order  -- rank the dates from 1 to 6
		FROM submissions
		GROUP BY submission_date, hacker_id  -- GROUP BY both to get rid of users who submitted more than once on a certain day
	) rc  -- subquery to do a rolling count of the users submitting at least once per day
	GROUP BY submission_date
) q1  -- query 1 to return the rolling count of users who submitted each day until a given date

JOIN  -- join q1 and q2

(
	SELECT submission_date, hacker_id, daily_sub,
		RANK() OVER (PARTITION BY submission_date ORDER BY daily_sub DESC, hacker_id ASC) sub_rank
	FROM
	(
		SELECT submission_date, hacker_id, COUNT(hacker_id) AS daily_sub
		FROM submissions
		GROUP BY submission_date, hacker_id
	) AS count_sub  -- subquery to count the number of daily submissions per user
) q2  -- subquery to rank the daily submissions on the basis of quantity and ID
ON q1.submission_date = q2.submission_date AND q2.sub_rank = 1  -- join on date and consider only rank 1 users
JOIN hackers
ON hackers.hacker_id = q2.hacker_id  -- join the user name
