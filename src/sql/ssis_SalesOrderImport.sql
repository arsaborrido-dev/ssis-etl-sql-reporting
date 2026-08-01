USE [MyDataBase]
GO

/****** Object:  StoredProcedure [dbo].[ssis_SalesOrderImport]    Script Date: 8/1/2026 12:20:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		arsaborrido-dev
-- Create date: 
-- Description:	Sales order import stored procedure
-- Purpose:		This stored procedure is used exclusively for the ETL import portion of the tutorial.
--				It demonstrates how raw staging data is cleaned, validated, deduplicated, and prepared 
--				for reporting. The procedure performs basic transformations, filters out invalid rows, 
--				identifies duplicates, routes rejected records to an exception table, inserts new region 
--				values, and loads clean sales order data into the main fact table. 
--    
--				This logic is intentionally simplified and exists solely to illustrate how an SSIS 
--				import pipeline interacts with SQL Server during a reporting workflow.
-- =============================================	

CREATE PROCEDURE [dbo].[ssis_SalesOrderImport] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	--lets do a little cleanup/transformation	
	
	IF OBJECT_ID('tempdb..#tempStaging') IS NOT NULL
		DROP TABLE #tempStaging

	SELECT
		NULLIF(TRY_CAST(OrderID AS INT), 0) AS OrderID
		,TRY_CAST(OrderDate AS DATE) AS OrderDate
		,TRIM(CustomerName) AS CustomerName
		,TRIM(Product) AS Product
		,NULLIF(TRY_CAST(Quantity AS INT), 0) AS Quantity
		,TRY_CAST(UnitPrice AS DECIMAL(10,2)) AS UnitPrice
		,TRIM(Region) AS Region
		,IDENTITY (INT,1,1) AS RowId
	INTO #tempStaging
	FROM tblSalesOrderImport_Staging


	SELECT *
		,ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY TRY_CAST(OrderDate AS DATE) DESC) AS RowNum
	INTO #tempSalesOrder
	FROM #tempStaging t
	WHERE EXISTS (SELECT 1 FROM tblRegion r WHERE r.Description = t.Region)
	  AND t.OrderID IS NOT NULL
	  AND t.OrderDate IS NOT NULL
	  AND t.Quantity IS NOT NULL
	  AND t.UnitPrice IS NOT NULL
	  AND t.Product <> ''

    --check if exception table exists
	IF OBJECT_ID ('dbo._tblExceptions', 'U') IS NULL
	BEGIN
		--create exception table if not created yet
		SELECT *
		INTO _tblExceptions
		FROM tblSalesOrderImport_Staging
		WHERE 1 = 2
	END

	--lets truncate exception table first for clean data
	TRUNCATE TABLE _tblExceptions

	--insert records to exception table
	INSERT INTO _tblExceptions
	SELECT
		s.OrderID
		,s.OrderDate
		,s.CustomerName
		,s.Product
		,s.Quantity
		,s.UnitPrice
		,s.Region
	FROM #tempStaging s
	LEFT JOIN #tempSalesOrder t ON t.RowId = s.RowId AND t.RowNum = 1
	LEFT JOIN tblSalesOrder so ON so.OrderID = s.OrderID
	WHERE t.RowId IS NULL
	   OR so.OrderID IS NOT NULL
	--WHERE NOT EXISTS (SELECT 1 FROM #tempSalesOrder t WHERE t.RowId = s.RowId AND t.RowNum = 1)
		
	--insert new regions into Region table
	INSERT INTO tblRegion
	SELECT DISTINCT t.Region
	FROM #tempStaging t
	WHERE NOT EXISTS (SELECT 1 FROM tblRegion r WHERE r.Description = t.Region)
	  AND t.Region <> ''

	--insert to fact table
	INSERT INTO tblSalesOrder
	(
		OrderID
		,OrderDate
		,CustomerName
		,Product
		,Quantity
		,UnitPrice
		,Region
	)
	SELECT 
		OrderID
		,OrderDate
		,CustomerName
		,Product
		,Quantity
		,UnitPrice
		,Region
	FROM #tempSalesOrder t
	WHERE NOT EXISTS (SELECT 1 FROM tblSalesOrder so WHERE so.OrderId = t.OrderID)
	  AND t.RowNum = 1
	  
END
GO


