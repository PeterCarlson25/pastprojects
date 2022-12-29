--CREATE DATABASE IMT563_Lab2_pcarlson
USE IMT563_Lab2_pcarlson
GO

--create the tables
CREATE TABLE tblCUSTOMER
(CustID INTEGER IDENTITY(1,1)PRIMARY KEY,
CustFName VARCHAR(20) NOT NULL,
CustLName VARCHAR(20) NOT NULL,
CustDOB DATE NULL)
GO

CREATE TABLE tblPRODUCTTYPE
(ProductTypeID INTEGER IDENTITY(1,1)PRIMARY KEY,
ProductTypeName VARCHAR(20) NOT NULL,
ProductTypeDescr VARCHAR(100) NULL)
GO

CREATE TABLE tblPRODUCT
(ProductID INTEGER IDENTITY(1,1)PRIMARY KEY,
ProductName VARCHAR(20) NOT NULL,
ProductTypeID INT FOREIGN KEY REFERENCES tblPRODUCTTYPE (ProductTypeID) NOT NULL,
PRICE NUMERIC(8,2) NOT NULL,
ProductDescr VARCHAR(100) NULL)
GO 

CREATE TABLE tblEMPLOYEE
(EmployeeID INTEGER IDENTITY(1,1) PRIMARY KEY,
EmpFName VARCHAR(20) NOT NULL,
EmpLName VARCHAR(20) NOT NULL,
EmpDOB DATE NOT NULL)
GO

CREATE TABLE tblORDER
(OrderID INTEGER IDENTITY(1,1) PRIMARY KEY,
OrderDate DATE NOT NULL,
CustID INT FOREIGN KEY REFERENCES tblCUSTOMER(CustID) NOT NULL,
ProductID INT FOREIGN KEY REFERENCES tblPRODUCT(ProductID) NOT NULL,
EmpID INT FOREIGN KEY REFERENCES tblEMPLOYEE(EmployeeID) NOT NULL,
Quantity INT NOT NULL)

INSERT INTO tblCUSTOMER (CustFname, CustLname, CustDOB)
VALUES ('Lebron', 'James', 'February 16, 1983'), ('Michael','Jordan', 'November 25, 1970'), ('Tim','Duncan', 'December 1, 1976'),('Evan', 'Mobley', 'February 8, 2003')


INSERT INTO tblPRODUCTTYPE (ProductTypeName, ProductTypeDescr)
VALUES ('Basketball','Sports equipment ball'),('Cigar Boxes','Wooden Box Containing Cigars'),('t-shirts','mens top tee shirts'),('Alcohol',''),('Weapon','')


INSERT INTO tblPRODUCT (ProductName, ProductTypeID, Price, ProductDescr)
VALUES ('Cobiha 24 pack', (SELECT ProductTypeID FROM tblPRODUCTTYPE WHERE ProductTypeName = 'Cigar Boxes'), '1000.00','24 pack of Cobiha Fine Cigars, wooden box'),
('Hanes 6 pack', (SELECT ProductTypeID FROM tblPRODUCTTYPE WHERE ProductTypeName = 't-shirts'), '30.00','6 pack of plain white Hanes mens t shirts'),
('29.5 oz. Wilson', (SELECT ProductTypeID FROM tblPRODUCTTYPE WHERE ProductTypeName = 'Basketball'), '50.00','29.5 oz. Leather Wilson Mens Basketball'),
('24oz Four Loko Rasp.', (SELECT ProductTypeID FROM tblPRODUCTTYPE WHERE ProductTypeName = 'Alcohol'), '7.00','Single Can 24oz. Four Loko Raspberry')



INSERT INTO tblEMPLOYEE (EmpFname, EmpLname, EmpDOB)
VALUES ('Kevin','Carlson', 'March 31, 2001'),
('Erik','Carlson','October 31, 1999'),
('Josh','Berry','October 1, 1995')

GO
select * from tblproduct
--Create a stored procedure to populate tblorder
CREATE PROCEDURE GetCustID
@cfname VARCHAR(20),
@clname VARCHAR(20),
@CID INTEGER OUTPUT

AS 

SET @CID = (SELECT custID FROM tblCUSTOMER WHERE CustFName = @cfname AND CustLName = @clname)
GO

CREATE PROCEDURE GetProductID
@PName VARCHAR(20),
@PID INTEGER OUTPUT

AS 

SET @PID = (SELECT productID FROM tblPRODUCT WHERE ProductName = @PName)
GO

CREATE PROCEDURE GetEmployeeID
@efname VARCHAR(20),
@elname VARCHAR(20),
@EID INTEGER OUTPUT

AS 

SET @EID = (SELECT EmployeeID FROM tblEMPLOYEE WHERE EmpFName = @efname AND EmpLName = @elname)
GO

CREATE PROCEDURE pcarlson_INSERT_OrderInfo
@ODate DATE,
@CF Varchar(20),
@CL Varchar(20),
@ProductName Varchar(20) ,
@EF varchar(20) ,
@EL varchar(20),
@Q INT 

AS 

DECLARE @CustomerID INT, @ProductID INT, @EmployeeID INT

EXEC GetCustID
@cfname = @CF,
@clname = @CL,
@CID = @CustomerID OUTPUT

EXEC GetProductID
@PName = @ProductName,
@PID = @ProductID OUTPUT

EXEC GetEmployeeID
@efname = @EF,
@elname = @EL,
@EID= @EmployeeID OUTPUT

BEGIN TRAN T1
INSERT INTO tblORDER (OrderDate, CustID, ProductID, EmpID, Quantity)
VALUES (@ODate,@CustomerID,@ProductID,@EmployeeID, @Q)
COMMIT TRAN T1

EXEC pcarlson_INSERT_OrderInfo
@ODate ='March 10, 2022',
@CF = 'Michael',
@CL = 'Jordan',
@ProductName = 'Cobiha 24 pack',
@EF = 'Erik',
@EL = 'Carlson',
@Q = '2'

EXEC pcarlson_INSERT_OrderInfo
@ODate ='March 10, 2022',
@CF = 'Lebron',
@CL = 'James',
@ProductName = '29.5 oz. Wilson',
@EF = 'Kevin',
@EL = 'Carlson',
@Q = '1'

EXEC pcarlson_INSERT_OrderInfo
@ODate ='March 17, 2022',
@CF = 'Tim',
@CL = 'Duncan',
@ProductName = 'Hanes 6 pack',
@EF = 'Josh',
@EL = 'Berry',
@Q = '1'

GO
--Error handling

CREATE FUNCTION mustbe21orolderforAlc_or_Weapons()
RETURNS INTEGER
AS
BEGIN
    DECLARE @RET INTEGER = 0
    IF EXISTS (SELECT * FROM tblORDER O
        JOIN tblCUSTOMER C ON C.CustID = O.CustID
        JOIN tblPRODUCT P ON P.ProductID = O.ProductID
        JOIN tblPRODUCTTYPE PT ON PT.ProductTypeID = P.ProductTypeID
    WHERE PT.ProductTypeName IN ('Alcohol','Weapon')
    AND C.CustDOB > DATEADD(YEAR,-21, GetDate())
    )
    SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE tblORDER WITH NOCHECK
ADD CONSTRAINT checkcustomerage
CHECK (dbo.mustbe21orolderforAlc_or_Weapons()=0)

--see if it works

EXEC pcarlson_INSERT_OrderInfo
@ODate ='March 17, 2022',
@CF = 'Evan',
@CL = 'Mobley',
@ProductName = '24oz Four Loko Rasp.',
@EF = 'Josh',
@EL = 'Berry',
@Q = '1'