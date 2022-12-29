--Create Database PCarlson_Lab4
USE PCarlson_Lab4

--Creating relevant tables
Create Table tblCUSTOMER (
	CustomerID int IDENTITY(1,1) PRIMARY KEY, 
	Fname varchar(30) NOT NULL,
	Lname varchar(30) NOT NULL,
	BirthDate date NOT NULL
	)

Create Table tblORDER (
	OrderID int IDENTITY(1,1) PRIMARY KEY, 
	OrderDate date NOT NULL,
	CustomerID int FOREIGN KEY REFERENCES tblCUSTOMER(CustomerID)
	)

Create Table tblPRODUCT_TYPE (
	ProductTypeID int IDENTITY(1,1) PRIMARY KEY, 
	ProductTypeName varchar(30) NOT NULL,
	ProductTypeDesc varchar(500) NULL
	)

Create Table tblPRODUCT (
	ProductID int IDENTITY(1,1) PRIMARY KEY, 
	ProductName varchar(50) NOT NULL,
	ProductTypeID int FOREIGN KEY REFERENCES tblPRODUCT_TYPE(ProductTypeID),
	Price numeric(8,2) NOT NULL,
	ProductDescr varchar(500) NULL
	)

Create Table tblORDER_PRODUCT (
	OrderProdID int IDENTITY(1,1) PRIMARY KEY, 
	OrderID int FOREIGN KEY REFERENCES tblORDER(OrderID),
	ProductID int FOREIGN KEY REFERENCES tblPRODUCT(ProductID),
	Quantity int NOT NULL
	)

Create Table tblCART (
	CartID int IDENTITY(1,1) PRIMARY KEY, 
	CustomerID int FOREIGN KEY REFERENCES tblCUSTOMER(CustomerID),
	ProductID int FOREIGN KEY REFERENCES tblPRODUCT(ProductID),
	Quantity int NOT NULL,
	DateAdded date NOT NULL
	)

--Populate tblCUSTOMER and tblPRODUCT_TYPE
INSERT INTO tblCUSTOMER(Fname, Lname, BirthDate)
	Select Top 150 CustomerFname, CustomerLname, DateOfBirth
	From Peeps.dbo.tblCUSTOMER Where Year(DateOfBirth) >= 1950

INSERT INTO tblPRODUCT_TYPE (ProductTypeName, ProductTypeDesc)
VALUES 
	('Fashion','Clothing and accessories for adults, kids, and babies'),
	('Kitchen','Cookware and food prep supplies, and all sorts of kitchen-related home goods'),
	('Toys','Fun toys and games for little ones as well as grown-ups'),
	('Books','Both classics and new releases, fiction, nonfiction, and poetry, we have it all!')

GO

--Procedures to get various IDs (Customer, ProductType, Product)
Create Procedure pcGetCustomerID
	@Fn varchar(30),
	@Ln varchar(30),
	@dob date,
	@CID int OUTPUT
AS
Set @CID = (SELECT CustomerID FROM tblCUSTOMER WHERE @Fn=Fname AND @Ln=Lname AND @dob=BirthDate)
GO

Create Procedure pcGetProductTypeID
	@PTname varchar(30),
	@PTID int OUTPUT
AS
Set @PTID = (SELECT ProductTypeID FROM tblPRODUCT_TYPE WHERE @PTname = ProductTypeName)
GO

Create Procedure pcGetProductID
	@Pname varchar(30),
	@PID int OUTPUT
AS
Set @PID = (SELECT ProductID FROM tblPRODUCT WHERE @Pname = ProductName)
GO

--Procedure to populate Product table, with ProductType lookup
Create Procedure pcInsertProduct
	@Pname varchar(50),
	@PType varchar(30),
	@Pr numeric(8,2),
	@Pdesc varchar(500) = NULL
AS
Declare @PT_ID int
EXEC pcGetProductTypeID @PTname=@PType, @PTID=@PT_ID OUTPUT
IF @PT_ID is NULL
	BEGIN
		Print 'No ProductType found by that name';
		Throw 55002, '@PT_ID cannot be NULL; process terminating',1;
	END

BEGIN TRANSACTION insertProd
Insert Into tblPRODUCT (ProductName, ProductTypeID, Price, ProductDescr)
	Values (@Pname, @PT_ID, @Pr, @Pdesc)
