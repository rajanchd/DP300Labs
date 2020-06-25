# Lab 5 -Query Performance Troubleshooting

**Estimated Time**: 60 minutes

**Pre-requisites**: Students will also login to a VM running SQL Server.

**Lab files**: The files for this lab are located in the D:\Labfiles\Query Performance folder.



# Lab overview

The students will evaluate a database design for problems with normalization, data type selection and index design. They will run queries with suboptimal performance, examine the query plans, and attempt to make improvements within the AdventureWorks2017 database.

# Lab objectives

After completing this lab, you will be able to:

1. Identify issues with database design

	- Evaluate queries against database design

	- Examine existing design for potential bad patterns such as over/under normalization or incorrect data types 

2. Isolate problem areas in poorly performing queries 

	- Run query to generate actual execution plan not using the GUI

	- Evaluate given execution plans (such as key lookup) 

3. Use Query Store to detect and handle regressions 

	- Run a workload to generate query statistics for Query Store 

	- Examine Top Resource Consuming Queries to identify poor performance 

	- Force a better execution plan 

4. Use query hints to impact performance 

	- Run workload 

	- Change the query to use a Parameter value

	- Apply query hint to query to optimize for a value 

# Scenario

You have been hired as a Senior Database Administrator to help with performance issues currently happening when users query the AdventureWorks2017 database. Your job is to identify issues in query performance and remedy them using techniques learned in this module.

The first step is to review the queries the users are having issues with and make recommendations:

1. Identify issues with database design within AdventureWorks2017

2. Isolate problem areas in poorly preforming queries in AdventureWorks2017

3. Use Query Store to detect and handle regressions in AdventureWorks2017

4. Use Query Hints to impact performance in AdventureWorks2017

# Exercise 1: Identify issues with database design in AdventureWorks2017

Estimated Time: 15 minutes

The main task for this exercise is as follows:

1. Examine the query and identify why you are seeing a warning and what that warning is.

2. Come up with two ways to fix the issue.

	- Change the query to resolve the issue.

	- Suggest a database design change to fix the issue.

## Task 1: Examine the query and identify the problem**.**

1. From the lab virtual machine, start **SQL Server Management Studio (SSMS).** Start a new query by clicking the New Query button in Management Studio.

	![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-01.png)

2. You will be prompted to connect to your SQL Server.  
‎Enter the server name localhost, and ensure that Windows Authentication is selected, and click connect.

	![Picture 1570495882](images/dp-3300-module-55-lab-02.png)

‎	
3. Start a new query by clicking the New Query button in SQL Server Management Studio. Copy and paste the code below into your query window.

	```sql
	USE AdventureWorks2017;

	SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle 

	FROM HumanResources.Employee 

	WHERE NationalIDNumber = 14417807;
	```
4. Click on Include Actual Execution Plan icon as shown below before running the query or type CTRL+M. This will cause the execution plan to be displayed when you execute the query.
	![A picture containing street, white, mounted, black Description automatically generated](images/dp-3300-module-55-lab-03.png)  
‎

5. Click the execute button to execute this query. 

6. Navigate to the execution plan, by clicking on execution plan tab in the results panel in SSMS. In the execution plan, mouse over the SELECT operator. You will note a warning message identified by an exclamation point in a yellow triangle as shown below. Identify what the Warning Message tells you. 
	![A screenshot of a social media post Description automatically generated](images/dp-3300-module-55-lab-04.png)

	An Implicit Conversion is causing a performance issue.


## Task 2: Identify two ways to fix the warning issue

The structure for the table is shown in the follow data definition language (DDL) statement.

```sql
CREATE TABLE [HumanResources].[Employee](

 [BusinessEntityID] [int] NOT NULL,

 [NationalIDNumber] [nvarchar](15) NOT NULL,

 [LoginID] [nvarchar](256) NOT NULL,

 [OrganizationNode] [hierarchyid] NULL,

 [OrganizationLevel] AS ([OrganizationNode].[GetLevel]()),

 [JobTitle] [nvarchar](50) NOT NULL,

 [BirthDate] [date] NOT NULL,

 [MaritalStatus] [nchar](1) NOT NULL,

 [Gender] [nchar](1) NOT NULL,

 [HireDate] [date] NOT NULL,

 [SalariedFlag] [dbo].[Flag] NOT NULL,

 [VacationHours] [smallint] NOT NULL,

 [SickLeaveHours] [smallint] NOT NULL,

 [CurrentFlag] [dbo].[Flag] NOT NULL,

 [rowguid] [uniqueidentifier] ROWGUIDCOL NOT NULL,

 [ModifiedDate] [datetime] NOT NULL

) ON [PRIMARY]
```


