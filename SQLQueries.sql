SELECT 
	Invoice, StockCode, Description, Quantity,
	COALESCE (
		TRY_CONVERT(datetime2, InvoiceDate, 120),
		TRY_CONVERT(datetime2, InvoiceDate, 105)
	)AS InvoiceDate,
	TRY_CONVERT(decimal(10, 2), Price) AS Price,
	Customer_ID, Country , '2009-2010' AS SourceSheet
INTO dbo.RetailCombined
FROM dbo.[Year 2009-2010]

UNION ALL

SELECT 
	Invoice, Stockcode, Description, Quantity,
	COALESCE (
		TRY_CONVERT(datetime2, InvoiceDate, 120),
		TRY_Convert(datetime2, InvoiceDate, 105)
	)AS InvoiceDate,
	TRY_CONVERT(decimal(10, 2), Price) AS Price,
	Customer_ID, Country, '2010-2011' AS SourceSheet
FROM dbo.[Year 2010-2011]

--Confirm the conversion worked cleanly
SELECT COUNT(*) AS TR FROM dbo.RetailCombined
SELECT COUNT(*) AS Falied_dates FROM dbo.RetailCombined WHERE InvoiceDate IS NULL;
SELECT COUNT(*) AS Failed_Prices FROM dbo.RetailCombined WHERE Price IS NULL;

--Check 1 - Missing Customer ID
SELECT COUNT(*) AS Missing_CustomerID
FROM dbo.RetailCombined WHERE Customer_ID is NULL;

--Check 2 Negative or Zero Quantity
SELECT COUNT(*) AS Negative_Qty
FROM dbo.RetailCombined WHERE Quantity <=0;

--CHeck 3 -  Missing Description 
SELECT COUNT(*) AS Missing_Description
FROM dbo.RetailCombined WHERE Description is NULL;

--Check 4 - Exact duplicate Rows
SELECT	Invoice, Stockcode, Description, Quantity, InvoiceDate, Customer_ID, Country,
		COUNT(*) AS ExactDupeCount
FROM dbo.RetailCombined
GROUP BY Invoice, Stockcode, Description, Quantity, InvoiceDate, Customer_ID, Country
HAVING COUNT(*)>1

--Deduplicate and produce the final cleaned table

WITH deduped AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
			ORDER BY (SELECT NULL)
		) AS RowNum
	FROM dbo.RetailCombined
)
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourceSheet
INTO dbo.RetailCleaned
FROM deduped
WHERE RowNum = 1;

SELECT * FROM dbo.RetailCleaned;
