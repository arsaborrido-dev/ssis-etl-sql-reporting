USE [DATABASE_NAME]
GO

/****** Object:  StoredProcedure [dbo].[ssrs_SalesOrderReport]    Script Date: 8/1/2026 12:12:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		arsaborrido-dev
-- Create date: 
-- Description:	Sales order report stored procedure
-- Purpose:		This stored procedure provides a simple, aggregated sales order dataset 
--				intended solely for reporting demonstrations. It summarizes raw transactional 
--				data by calculating the total quantity ordered and total sales amount 
--				for each product–region combination. Its only purpose is to serve as a lightweight, 
--				easy‑to‑understand example for showcasing the ETL workflow and how SSRS consumes 
--				cleaned and transformed data from SQL Server
-- =============================================
CREATE PROCEDURE [dbo].[ssrs_SalesOrderReport] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT
		Product
		,Region
		,SUM(Quantity) AS TotalQuantity
		,SUM(TotalAmount) AS TotalSalesAmount
	FROM tblSalesOrder
	GROUP BY Product, Region


END
GO