1. Fix the query using code as a solution.

Identify what field is causing the implicit conversion and why. 

If you review the query from Task1, you will note the value compared to the NationalIDNumber column in the WHERE clause is passed in as a number, since it is not in a quoted string. After examining the table structure you will find this column in the table is using the nvarchar(15) datatype and not the int or integer data type. This data type inconsistency causes the optimizer to implicitly convert the constant to a nvarchar upon execution causing additional overhead to the query performance with a suboptimal plan.

2. Change the code to resolve the implicit conversion and rerun the query. Remember to turn on the Include Actual Execution Plan (Cntl+M) if it is not already on from the exercise above. Note the warning is now gone.

Changing the WHERE clause so that the value compared to the NationalIDNumber column matches the column’s data type in the table, you can get rid of the implicit conversion. In this scenario just adding a single quote on each side of the value changes it from a number to a character format. Keep the query window open for this query.

```sql
SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle 

FROM HumanResources.Employee 

WHERE NationalIDNumber = '14417807'
```

![A screenshot of a social media post Description automatically generated](images/dp-3300-module-55-lab-05.png)

3. Fix the query using database design changes. 

To attempt to fix the index, in a new query window, copy and paste the query below to change the column’s data type. Attempt to execute the query, by clicking Execute or pressing F5.

```sql
ALTER TABLE [HumanResources].[Employee] ALTER COLUMN [NationalIDNumber] INT NOT NULL;
```

The changes to the table would solve the conversion issue. However this change introduces another issue that as a database administrator you need to resolve. Since this column is part of an already existing nonclustered index, the index has to be rebuilt/recreated in order to execute the data type change. This could lead to extended downtime in production, which highlights the importance of choosing the right data types in your design. 

Msg 5074, Level 16, State 1, Line 1The index 'AK_Employee_NationalIDNumber' is dependent on column 'NationalIDNumber'.

Msg 4922, Level 16, State 9, Line 1

ALTER TABLE ALTER COLUMN NationalIDNumber failed because one or more objects access this column.

 

4. In order to resolve this issue, copy and paste the code below into your query window and execute it by clicking Execute.

```sql
USE AdventureWorks2017
GO

DROP INDEX [AK_Employee_NationalIDNumber] ON [HumanResources].[Employee]
GO

ALTER TABLE [HumanResources].[Employee] ALTER COLUMN [NationalIDNumber] INT NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [AK_Employee_NationalIDNumber] ON [HumanResources].[Employee]

( [NationalIDNumber] ASC

);
GO
```

5. Rerun the original query without the quotes.

```sql
USE AdventureWorks2017;

SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle 

FROM HumanResources.Employee 

WHERE NationalIDNumber = 14417807;
```

# Exercise 2: Isolate problem areas in poorly performing queries in AdventureWorks2017

Estimated Time: 30 minutes

The tasks for this exercise is as follows:

1. Run query to generate actual execution plan. 

2. Evaluate given execution plans (such as key lookup). 

## Task 1: Run a query to generate actual execution plan

There are several ways to generate an execution plan in SQL Server Management Studio. You will use the same query from Exercise 1. Copy and paste the code below into a new query window and execute it by clicking Execute or pressing the F5 key.

Using the SHOWPLAN_ALL setting we can get the same information as we did in the last exercise but in the results pane instead of the graphical result.

```sql
USE AdventureWorks2017; 

GO 

SET SHOWPLAN_ALL ON; 

GO 

SELECT BusinessEntityID 

FROM HumanResources.Employee 

WHERE NationalIDNumber = '14417807'; 

GO 

SET SHOWPLAN_ALL OFF; 

GO 
```

This shows you a text version of the execution plan.

![Picture 6](images/dp-3300-module-55-lab-06.png)  
‎

## Task 2: Resolve a Performance Problem from an Execution Plan

1. Copy and paste the code below into a new query window. Click on Include Actual Execution Plan icon as shown below before running the query, or type CTRL+M. Execute the query by clicking Execute or pressing the F5 key. Make note of the execution plan and the logical reads in the messages tab.