COMMIT Transaction insertProd
GO

--Brief break to populate the Product table
EXEC pcInsertProduct @Pname='Shirt', @PType='Fashion', @Pr=8.50
EXEC pcInsertProduct @Pname='Jeans', @PType='Fashion', @Pr=9.00
EXEC pcInsertProduct @Pname='Blender', @PType='Kitchen', @Pr=32.50
EXEC pcInsertProduct @Pname='Instant Pot', @PType='Kitchen', @Pr=65.50
EXEC pcInsertProduct @Pname='Blocks', @PType='Toys', @Pr=12.75
EXEC pcInsertProduct @Pname='Dolly', @PType='Toys', @Pr=8.25
EXEC pcInsertProduct @Pname='American Gods', @PType='Books', @Pr=11.00
EXEC pcInsertProduct @Pname='Life of Pi', @PType='Books', @Pr=9.50
GO

--Procedure to populate tblCART, with lookups
Create Procedure pcAddToCart
	@CFn varchar(30),
	@CLn varchar(30),
	@Cdob date,
	@Prod varchar(50),
	@Quant int,
	@date date = NULL --(will default to GETDATE())
AS
IF @date is NULL Set @date=GETDATE()
Declare @P_ID int, @C_ID int

EXEC pcGetCustomerID @Fn=@CFn, @Ln=@CLn, @dob=@Cdob, @CID=@C_ID OUTPUT
IF @C_ID is NULL
	BEGIN
		Print 'No customer found with those details';
		Throw 55001, '@C_ID cannot be NULL; process terminating',1;
	END

EXEC pcGetProductID @Pname=@Prod, @PID=@P_ID OUTPUT
IF @P_ID is NULL
	BEGIN
		Print 'No product found by that name';
		Throw 55003, '@P_ID cannot be NULL; process terminating',1;
	END

BEGIN TRANSACTION addToCart
Insert Into tblCART (CustomerID, ProductID, Quantity, DateAdded)
	Values (@C_ID, @P_ID, @Quant, @date)
COMMIT Transaction addToCart
GO

/*
4) Write stored procedure to conduct a check-out process of the contents of tblCART based on a single customer. 
	This is populating the ORDER and ORDER_PRODUCT tables!!! 
	Your calling stored procedure will also use the GetCustomerID created in step 1.
5) Include error-handling if a parameter or variable is NULL.
6) The final INSERT statement of processing rows into tblORDER_PRODUCT 
	needs to be in an explicit transaction.
HINT: Obtain the new OrderID by using SCOPE_IDENTITY()
7) Include nested transaction to manage the different steps as explained in lecture 
	(remember: @@TRANCOUNT must be 1 when the final commit is issued). 
*/
Create Procedure pcCheckoutCart
	@CFn varchar(30),
	@CLn varchar(30),
	@Cdob date,
	@Odate date
AS
Declare @CustID int
EXEC pcGetCustomerID @Fn=@CFn, @Ln=@CLn, @dob=@Cdob, @CID=@CustID OUTPUT
IF @CustID is NULL
	BEGIN
		Print 'No customer found with those details';
		Throw 55001, '@CustID cannot be NULL; process terminating',1;
	END

BEGIN TRANSACTION newOrder1
	--Create new order
	Insert Into tblORDER(CustomerID, OrderDate)
	Values (@CustID, @Odate)
	BEGIN TRANSACTION cartToOrderProduct2
		--Add items for this customer to the order from the cart
		INSERT INTO tblORDER_PRODUCT(OrderID, ProductID, Quantity)
			SELECT SCOPE_IDENTITY(), ProductID, SUM(Quantity)
				FROM tblCART
				WHERE CustomerID=@CustID
				GROUP BY ProductID
		--Clean up Cart
		DELETE FROM tblCART WHERE CustomerID=@CustID
	COMMIT TRANSACTION cartToOrderProduct2
	--Double check that all went well
	IF @@TRANCOUNT <> 1
		BEGIN 
			ROLLBACK TRANSACTION cartToOrderProduct2
		END
	ELSE
		--Commit to the order since everything is fine!
		COMMIT TRANSACTION newOrder1
GO


