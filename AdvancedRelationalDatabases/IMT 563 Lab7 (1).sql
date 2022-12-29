CREATE DATABASE pcLab7

DROP DATABASE pcLab7

USE pcLab7

----CREATE TABLES

CREATE TABLE tblPET_TYPE
(PetTypeID INT IDENTITY(1,1) primary key,
PetTypeName varchar(50) not null,
PetTypeDescr varchar(500) NULL)
GO

CREATE TABLE tblTEMPERAMENT
(TempID INT IDENTITY(1,1) primary key,
TempName varchar(50) not null,
TempDescr varchar(500) NULL)
GO

CREATE TABLE tblREGION
(RegionID INT IDENTITY(1,1) primary key,
RegionName varchar(50) not null)
GO

CREATE TABLE tblCOUNTRY
(CountryID INT IDENTITY(1,1) primary key,
CountryName varchar(50) not null,
RegionID INT FOREIGN KEY REFERENCES tblREGION (RegionID) NOT NULL)
GO

CREATE TABLE tblGENDER 
(GenderID INT IDENTITY(1,1) primary key,
GenderName varchar(30) not null)
GO

CREATE TABLE tblPET 
(PetID INT IDENTITY (1,1) primary key,
PetName varchar(25) not null,
PetTypeID INT not null,
TempID INT not null,
CountryID INT not null,
BirthDate Date not null,
GenderID INT not null,
Cost numeric (7,2) not null,
Price numeric (8,2) null)
GO

CREATE TABLE tblHOBBY
(HobbyID INT IDENTITY(1,1) primary key,
HobbyName varchar(50) not null,
HobbyPoints Numeric(5,2) null)
GO

CREATE TABLE tblPET_HOBBY
(PetHobbyID INT IDENTITY(1,1) primary key,
PetID INT FOREIGN KEY REFERENCES tblPET (PetID) NOT NULL,
HobbyID INT FOREIGN KEY REFERENCES tblHOBBY (HobbyID) NULL,
HobbyNum INT NULL)
GO

-- add FOREIGN KEYs to tblPET
ALTER TABLE tblPET
ADD CONSTRAINT FK_tblPET_PetTypeID
FOREIGN KEY (PetTypeID) 
REFERENCES tblPET_TYPE (PetTypeID)
GO
ALTER TABLE tblPET
ADD CONSTRAINT FK_tblPET_TempID
FOREIGN KEY (TempID)
REFERENCES tblTEMPERAMENT (TempID)
GO
ALTER TABLE tblPET
ADD CONSTRAINT FK_tblPET_CountryID
FOREIGN KEY (CountryID)
 REFERENCES tblCOUNTRY (CountryID)
GO
ALTER TABLE tblPET
ADD CONSTRAINT FK_tblPET_GenderID
FOREIGN KEY (GenderID)
REFERENCES tblGENDER (GenderID)
GO

---
CREATE TABLE Raw_New(
	PETNAME nvarchar(255) NULL, -- making these columns wide for now (varchar(255) is as wide as excel goes)
	PET_TYPE nvarchar(255) NULL,
	TEMPERAMENT nvarchar(255) NULL,
	COUNTRY nvarchar(255) NULL,
	DATE_BIRTH Date NULL, -- converting from varchar(255) to a standard DATE data type
	GENDER nvarchar(255) NULL,
	HOBBY1 nvarchar(255) NULL,
	HOBBY2 nvarchar(255) NULL,
	HOBBY3 nvarchar(255) NULL,
	HOBBY4 nvarchar(255) NULL,
	Cost Numeric(8,2)  NULL -- converting from varchar(255) to a data type that represents decimals
) 
GO

---
BULK INSERT pcLab7.dbo.Raw_New
    FROM 'C:\SQL\PetAnalytics.csv'
    WITH (
	FIELDTERMINATOR = ',',
	FIRSTROW = 2, 
    ROWTERMINATOR = '\n')
GO

SELECT *
FROM Raw_New