```sql
SET STATISTICS IO, TIME ON;

SELECT [SalesOrderID] ,[CarrierTrackingNumber] ,[OrderQty] ,[ProductID] ,[UnitPrice] ,[ModifiedDate]

FROM [AdventureWorks2017].[Sales].[SalesOrderDetail]WHERE [ModifiedDate] > '2014/01/01' AND [ProductID] = 772;
```

When reviewing the execution plan you will note there is a key lookup. If you your mouse over the icon, you will see that the properties indicate it is performed for each row retrieved by the query. You can see the execution plan is performing a Key Lookup operation. 

To identify what index needs to be altered in order to remove the key lookup, you need to examine the index seek above it. Hover over the index seek operator with your mouse and the properties of the operator will appear. Make note of the output column as shown below. 


![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-07.png)

![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-08.png)

2. Fix the Key Lookup and rerun the query to see the new plan. Key Lookups are fixed by adding a COVERING index that INCLUDES all fields being returned or searched in the query. In this example the index only had ProductID. If we add the Output List fields to the index as Included Columns, then the Key Lookup will be removed. Since the index already exists you either have to DROP the index and recreate it or set the DROP_EXISTING=ON in order to add the columns. Note ProductID is already part of the index and does not need to be added as an included column.

```sql
CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID]

ON [Sales].[SalesOrderDetail] ([ProductID],[ModifiedDate])

INCLUDE ([CarrierTrackingNumber],[OrderQty],[UnitPrice])

WITH (DROP_EXISTING = on);

GO
```

3. Rerun the query from Step 1. Make note of the changes to the logical reads and execution plan changes

# Exercise 3: Use Query Store to detect and handle regression in AdventureWorks2017.

Estimated Time: 15 minutes

The tasks for this exercise are as follows:

1. Run a workload to generate query statistics for QS 

2. Examine Top Resource Consuming Queries to identify poor performance 

3. Force a better execution plan. 

## Task 1: Run a workload to generate query stats for Query Store

1. Copy and paste the code below into a new query window and execute it by clicking Execute . Make note of the execution plan and the logical reads in the messages tab. This script will enable the Query Store for AdventureWorks2017 and sets the database to Compatibility Level 100

```sql
USE master;
GO

ALTER DATABASE AdventureWorks2017 SET QUERY_STORE = ON;
GO

ALTER DATABASE AdventureWorks2017 SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
GO

ALTER DATABASE AdventureWorks2017 SET COMPATIBILITY_LEVEL = 100;
GO
```


2. Click the File > Open > File control in SQL Server Management Studio. Navigate to the D:\Labfiles\Query Performance\CreateRandomWorkloadGenerator.sql file. Click on the file to load it into Management Studio and then click execute or press F5 to execute the query.

![A screenshot of a social media post Description automatically generated](images/dp-3300-module-55-lab-09.png)

 
3. Run a workload to generate statistics for Query Store. Navigate back to the D:\Labfiles\Query Performance\ExecuteRandomWorkload.sql script to execute a workload. Click execute or press F5 to run the script. After execution completes, run the script a second time. Leave the query tab open for this query.

4. Copy and paste the code below into a new query window and execute it by clicking Execute or pressing the F5 key . This script changes the database compatibility mode using the below script to SQL Server 2019 (150)

```sql
USE master;
GO

ALTER DATABASE AdventureWorks2017 SET COMPATIBILITY_LEVEL = 150;
GO
```

5. Navigate back to the query tab from step 3, and re-execute.

## Task 2: Examine Top Resource Consuming Queries to identify poor performance

1. In order to view the Query Store you will need to refresh the AdventureWorks2017 database in Management Studio. Right click on database name and choose click refresh. You will then see the Query Store option under the database.  
‎
	![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-10.png)  
‎

2. Expand Query Store node to view all available report. Click on plus sign to expand Query Store reports. Choose Top Resource Consuming Queries Report

	![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-11.png)

	The report will open as shown below.  
	‎

	Click configure in the top right.

	![Picture 1037920255](images/dp-3300-module-55-lab-12.png)

	In the configuration screen, change the filter for the minimum number of query plans to 2.

	![Picture 1995201375](images/dp-3300-module-55-lab-13.png)

 

3. Choose the query with the longest duration by clicking on the left most bar in the bar chart in the top left portion of the report.

	![Picture 913191774](images/dp-3300-module-55-lab-14.png)  
