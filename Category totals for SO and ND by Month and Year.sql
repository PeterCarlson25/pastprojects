--This report is to see how the Standing Order and Next Delivery breakdown by Month for each category
DECLARE @rowCount int;

	PRINT CONCAT(CONVERT( VARCHAR(24), GETDATE(), 121), ': Script START');	
	RAISERROR ('', 0, 1) WITH NOWAIT  --use this to display message immediately, otherwise it waits until the end of the whole script


--Use this to drop any temp tables that still exist from the previous run
IF OBJECT_ID('tempdb..#InvoiceTemp1') IS NOT NULL DROP TABLE #InvoiceTemp1;
IF OBJECT_ID('tempdb..#InvoiceTemp2') IS NOT NULL DROP TABLE #InvoiceTemp2;
IF OBJECT_ID('tempdb..#InventoryTemp') IS NOT NULL DROP TABLE #InventoryTemp;
IF OBJECT_ID('tempdb..#InvoiceDetailTemp') IS NOT NULL DROP TABLE #InvoiceDetailTemp;
IF OBJECT_ID('tempdb..#shoppingcarttempSO') IS NOT NULL DROP TABLE #shoppingcarttempSO;

-- Gather all invoices that came from after the first snapshot was taken of the carts

SELECT InvoiceId,cc.storeid, cc.CustomerId, InvoiceDate, DeliverDate
INTO #InvoiceTemp1
FROM SBFarms.sbf.Invoice_InvoicesView i
INNER JOIN SBFarms.sbf.CustomerView cc ON cc.CustomerID = i.CustomerId
WHERE InvoiceDate >= '5-21-2023'
  AND Status <> 'VOID'
  AND CustomerClassID IN (SELECT CustomerClassId FROM SBFarms.dbo.CustomerClass WHERE CustomerClassNum = 'Res') --Only residential
  AND i.RouteDayId IS NOT NULL  --only grab invoices that were part of a route
  AND Active = 1
;

	SET @rowCount = @@ROWCOUNT;
	PRINT CONCAT(CONVERT( VARCHAR(24), GETDATE(), 121), ': #InvoiceTemp1.INSERT: ', @rowCount);	
	RAISERROR ('', 0, 1) WITH NOWAIT  --use this to display message immediately, otherwise it waits until the end of the whole script

--DROP TABLE #InvoiceTemp1
--SELECT * FROM #InvoiceTemp1

--Create the temp Inventory table to join onto the Invoice view to improve performance
SELECT 
       iv.InventoryID,
       iv.InventoryNum Sku, 
       iv.Description,
       iv.Inventorytype,
	   iv.SalesCategory,
	   iv.SalesSubCategory,
       iv.PA_Organic,  --this tells you if the product is organic. 
       iv.User2
INTO #InventoryTemp
FROM SBFarms.sbf.InventoryView iv
WHERE InventoryNum NOT IN ('29902','29913','29945','GELPACK', 'SKIM', '29907', 'A29912', '29909', '29908', 'A29902', 'A29907'
  ,'GWP-40X40SMI000','NSRS-MIT206070','29989','29995','29996','29998','29911','REFUND','SURVEY','MFD ADD ON','29912','66016','A29911',
  'GWP-40X40SMI111','DO NOT USE-2132','1163151PMT','1163251PMT','1173151PMT','1173251PMT','A51296','A6','40023','41006','50009','A60896','A60897',
  'A60898','A60899','84598','A10251','A10255','A10256','A10300','A10301','A10302','A10303','A10304','A10305','A10310','A10312','A10313','A10314'
  ,'A10318','A10450','A10451','A10454','A10456','A83013','A84598','A881','A10465','A10466','A10467','A10468','A10469','A882','A887','A889','A9998'
  ,'ALLOWANCES','BALANCE TRANSFER','CROSS DOCK FEE','DELIVERY FEE','Description','FinChrg','Fixed Asset Disposal','Freight In','INTEREST','Partner Discount'
  ,'PROCESSING CHARGES','Test Discount','A59888','A9887','DO NOT USE-3554','DO NOT USE-3595','NSRS-3005549','PCA-93606-1','FREEGIFT','a1482','A10319'
  ,'A10311','A10308','A10501','Misc Item','A6070','A10399','DO NOT USE-4086','X29907','BOAT RACE - HALF GALLONS','BOAT RACE - GALLON JUGS','25153'
  ,'DO NOT USE-4290','X60896','X60897','NSRS-HP1722914','DO NOT USE-4796')  
  AND InventoryNum NOT LIKE 'PROMO%'
  AND InventoryNum NOT LIKE '/%'
  AND InventoryNum NOT LIKE 'NOTE%'
  AND InventoryNum NOT LIKE 'IC%'
  AND InventoryNum NOT LIKE 'A/%'
  AND InventoryNum NOT LIKE 'Z/%'
  --AND iv.User2 IN ('Inventory Item', 'Assembly/Bill of Materials')
;

	SET @rowCount = @@ROWCOUNT;
	PRINT CONCAT(CONVERT( VARCHAR(24), GETDATE(), 121), ': #InventoryTemp.INSERT: ', @rowCount);	
	RAISERROR ('', 0, 1) WITH NOWAIT  --use this to display message immediately, otherwise it waits until the end of the whole script

--SELECT * FROM #InventoryTemp
--DROP TABLE #InventoryTemp


SELECT i.StoreId,i.InvoiceId, i.CustomerId, i.InvoiceDate, i.DeliverDate,
	   id.InvoiceDetailID,
	   iv.InventoryId,
       id.QtyOrdered,
       iv.Sku,
       iv.Description,
	   iv.SalesCategory,
	   iv.SalesSubCategory
INTO #InvoiceDetailTemp
FROM #InvoiceTemp1 i
  INNER JOIN SBFarms.dbo.InvoiceDetail id ON id.InvoiceId = i.InvoiceId 
  INNER JOIN #InventoryTemp iv ON iv.InventoryId = id.InventoryId
WHERE QtyOrdered > 0
ORDER BY iv.Sku

--SELECT * FROM #InvoiceDetailTemp
--DROP TABLE #InvoiceDetailTemp

SET @rowCount = @@ROWCOUNT;
	PRINT CONCAT(CONVERT( VARCHAR(24), GETDATE(), 121), ': #InvoiceDetailTemp.INSERT: ', @rowCount);	
	RAISERROR ('', 0, 1) WITH NOWAIT  --use this to display message immediately, otherwise it waits until the end of the whole script


--------------------------------------------------------------------------------------------

--pull from the snapshot
SELECT StoreId, 
	   CustomerID,
	   DeliverDate,
	   DATEADD(WEEK, DATEDIFF(WEEK, '20120101', DeliverDate), '20120101') AS WeekStart,
	   ShoppingCartTypeId,
	   sku,
	   Quantity
INTO #shoppingcarttempSO
FROM SBFarms_DataStore.sbf.ShoppingCartItem_Snapshot s
INNER JOIN SBF_NOP.dbo.Customer c ON c.Id = s.CustomerId
WHERE s.ShoppingCartTypeId = 2

--SELECT * FROM #shoppingcarttempSO
--DROP TABLE #shoppingcarttempSO

SET @rowCount = @@ROWCOUNT;
	PRINT CONCAT(CONVERT( VARCHAR(24), GETDATE(), 121), ': #shoppingcarttempSO.INSERT: ', @rowCount);	
	RAISERROR ('', 0, 1) WITH NOWAIT  --use this to display message immediately, otherwise it waits until the end of the whole script


	PRINT CONCAT(CONVERT( VARCHAR(24), GETDATE(), 121), ': Script END');	