---
IF EXISTS (SELECT * FROM sys.sysobjects WHERE NAME = 'CLEANED_PETS_PK')
	BEGIN
			-- example schema that has a primary key column added
			CREATE TABLE [dbo].[CLEANED_Pets_PK](
			PetID INT IDENTITY (1,1) primary key,
				[PETNAME] [nvarchar](255) NULL,
				[PET_TYPE] [nvarchar](255) NULL,
				[TEMPERAMENT] [nvarchar](255) NULL,
				[COUNTRY] [nvarchar](255) NULL,
				[DATE_BIRTH] [date] NULL,
				[GENDER] [nvarchar](255) NULL,
				[HOBBY1] [nvarchar](255) NULL,
				[HOBBY2] [nvarchar](255) NULL,
				[HOBBY3] [nvarchar](255) NULL,
				[HOBBY4] [nvarchar](255) NULL,
				[Cost] [money] NULL
			) 
	END
GO

SELECT *
FROM CLEANED_PETS_PK
---
INSERT INTO CLEANED_Pets_PK (PETNAME,PET_TYPE,TEMPERAMENT,COUNTRY,DATE_BIRTH,GENDER,HOBBY1,	HOBBY2,	HOBBY3,	HOBBY4, Cost)
SELECT PETNAME, PET_TYPE, TEMPERAMENT, COUNTRY, DATE_BIRTH, GENDER, HOBBY1, HOBBY2, HOBBY3, HOBBY4, Cost
FROM gthay_66.dbo.Raw_New
WHERE PETNAME IS NOT NULL
AND PET_TYPE IS NOT NULL
AND TEMPERAMENT IS NOT NULL
AND COUNTRY IS NOT NULL
AND DATE_BIRTH IS NOT NULL
AND GENDER IS NOT NULL
AND Cost IS NOT NULL
AND DATE_BIRTH  <= GetDate()
GO

---
CREATE PROCEDURE pcGetGenderID
@GenName varchar(15),
@GenderID INT OUTPUT
AS
SET @GenderID = (SELECT GenderID FROM tblGENDER WHERE GenderName = @GenName)
GO

CREATE PROCEDURE pcGetPetTypeID
@PTypeName varchar(50),
@PTypeID INT OUTPUT
AS
SET @PTypeID = (SELECT PetTypeID FROM tblPET_TYPE WHERE PetTypeName = @PTypeName)
GO

CREATE PROCEDURE pcGetTemperamentID
@T_Name varchar(50),
@Temp_ID INT OUTPUT
AS
SET @Temp_ID = (SELECT TempID FROM tblTEMPERAMENT WHERE TempName = @T_Name)
GO

CREATE PROCEDURE pcGetCountryID
@CountryName varchar(50),
@CntID INT OUTPUT
AS
SET @CntID = (SELECT CountryID FROM tblCOUNTRY WHERE CountryName = @CountryName)
GO

CREATE PROCEDURE pcGetRegionID
@R_Name varchar(50),
@RegID INT OUTPUT
AS
SET @RegID = (SELECT RegionID FROM tblREGION WHERE RegionName = @R_Name)
GO

CREATE PROCEDURE pcGetHobbyTypeID
@HT_Name varchar(50),
@HobT_ID INT OUTPUT
AS
SET @HobT_ID = (SELECT HobbyTypeID FROM tblHOBBY_TYPE WHERE HobbyTypeName = @HT_Name)
GO

CREATE PROCEDURE pcGetHobbyID
@HB_Name varchar(50),
@HB_ID INT OUTPUT
AS
SET @HB_ID = (SELECT HobbyID FROM tblHOBBY WHERE HobbyName = @HB_Name)
GO

---
-- populate the look-up columns in the database with DISTINCT values from the cleaned/scrubbed table 'CLEANED_Pets_PK'

INSERT INTO tblGENDER (GenderName) -- should be 2 rows (no duplicates!!!)
SELECT DISTINCT Gender
FROM CLEANED_Pets_PK
GO