‎


	This will show you the query and plan summary for your longest duration query in your query store. 

## Task 3: Force a better execution plan

1. Navigate to the plan summary portion of the report as shown below. You will note there are two execution plans with widely different durations.

	![A screenshot of a social media post Description automatically generated](images/dp-3300-module-55-lab-15.png)  
‎

2. Click on the Plan ID with the lowest duration (this is indicated by a lower position on the Y-axis of the chart) in the top right window of the report. In the graphic above, it’s PlanID 43. Click on the plan ID next to the Plan Summary chart (it should be highlighted like in the above screenshot).

3. Click on **Force Plan** under the summary chart. A confirmation window will popup, choose Yes to force the plan.

	![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-16.png)   
‎

	Once forced you will see that the Forced Plan is now greyed out and the plan in the plan summary window now has a check mark indicating is it forced.

	![A picture containing hawk, eagle, bird Description automatically generated](images/dp-3300-module-55-lab-17.png)

# Exercise 4: Use query hints to impact performance in AdventureWorks2017

The main task for this exercise is as follows:

1. Run a workload. 

2. Change query to use a parameter

3. Apply query hint to query to optimize for a value and re-execute.

## Task 1: Run a workload

1. Run the queries below, examine the Actual Execution Plan (Crtl+M)
	- Click on Include Actual Execution Plan icon before running the query or use CTRL+M.
	![A picture containing street, white, mounted, black Description automatically generated](images/dp-3300-module-55-lab-18.png)  
‎
	- Execute the query below. Note that the execution plan shows an index seek operator.
        ```sql
		USE AdventureWorks2017

		GO

		SELECT SalesOrderId, OrderDate

		FROM Sales.SalesOrderHeader

		WHERE SalesPersonID=288;
        ```
 

		![A screenshot of a cell phone Description automaticallygenerated](images/dp-3300-module-55-lab-19.png)

	- Now run the next query. The only this time change the SalesPersonID value to 277. Note the Clustered Index Scan operation in the execution plan.
        ```sql
		USE [AdventureWorks2017]

		GO

		SELECT SalesOrderId, OrderDate

		FROM Sales.SalesOrderHeader

		WHERE SalesPersonID=277;
        ```
 
		![A screenshot of a cell phone Description automatically generated](images/dp-3300-module-55-lab-20.png)

 

	Based on the column statistics the database optimizer has chosen a different execution plan because of the different values of this where clause. Because this query uses a constant in its WHERE clause, the optimizer sees each of these queries as unique and generates a different execution plan for each one.

## Task 2: Change the query to use a parameter and use a Query Hint

1. Change the query to use a variable value for SalesPersonID.

2. Use the T-SQL DECLARE statement to declare @SalesPersonID so you can pass in a value instead of hard-code the value in the WHERE clause. You should ensure that the data type of your variable matches the data type of the column in the target table. 

```sql
USE AdventureWorks2017
GO


DECLARE @SalesPersonID INT;

SELECT @SalesPersonID = 277; 

SELECT SalesOrderId, OrderDate

FROM Sales.SalesOrderHeader

WHERE SalesPersonID= @SalesPersonID;
```
 

Execute this query again changing the parameter value to 288. If you examine the execution plan, you will note is the same as it was for the value of 277. This is because SQL Server has cached the execution plan and is reusing for the second execution of the query. Note that although the same plan is used for both queries, it is not necessarily the best plan.

```sql
USE AdventureWorks2017
GO

DECLARE @SalesPersonID INT;

SELECT @SalesPersonID = 288; 

SELECT SalesOrderId, OrderDate

FROM Sales.SalesOrderHeader

WHERE SalesPersonID= @SalesPersonID;
```
 

3. Execute the following command to clear the plan cache for the AdventureWorks2017 database

```sql
USE AdventureWorks2017
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
```
4. Now Run the Query with the Query Hint. Review the plan noting it now uses the plan with the index seek created for value 288 even though the @SalesPersonID = 277.

```sql
USE AdventureWorks2017;
GO
 
DECLARE @SalesPersonID int

SELECT @SalesPersonID = 277

SELECT SalesOrderId, OrderDate

from Sales.SalesOrderHeader

WHERE SalesPersonID= @SalesPersonID

OPTION (OPTIMIZE FOR (@SalesPersonID = 288));
```
 
