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