--Testing and such!
/*SELECT Top 5 * from tblCUSTOMER
1	Karima	Butterworth	1976-05-23
2	Lessie	Fevold	1972-04-06
3	Sharyn	Bednarczyk	1994-03-19
4	Brigette	Atienza	1951-07-10
5	Sanda	Bowell	1956-07-18 
*/
/*SELECT * from tblPRODUCT
Shirt
Jeans
Blender
Instant Pot
Blocks
Dolly
American Gods
Life of Pi
*/

/*
--EXEC pcAddToCart @CFn='',@CLn='',@Cdob='',@Prod='',@Quant=
EXEC pcAddToCart @CFn='Karima',@CLn='Butterworth',@Cdob='1976-05-23',@Prod='Shirt',@Quant=2
EXEC pcAddToCart @CFn='Karima',@CLn='Butterworth',@Cdob='1976-05-23',@Prod='Blender',@Quant=1
EXEC pcAddToCart @CFn='Karima',@CLn='Butterworth',@Cdob='1976-05-23',@Prod='Dolly',@Quant=3
EXEC pcAddToCart @CFn='Karima',@CLn='Butterworth',@Cdob='1976-05-23',@Prod='Jeans',@Quant=1
EXEC pcAddToCart @CFn='Karima',@CLn='Butterworth',@Cdob='1976-05-23',@Prod='Shirt',@Quant=1 --See if this works in final order

EXEC pcAddToCart @CFn='Lessie',@CLn='Fevold',@Cdob='1972-04-06',@Prod='Jeans',@Quant=2
EXEC pcAddToCart @CFn='Lessie',@CLn='Fevold',@Cdob='1972-04-06',@Prod='Shirt',@Quant=2
EXEC pcAddToCart @CFn='Lessie',@CLn='Fevold',@Cdob='1972-04-06',@Prod='American Gods',@Quant=1

EXEC pcAddToCart @CFn='Sharyn',@CLn='Bednarczyk',@Cdob='1994-03-19',@Prod='Life of Pi',@Quant=2
EXEC pcAddToCart @CFn='Sharyn',@CLn='Bednarczyk',@Cdob='1994-03-19',@Prod='Dolly',@Quant=1
EXEC pcAddToCart @CFn='Sharyn',@CLn='Bednarczyk',@Cdob='1994-03-19',@Prod='Instant Pot',@Quant=1
EXEC pcAddToCart @CFn='Sharyn',@CLn='Bednarczyk',@Cdob='1994-03-19',@Prod='Jeans',@Quant=1

EXEC pcAddToCart @CFn='Lessie',@CLn='Fevold',@Cdob='1972-04-06',@Prod='Jeans',@Quant=1 --See if this works in final order

EXEC pcAddToCart @CFn='Lessie',@CLn='Fevold',@Cdob='1972-04-06',@Prod='Jeanzz',@Quant=2 --Shouldn't work (not a right product)
EXEC pcAddToCart @CFn='Lexxie',@CLn='Fexxold',@Cdob='1972-04-06',@Prod='Jeans',@Quant=2 --Shouldn't work (not a right customer)

SELECT * from tblCART ca
	join tblCUSTOMER cu on cu.CustomerID=ca.CustomerID
	join tblPRODUCT p on p.ProductID = ca.ProductID

--DECLARE @today date = GetDate()
EXEC pcCheckoutCart @CFn='Karima',@CLn='Butterworth',@Cdob='1976-05-23', @Odate='2022-04-23'
EXEC pcCheckoutCart @CFn='Lessie',@CLn='Fevold',@Cdob='1972-04-06', @Odate = '2022-04-25' --@today

EXEC pcCheckoutCart @CFn='Sharyynxx',@CLn='Bednarczyk',@Cdob='1994-03-19', @Odate='2022-04-24' --Shouldn't work (not a right customer)

Select OrderDate, Fname, ProductName, Quantity 
	from tblORDER o
	join tblCUSTOMER c on c.CustomerID = o.CustomerID
	join tblORDER_PRODUCT op on op.OrderID = o.OrderID
	join tblPRODUCT p on p.ProductID = op.ProductID

--Sharyn didn't check out (successfully), so they should still have their cart, but the rest have been checked out so carts deleted
SELECT Fname, ProductName, Quantity
	from tblCART ca
	join tblCUSTOMER cu on cu.CustomerID=ca.CustomerID
	join tblPRODUCT p on p.ProductID = ca.ProductID
*/
