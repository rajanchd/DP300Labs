--Start a new query by clicking the New Query button in SQL Server Management Studio. Copy and paste the code below into your query window. 

USE AdventureWorks2017
GO

SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle  
FROM HumanResources.Employee  
WHERE NationalIDNumber = 14417807; 
GO

-- Keep the query window open for this query. 

SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle  
FROM HumanResources.Employee  
WHERE NationalIDNumber = '14417807';
GO

--To attempt to fix the index, in a new query window, copy and paste the query below to change the column’s data type. Attempt to execute the query, by clicking Execute or pressing F5. 

ALTER TABLE [HumanResources].[Employee] ALTER COLUMN [NationalIDNumber] INT NOT NULL; 

--In order to resolve this issue, copy and paste the code below into your query window and execute it by clicking Execute. 

USE AdventureWorks2017 
GO 

DROP INDEX [AK_Employee_NationalIDNumber] ON [HumanResources].[Employee];
GO 

ALTER TABLE [HumanResources].[Employee] ALTER COLUMN [NationalIDNumber] INT NOT NULL; 
GO 

CREATE UNIQUE NONCLUSTERED INDEX [AK_Employee_NationalIDNumber] ON [HumanResources].[Employee] 
(   [NationalIDNumber] ASC 
); 
GO 

--Rerun the original query without the quotes. 

USE AdventureWorks2017
GO

SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle  
FROM HumanResources.Employee  
WHERE NationalIDNumber = 14417807; 
GO

--Using the SHOWPLAN_ALL setting we can get the same information as we did in the last exercise but in the results pane instead of the graphical result. 

USE AdventureWorks2017
GO   

SET SHOWPLAN_ALL ON 
GO   

SELECT BusinessEntityID    
FROM HumanResources.Employee   
WHERE NationalIDNumber = '14417807';   
GO   

SET SHOWPLAN_ALL OFF
GO

--Copy and paste the code below into a new query window. Click on Include Actual Execution Plan icon as shown below before running the query, or type CTRL+M. Execute the query by clicking Execute or pressing the F5 key. Make note of the execution plan and the logical reads in the messages tab. 

SET STATISTICS IO, TIME ON; 
 
SELECT [SalesOrderID]
	,[CarrierTrackingNumber]
	,[OrderQty]
	,[ProductID]
	,[UnitPrice]
	,[ModifiedDate]
FROM [AdventureWorks2017].[Sales].[SalesOrderDetail]
WHERE [ModifiedDate] > '2014/01/01'
	AND [ProductID] = 772;
GO

--Fix the Key Lookup and rerun the query to see the new plan. Key Lookups are fixed by adding a COVERING index that INCLUDES all fields being returned or searched in the query. In this example the index only had ProductID. If we add the Output List fields to the index as Included Columns, then the Key Lookup will be removed. Since the index already exists you either have to DROP the index and recreate it or set the DROP_EXISTING=ON in order to add the columns. Note ProductID is already part of the index and does not need to be added as an included column. 

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] 
ON [Sales].[SalesOrderDetail] ([ProductID],[ModifiedDate]) 
INCLUDE ([CarrierTrackingNumber],[OrderQty],[UnitPrice]) 
WITH (DROP_EXISTING = on); 
GO 

--Copy and paste the code below into a new query window and execute it by clicking Execute . Make note of the execution plan and the logical reads in the messages tab. This script will enable the Query Store for AdventureWorks2017 and sets the database to Compatibility Level 100 

USE master
GO 

ALTER DATABASE AdventureWorks2017 SET QUERY_STORE = ON; 
GO 

ALTER DATABASE AdventureWorks2017 SET QUERY_STORE (OPERATION_MODE = READ_WRITE); 
GO 

ALTER DATABASE AdventureWorks2017 SET COMPATIBILITY_LEVEL = 100; 
GO 

--Copy and paste the code below into a new query window and execute it by clicking Execute or pressing the F5 key . This script changes the database compatibility mode using the below script to SQL Server 2019 (150) 

USE master; 
GO 

ALTER DATABASE AdventureWorks2017 SET COMPATIBILITY_LEVEL = 150; 
GO 

--Execute the query below. Note that the execution plan shows an index seek operator. 

USE AdventureWorks2017 
GO 

SELECT SalesOrderId, OrderDate 
FROM Sales.SalesOrderHeader 
WHERE SalesPersonID=288; 
GO

--Now run the next query. The only this time change the SalesPersonID value to 277. Note the Clustered Index Scan operation in the execution plan. 

USE [AdventureWorks2017] 
GO 

SELECT SalesOrderId, OrderDate 
FROM Sales.SalesOrderHeader 
WHERE SalesPersonID=277; 

--Use the T-SQL DECLARE statement to declare @SalesPersonID so you can pass in a value instead of hard-code the value in the WHERE clause. You should ensure that the data type of your variable matches the data type of the column in the target table.  

USE AdventureWorks2017 
GO 

DECLARE @SalesPersonID INT; 
SELECT @SalesPersonID = 277;  
SELECT SalesOrderId, OrderDate 
FROM Sales.SalesOrderHeader 
WHERE SalesPersonID= @SalesPersonID; 
GO

--Execute this query again changing the parameter value to 288.  If you examine the execution plan, you will note is the same as it was for the value of 277. This is because SQL Server has cached the execution plan and is reusing for the second execution of the query. Note that although the same plan is used for both queries, it is not necessarily the best plan. 

 

USE AdventureWorks2017 
GO 

 

DECLARE @SalesPersonID INT; 
SELECT @SalesPersonID = 288;  

SELECT SalesOrderId, OrderDate 
FROM Sales.SalesOrderHeader 
WHERE SalesPersonID= @SalesPersonID; 
GO


--Execute the following command to clear the plan cache for the AdventureWorks2017 database 

USE AdventureWorks2017 
GO 

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE; 
GO 

--Now Run the Query with the Query Hint. Review the plan noting it now uses the plan with the index seek created for value 288 even though the @SalesPersonID = 277. 

USE AdventureWorks2017; 
GO 

DECLARE @SalesPersonID int 
SELECT @SalesPersonID = 277 

SELECT SalesOrderId, OrderDate 
FROM Sales.SalesOrderHeader 
WHERE SalesPersonID= @SalesPersonID 
OPTION (OPTIMIZE FOR (@SalesPersonID = 288)); 

 