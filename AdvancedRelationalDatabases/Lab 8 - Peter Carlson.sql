--1. Each student will create a synthetic transaction of one of the base stored procedures they have created for their project database.

--2. Follow best-practices in creating stored procedures (such as creating nested stored procedures for FK look-ups) and passing 'names' for parameters (as opposed to hard-coding FK values).

-- Lab 8: Synthetic Transaction on WRAPPER_pc_INSERT_TRAIL_TERRAIN
---INSERT_TRAIL_TERRAIN
CREATE PROCEDURE GetTerrainID
@TerrainName VARCHAR(50),
@Terrain_ID INT OUTPUT
AS
SET @Terrain_ID = (SELECT TerrainID FROM tblTERRAIN WHERE TerrainName = @TerrainName)
GO
 
CREATE PROCEDURE GetTrailID
@TrailName VARCHAR(250),
@TrailAddress VARCHAR(250),
@Trail_ID INT OUTPUT
AS
SET @Trail_ID = (SELECT TrailID FROM tblTRAIL WHERE TrailName = @TrailName AND TrailAddress = @TrailAddress)
GO
 
CREATE PROCEDURE pcINSERT_TRAIL_TERRAIN
@Terrain VARCHAR(50),
@TRname VARCHAR(250),
@TRAddress VARCHAR(250)
AS
DECLARE @TR_ID INT, @T_ID INT
 
EXEC GetTerrainID
@TerrainName = @Terrain,
@Terrain_ID =  @TR_ID OUTPUT
 
IF @TR_ID IS NULL
  BEGIN
     PRINT '@TR_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@TR_ID cannot be NULL; statement is terminating', 1;
  END
 
EXEC GetTrailID
@TrailName = @TRname,
@TrailAddress = @TRAddress,
@Trail_ID = @T_ID OUTPUT
 
IF @T_ID IS NULL
  BEGIN
     PRINT '@T_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@T_ID cannot be NULL; statement is terminating', 1;
  END
 
BEGIN TRAN T4
INSERT INTO tblTRAIL_TERRAIN (TrailID, TerrainID)
VALUES (@T_ID, @TR_ID)
COMMIT TRAN T4
 
GO
--creating the wrapper
CREATE PROCEDURE WRAPPER_pcINSERT_TRAIL_TERRAIN
@Run INT
AS
   DECLARE @TrailName varchar(50), @TrailAddress varchar(50), @TerrainName varchar(50)
   DECLARE @TerrainPK INT, @TerrainPK INT
   DECLARE @TrailCount INT = (SELECT COUNT(*) FROM tblTRAIL)
   DECLARE @TerrainCount INT = (SELECT COUNT(*) FROM tblTERRAIN)
 
WHILE @Run > 0
 
   BEGIN
   SET @TerrainPK = (SELECT RAND() * @TerrainCount + 1)
   SET @TerrainName = (SELECT TerrainName FROM tblTERRAIN WHERE TerrainID = @TerrainPK)
 
   SET @TrailPK = (SELECT RAND() * @TrailCount +1)
   SET @TrailName = (SELECT TrailName FROM tblTRAIL WHERE TrailID = @TrailPK)
   SET @TrailAddress = (SELECT TrailAddress FROM tblTRAIL WHERE TrailID = @TrailPK)
 
   EXECUTE pcINSERT_TRAIL_TERRAIN
   @T_Terrain = @TerrainName,
   @T_Name = @TrailName,
   @T_Address = @TrailAddress
 
SET @Run = @Run - 1
   END