INSERT INTO tblTEMPERAMENT (TempName) -- should be 15 rows (no duplicates!!!)
SELECT DISTINCT Temperament
FROM CLEANED_Pets_PK
GO

INSERT INTO tblPET_TYPE (PetTypeName) -- should only be 20 rows (no duplicates!!!)
SELECT DISTINCT Pet_Type
FROM CLEANED_Pets_PK
GO

INSERT INTO tblCOUNTRY (CountryName) -- should be 31 rows (no duplicates!!!) ---TO DO: ERROR
SELECT DISTINCT Country
FROM CLEANED_Pets_PK
GO

---
CREATE TABLE #TempHobbyHold
(TempHobbyName varchar(50))
GO
INSERT INTO #TempHobbyHold (TempHobbyName)
SELECT DISTINCT Hobby1
FROM CLEANED_Pets_PK
GO

INSERT INTO #TempHobbyHold (TempHobbyName)
SELECT DISTINCT Hobby2
FROM CLEANED_Pets_PK
GO
INSERT INTO #TempHobbyHold (TempHobbyName)
SELECT DISTINCT Hobby3
FROM CLEANED_Pets_PK
GO
INSERT INTO #TempHobbyHold (TempHobbyName)
SELECT DISTINCT Hobby4
FROM CLEANED_Pets_PK
GO

INSERT INTO tblHOBBY (HobbyName)
SELECT DISTINCT TempHobbyName
FROM #TempHobbyHold
WHERE TempHobbyName IS NOT NULL

DROP TABLE #TempHobbyHold -- clean up the temp table used to sort all hobbies

SELECT * 
FROM CLEANED_Pets_PK

---
-- we do not want to touch the cleaned/scrubbed data! Make a 'working' copy that can be destroyed or ripped apart without damaging any data we worked hard to get!

-- ******This will be the beginning of each attempt of our script. ******

IF EXISTS (SELECT * FROM sys.sysobjects WHERE NAME = '#WORKING_COPY_Pets_pc') -- will need to run the following block of code minus the DROP table line the very first time
	BEGIN
	DROP TABLE #WORKING_COPY_Pets_pc

    CREATE TABLE #WORKING_COPY_Pets_pc
    (PetID INT IDENTITY(1,1) PRIMARY KEY,
    PETNAME nvarchar(255),
	PET_TYPE nvarchar(255),
	TEMPERAMENT nvarchar(255),
	COUNTRY nvarchar(255),
	DATE_BIRTH date,
	GENDER nvarchar(255),
	HOBBY1 nvarchar(255),
	HOBBY2 nvarchar(255),
	HOBBY3 nvarchar(255),
	HOBBY4 nvarchar(255),
	Cost numeric(8,2))

	END

SELECT *
INTO #WORKING_COPY_Pets_pc
FROM CLEANED_PETS_PK
ORDER BY PetID 

SELECT *
FROM #WORKING_COPY_Pets_pc
---

CREATE TABLE tblHOBBY_TYPE
(HobbyTypeID INT IDENTITY(1,1) primary key,
HobbyTypeName varchar(50) not null,
HobbyTypeDescr varchar(500) not null)
GO
	
INSERT INTO tblHOBBY_TYPE (HobbyTypeName, HobbyTypeDescr)
VALUES ('Musical', 'Play as a musical instrument'),('Domestic', 'Keeps the house working well'), ('GamingArtistic', 'Plays games or draws well')
GO

ALTER TABLE tblHOBBY
ADD HobbyTypeID INT
FOREIGN KEY REFERENCES tblHOBBY_TYPE (HobbyTypeID)
GO

UPDATE tblHOBBY
SET HobbyTypeID = (SELECT HobbyTypeID FROM tblHOBBY_TYPE WHERE HobbyTypeName = 'Musical')
WHERE HobbyName IN ('Piano','Guitar', 'MusicListening')

SELECT *
FROM tblHOBBY