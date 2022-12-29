-- Project 4: Stored Procedures, Check Constraints, Computed Columns and Views
    -- Group 4: Leo Moley, Makenna Barton, Peter Carlson, AJ Whitman

USE IMT_563_Proj_04;

------- COMPUTED COLUMNS

--- Computed Column: Count active Accounts for each Account Type (Leo)

CREATE FUNCTION fn_AccountTypeCount (@PK INT)
RETURNS INT
AS
BEGIN
   DECLARE @Return INT = (SELECT Count(A.AccountID)
       FROM tblACCOUNT A
       JOIN tblACCOUNT_TYPE AT ON AT.AccountTypeID = A.AccountTypeID
       WHERE AT.AccountTypeID = @PK
           AND A.AccountEndDate IS NULL)
RETURN @Return
END
GO
 
ALTER TABLE tblACCOUNT_TYPE
ADD AccountTypeCount AS (dbo.fn_AccountTypeCount (AccountTypeID))

--- Computed Column: Average Experience Level of Reviewers for each Trail (Leo)
 
CREATE FUNCTION fn_TrailAverageExperience (@PK INT)
RETURNS NUMERIC (4,2)
AS
BEGIN
   DECLARE @Return NUMERIC (4,2) = (SELECT AVG(E.ExpNumeric)
       FROM tblEXPERIENCE E
       JOIN tblUSER U ON U.ExperienceID = E.ExperienceID
       JOIN tblREVIEW R ON R.UserID = U.UserID
       JOIN tblTRAIL T ON T.TrailID = R.TrailID
       WHERE T.TrailID = @PK)
RETURN @Return
END
GO
 
ALTER TABLE tblTRAIL
ADD AverageExperienceLevel AS (dbo.fn_TrailAverageExperience (TrailID))

--- Computed Column: Monthly price for each account type (Peter)

CREATE FUNCTION fn_MonthlyPriceAccountType (@PK INT)
RETURNS NUMERIC(9,2)
AS
BEGIN
    DECLARE @Return NUMERIC(9,2) = (
        SELECT AccountAnnualPrice / 12 
        FROM tblACCOUNT_TYPE A
        WHERE A.AccountTypeID = @PK)
    RETURN @Return
END
GO
 
ALTER TABLE tblACCOUNT_TYPE
ADD AccountMonthlyPrice as (dbo.fn_MonthlyPriceAccountType (AccountTypeID))

--- Computed Column: Account Age (Peter)

CREATE FUNCTION fn_AccountAge (@PK INT)
RETURNS INT
AS
BEGIN
    DECLARE @Return INT = (
        SELECT  DATEDIFF(Year,AccountStartDate,getdate())
        FROM tblACCOUNT A
        WHERE A.AccountID = @PK)
    RETURN @Return
END
GO
 
ALTER TABLE tblACCOUNT
ADD AccountAge as (dbo.fn_AccountAge (AccountID))

--- Computed Column: Number of trails reviewed by user (AJ)
--Function to get the number of trails reviewed:

CREATE FUNCTION FN_GetUserTrailsReviewed (@UserPK INT)
RETURNS INT
AS 
BEGIN 
    DECLARE @NumTrails INT
    SET @NumTrails = (SELECT COUNT(DISTINCT TrailID) FROM tblREVIEW WHERE UserID = @UserPK GROUP BY UserID)
    RETURN @NumTrails
END
GO

ALTER TABLE tblUSER ADD NumTrailsHiked AS dbo.FN_GetUserTrailsReviewed(UserID)
GO

---Most frequent difficulty (AJ)
--Function to get the most frequent DifficultyID for a certain trail:
CREATE FUNCTION FN_GetTrailDifficulty (@TrailPK INT)
RETURNS INT
AS 
BEGIN 
	DECLARE @DiffID INT
	SET @DiffID = (SELECT TOP 1 DifficultyID
					FROM tblREVIEW r
					WHERE r.TrailID = @TrailPK
					GROUP BY r.DifficultyID
					ORDER BY COUNT(DifficultyID) DESC)
	RETURN @DiffID
END
GO

ALTER TABLE tblTRAIL ADD DifficultyID AS dbo.FN_GetTrailDifficulty(TrailID) 
GO

--- Computed Column: Number of trails in each state (Makenna)

CREATE FUNCTION fn_NumberStateTrails_mb (@PK INT)
RETURNS INT
AS
BEGIN
   DECLARE @Ret INT = (
       SELECT DISTINCT COUNT(TrailID)
       FROM tblTRAIL T
       JOIN tblSTATE_PROVINCE SP on T.StateProvID = SP.StateProvID
       WHERE T.StateProvID = @PK
       GROUP BY T.StateProvID)
   RETURN @Ret
END
GO

ALTER TABLE tblSTATE_PROVINCE
ADD NumberStateTrails as (dbo.fn_NumberStateTrails_mb (StateProvID))

--- Computed Column: Number of pieces of equipment suggested for each trail (Makenna)

CREATE FUNCTION fn_NumberOfEquipmentPerTrail_mb(@PK INT)
RETURNS INT
AS
   BEGIN
       DECLARE @Ret INT =
           (SELECT COUNT(TrailEquipmentID)
               FROM tblTRAIL_EQUIPMENT TE
               JOIN tblTRAIL T ON TE.TrailID = T.TrailID
               WHERE T.TrailID = @PK)
       RETURN @Ret
   end
GO
ALTER TABLE tblTRAIL
ADD NumberEquipmentSuggested AS (dbo.fn_NumberOfEquipmentPerTrail_mb(TrailID))

------- BUSINESS RULES

-- Business Rule: User must be at least 13 to create an account (Leo)

CREATE FUNCTION fn_Mustbe13_forAccount()
RETURNS INTEGER
AS
BEGIN
   DECLARE @RET INTEGER = 0
   IF EXISTS (SELECT * FROM tblUSER U
       JOIN tblACCOUNT A ON U.UserID = A.UserID
   WHERE U.UserBirthDate > DateAdd(Year, -13, GetDate()))
   SET @RET = 1
RETURN @RET
END
GO
 
ALTER TABLE tblACCOUNT
ADD CONSTRAINT check_user_age
CHECK (dbo.fn_Mustbe13_forAccount() = 0)

-- Business Rule: Account must be at least 1 week old for a user to leave a review (Leo)

CREATE FUNCTION fn_AccountMustbe_1WeekOldforReview()
RETURNS INTEGER
AS
BEGIN
   DECLARE @RET INTEGER = 0
   IF EXISTS (SELECT * FROM tblUSER U
       JOIN tblACCOUNT A ON U.UserID = A.UserID
       JOIN tblREVIEW R ON U.UserID = R.UserID
   WHERE A.AccountStartDate > DateAdd(WEEK, -1, GetDate())
)
   SET @RET = 1
RETURN @RET
END
GO
 
ALTER TABLE tblREVIEW
ADD CONSTRAINT check_account_age
CHECK (dbo.fn_AccountMustbe_1WeekOldforReview() = 0)

-- Business Rule: Users with an email address ending in @uoregon.edu will be rejected from premium/pro accounts (keep quality people on the trails) (Peter)

CREATE FUNCTION fr_NoDucksPremium()
RETURNS INTEGER 
AS
BEGIN  
    DECLARE @RET INTEGER = 0
    IF EXISTS (
        SELECT *
        FROM tblUSER U
        JOIN tblACCOUNT A ON A.UserID = U.UserID
        JOIN tblACCOUNT_TYPE T ON T.AccountTypeID = A.AccountTypeID
        WHERE U.UserEmail LIKE '%@uoregon.edu'
        AND T.AccountTypeName IN ('Premium','Premium Plus','Pro', 'Pro Plus'))
    SET @RET = 1
    RETURN @RET
END
GO
 
ALTER TABLE tblACCOUNT_TYPE WITH NOCHECK
ADD CONSTRAINT DuckHuntingSeason
CHECK (dbo.fr_NoDucksPremium() = 0)

-- Business Rule: User must be at least 18 to be listed as an Expert (Peter)
 
 
CREATE FUNCTION fn_Mustbe18_tobeExpert()
RETURNS INTEGER
AS
BEGIN
DECLARE @RET INTEGER = 0
 
IF EXISTS (SELECT * FROM tblUSER U
JOIN tblEXPERIENCE E ON U.ExperienceID = E.ExperienceID
WHERE U.UserBirthDate > DateAdd(Year, -18, GetDate())
AND E.ExpLevel IN ('Expert','Expert Backpacker'))
SET @RET = 1
RETURN @RET
END
GO
 
 
ALTER TABLE tblUSER
ADD CONSTRAINT check_user_age_experience
CHECK (dbo.fn_Mustbe18_tobeExpert() = 0)

-- Business Rule: Trails with more than 10 equipment items suggested cannot be of difficulty Easiest (Makenna)

CREATE FUNCTION fn_MoreThan10EquipmentOnEasiestTrails()
RETURNS INT
AS
   BEGIN
       DECLARE @Ret INT = 0
       IF EXISTS(SELECT * FROM tblTRAIL T
           JOIN tblDIFFICULTY D ON T.DifficultyID = D.DifficultyID
           WHERE DifficultyName = 'Easiest'
           AND NumberEquipmentSuggested > 10)
       BEGIN
           SET @Ret = 1
       end
       RETURN @Ret
   end
GO

ALTER TABLE tblTRAIL
ADD CONSTRAINT CK_NoEasiestTrailsWithMoreThan10Equipment
CHECK (dbo.fn_MoreThan10EquipmentOnEasiestTrails() = 0)

-- Users of ExpLevel Novice cannot write a review on trails of DifficultyName Very Strenuous (Makenna)
CREATE FUNCTION fn_NoviceOnVeryStrenuousTrails()
RETURNS INT
AS
   BEGIN
       DECLARE @Ret INT = 0
       IF EXISTS(SELECT * FROM tblEXPERIENCE E
           JOIN tblUSER U ON E.ExperienceID = U.ExperienceID
           JOIN tblREVIEW R on U.UserID = R.UserID
           JOIN tblDIFFICULTY D on R.DifficultyID = D.DifficultyID
           WHERE DifficultyName = 'Very Strenuous'
           AND ExpLevel = 'Novice')
       BEGIN
           SET @Ret = 1
       end
   RETURN @Ret
   end
GO
ALTER TABLE tblREVIEW
ADD CONSTRAINT CK_NoNoviceReviewsOnVeryStrenuousTrails
CHECK (dbo.fn_NoviceOnVeryStrenuousTrails() = 0)

-- Business Rule: Reviews more than 30 days old cannot be edited (AJ)
ALTER TABLE tblREVIEW ADD EditDate DATE; -- Run first
ALTER TABLE tblREVIEW ADD CONSTRAINT NoEdit30Days CHECK (DATEDIFF(DAY, ReviewDate, EditDate) <=30)
GO

-- Business Rule: Review/Condition pairings only need to be registered once (AJ)
ALTER TABLE tblREVIEW_CONDITION ADD CONSTRAINT UC_RevCond UNIQUE (ReviewID, ConditionID)
GO

-- Business Rule: Single user can only leave one review per trail per month (30 days) (AJ)
CREATE FUNCTION FN_CheckUserTrailReviewTime (@UserPK INT, @TrailPK INT, @RevDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @NumDays INT
    SET @NumDays = (SELECT MIN(DATEDIFF(day,ReviewDate,@RevDate)) 
                    FROM tblREVIEW 
                    WHERE UserID=@UserPK AND TrailID=@TrailPK)
    RETURN @NumDays
END
GO
ALTER TABLE tblREVIEW ADD CONSTRAINT OneReview_User_Trail_Month 
CHECK (dbo.FN_CheckUserTrailReviewTime(UserID,TrailID,ReviewDate) > 30)
GO

------- STORED PROCEDURES

--- Stored Procedure: GetID's for all Look-up Tables

CREATE PROCEDURE GetTerrainID
@Terrain varchar(50),
@TR_ID INT OUTPUT
AS
   SET @TR_ID = (SELECT TerrainID FROM tblTERRAIN WHERE TerrainName = @Terrain)
GO

CREATE PROCEDURE GetDifficultyID
@Difficulty varchar(50),
@D_ID INT OUTPUT
AS
   SET @D_ID = (SELECT DifficultyID FROM tblDIFFICULTY WHERE DifficultyName = @Difficulty)
GO

CREATE PROCEDURE GetSeasonID
@Season varchar(50),
@S_ID INT OUTPUT
AS
   SET @S_ID = (SELECT SeasonID FROM tblSEASON WHERE SeasonName = @Season)
GO

CREATE PROCEDURE GetTrailType
@TrailType varchar(100),
@TT_ID INT OUTPUT
AS
   SET @TT_ID = (SELECT TrailTypeID FROM tblTRAIL_TYPE WHERE TrailTypeName = @TrailType)
GO

CREATE PROCEDURE GetEquipmentTypeID
@EquipType varchar(100),
@ET_ID INT OUTPUT
AS
   SET @ET_ID = (SELECT EquipmentTypeID FROM tblEQUIPMENT_TYPE WHERE EquipmentTypeName = @EquipType)
GO

CREATE PROCEDURE GetEquipmentID
@Equip varchar(250),
@E_ID INT OUTPUT
AS
   SET @E_ID = (SELECT EquipmentID FROM tblEQUIPMENT WHERE EquipmentName = @Equip)
GO

CREATE PROCEDURE GetActivityID
@Activity varchar(250),
@A_ID INT OUTPUT
AS
   SET @A_ID = (SELECT ActivityID FROM tblACTIVITY WHERE ActivityName = @Activity)
GO

CREATE PROCEDURE GetTrailID
@Trail varchar(250),
@Address varchar(250),
@T_ID INT OUTPUT
AS
   SET @T_ID = (SELECT TrailID FROM tblTRAIL WHERE TrailName = @Trail AND TrailAddress = @Address)
GO

CREATE PROCEDURE GetReviewID
@Review varchar(250),
@RDate date,
@R_ID INT OUTPUT
AS
   SET @R_ID = (SELECT ReviewID FROM tblREVIEW WHERE ReviewHeader = @Review AND ReviewDate = @RDate)
GO
CREATE PROCEDURE GetRatingID
@RatingName varchar(250),
@R_ID INT OUTPUT
AS
   SET @R_ID = (SELECT RatingID FROM tblRATING WHERE RatingName = @RatingName)
GO

CREATE PROCEDURE GetConditionID
@Condition varchar(100),
@C_ID INT OUTPUT
AS
   SET @C_ID = (SELECT ConditionID FROM tblCONDITION WHERE ConditionName = @Condition)
GO

CREATE PROCEDURE GetStateProvID
@StateProv varchar(50),
@SP_ID INT OUTPUT
AS
   SET @SP_ID = (SELECT StateProvID FROM tblSTATE_PROVINCE WHERE StateProvName = @StateProv)
GO

CREATE PROCEDURE GetCountryID
@Country varchar(50),
@C_ID INT OUTPUT
AS
   SET @C_ID = (SELECT CountryID FROM tblCOUNTRY WHERE CountryName = @Country)
GO

CREATE PROCEDURE GetContinentID
@Contnt varchar(50),
@Cont_ID INT OUTPUT
AS
   SET @Cont_ID = (SELECT ContinentID FROM tblCONTINENT WHERE ContinentName = @Contnt OR ContinentCode = @Contnt)
GO

CREATE PROCEDURE GetAccountTypeID
@AccountType varchar(100),
@AT_ID INT OUTPUT
AS
   SET @AT_ID = (SELECT AccountTypeID FROM tblACCOUNT_TYPE WHERE AccountTypeName = @AccountType)
GO

CREATE PROCEDURE GetExperienceID
@Exp varchar(100),
@E_ID INT OUTPUT
AS
   SET @E_ID = (SELECT ExperienceID FROM tblEXPERIENCE WHERE ExpLevel = @Exp)
GO

CREATE PROCEDURE GetUserID
@Fname varchar(50),
@Lname varchar(100),
@Birth date,
@U_ID INT OUTPUT
AS
   SET @U_ID = (SELECT UserID FROM tblUSER WHERE UserFname = @Fname AND UserLname = @Lname AND UserBirthDate = @Birth)
GO

CREATE PROCEDURE GetGenderID
@Gender varchar(20),
@G_ID INT OUTPUT
AS
   SET @G_ID = (SELECT GenderID FROM tblGENDER WHERE GenderName = @Gender)
GO

--- Stored Procedure: INSERT_ACCOUNT (Leo)
 
CREATE PROCEDURE lpmINSERT_ACCOUNT
@AT_name VARCHAR(100),
@UFname VARCHAR(50),
@ULname VARCHAR(100),
@UBirth DATE,
@AccountStart DATE,
@AccountEnd DATE
AS
DECLARE @UID INT, @ATID INT
 
EXEC GetAccountTypeID
@AccountType = @AT_name,
@AT_ID =  @ATID OUTPUT
 
IF @ATID IS NULL
 BEGIN
    PRINT '@ATID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
    THROW 56676, '@ATID cannot be NULL; statement is terminating', 1;
 END
 
EXEC GetUserID
@Fname = @UFname,
@Lname = @ULname,
@Birth = @UBirth,
@U_ID = @UID OUTPUT
 
IF @UID IS NULL
 BEGIN
    PRINT '@UID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
    THROW 56676, '@UID cannot be NULL; statement is terminating', 1;
 END
 
BEGIN TRAN T1
INSERT INTO tblACCOUNT (AccountStartDate, AccountEndDate, UserID, AccountTypeID)
VALUES (@AccountStart, @AccountEnd, @UID, @ATID)
COMMIT TRAN T1

--- Stored Procedure: INSERT_TRAIL_ACTIVITY (Leo)

CREATE PROCEDURE lpmINSERT_TRAIL_ACTIVITY
@T_Activity VARCHAR(250),
@T_Name VARCHAR(250),
@T_Address VARCHAR(250)
AS
DECLARE @AID INT, @TID INT
 
EXEC GetActivityID
@Activity = @T_Activity,
@A_ID =  @AID OUTPUT
 
IF @AID IS NULL
  BEGIN
     PRINT '@AID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@AID cannot be NULL; statement is terminating', 1;
  END
 
EXEC GetTrailID
@Trail = @T_Name,
@Address = @T_Address,
@T_ID = @TID OUTPUT
 
IF @TID IS NULL
  BEGIN
     PRINT '@TID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@TID cannot be NULL; statement is terminating', 1;
  END
 
BEGIN TRAN T1
INSERT INTO tblTRAIL_ACTIVITY (TrailID, ActivityID)
VALUES (@TID, @AID)
COMMIT TRAN T1

--- Stored Procedure: INSERT_TRAIL_EQUIPMENT (Peter)
 
CREATE PROCEDURE pcINSERT_TRAIL_EQUIPMENT
@Equipment VARCHAR(50),
@TRname VARCHAR(250),
@TRAddress VARCHAR(250)
AS
DECLARE @E_ID INT, @T_ID INT
 
EXEC GetEquipmentID
@EquipmentName = @Equipment,
@Equipment_ID =  @E_ID OUTPUT
 
IF @E_ID IS NULL
  BEGIN
     PRINT '@E_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@E_ID cannot be NULL; statement is terminating', 1;
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
 
BEGIN TRAN T3
INSERT INTO tblTRAIL_EQUIPMENT (TrailID, EquipmentID)
VALUES (@T_ID, @E_ID)
COMMIT TRAN T3

--- Stored Procedure: INSERT_TRAIL_TERRAIN (Peter)

CREATE PROCEDURE pcINSERT_TRAIL_TERRAIN
@TName VARCHAR(50),
@TRname VARCHAR(250),
@TRAddress VARCHAR(250)
AS
DECLARE @TRID INT, @TID INT
 
EXEC GetTerrainID
@Terrain = @TName,
@TR_ID =  @TRID OUTPUT
 
IF @TRID IS NULL
  BEGIN
     PRINT '@TRID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@TRID cannot be NULL; statement is terminating', 1;
  END
 
EXEC GetTrailID
@Trail = @TRname,
@Address = @TRAddress,
@T_ID = @TID OUTPUT
 
IF @TID IS NULL
  BEGIN
     PRINT '@TID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
     THROW 56676, '@TID cannot be NULL; statement is terminating', 1;
  END
 
BEGIN TRAN T4
INSERT INTO tblTRAIL_TERRAIN (TrailID, TerrainID)
VALUES (@TID, @TRID)
COMMIT TRAN T4

--- Stored Procedure: INSERT INTO tblUSER (Makenna)

CREATE PROCEDURE INSERT_User_mb
@F varchar(50),
@L varchar(50),
@BD date,
@Phone varchar(15),
@email varchar(100),
@Address varchar(100),
@City varchar(100),
@ZipCode varchar(15),
@State varchar(50),
@Gender varchar(50),
@Experience varchar(100)
AS
   DECLARE @SPID INT, @GID INT, @EID INT

   EXEC GetStateProvID
   @StateProv = @State,
   @SP_ID = @SPID OUTPUT
   IF @SPID IS NULL
     BEGIN
        PRINT '@SPID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@SPID cannot be NULL; statement is terminating', 1;
     END

   EXEC GetGenderID
   @Gender = @Gender,
   @G_ID = @GID OUTPUT
   IF @GID IS NULL
     BEGIN
        PRINT '@GID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@GID cannot be NULL; statement is terminating', 1;
     END

   EXEC GetExperienceID
   @Exp = @Experience,
   @E_ID = @EID OUTPUT
   IF @EID IS NULL
     BEGIN
        PRINT '@EID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@EID cannot be NULL; statement is terminating', 1;
     END

BEGIN TRANSACTION T1
INSERT INTO tblUSER(UserFname, UserLname, UserBirthDate, UserPhone, UserEmail, StreetAddress, City, Zipcode, StateProvID, ExperienceID, GenderID)
VALUES (@F, @L, @BD, @Phone, @email, @Address, @City, @ZipCode, @SPID, @EID, @GID)
IF @@ERROR <> 0
   BEGIN
       ROLLBACK TRANSACTION T1
   end
ELSE
   COMMIT TRANSACTION T1

--- Stored Procedure: INSERT INTO tblTRAIL (Makenna)

CREATE PROCEDURE INSERT_Trail_mb
@Name varchar(200),
@Length numeric(8,2),
@Elevation numeric(8,2),
@Lat decimal(20,15),
@Long decimal(20,15),
@Add varchar(50),
@City varchar(50),
@State varchar(50),
@Seas varchar(50),
@TrailT varchar(50)
AS
   DECLARE @Sea_ID INT, @TrailT_ID INT, @State_ID INT

   EXEC GetSeasonID
   @Season = @Seas,
   @S_ID = @Sea_ID OUTPUT
   IF @Sea_ID IS NULL
     BEGIN
        PRINT '@Sea_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@Sea_ID cannot be NULL; statement is terminating', 1;
     END

   EXEC GetTrailType
   @TrailType = @TrailT,
   @TT_ID = @TrailT_ID OUTPUT
   IF @TrailT_ID IS NULL
     BEGIN
        PRINT '@TrailT_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@TrailT_ID cannot be NULL; statement is terminating', 1;
     END

   EXEC GetStateProvID
   @StateProv = @State,
   @SP_ID = @State_ID OUTPUT
   IF @State_ID IS NULL
     BEGIN
        PRINT '@State_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@State_ID cannot be NULL; statement is terminating', 1;
     END

BEGIN TRANSACTION T2
INSERT INTO tblTRAIL(TrailName, TrailLength, TrailElevationGain, TrailLatitude,
                    TrailLongitude, TrailAddress, TrailCity, SeasonID, TrailTypeID, StateProvID)
VALUES (@Name, @Length, @Elevation, @Lat, @Long, @Add, @City, @Sea_ID, @TrailT_ID, @State_ID)
IF @@ERROR <> 0
   BEGIN
       ROLLBACK TRANSACTION T2
   end
ELSE
   COMMIT TRANSACTION T2

--- Stored Procedure: INSERT into tblREVIEW and tblREVIEW_CONDITION (Makenna)

CREATE PROCEDURE INSERT_Review_ReviewCondition_mb
@Header varchar(30),
@Body varchar(1000),
@TrailName varchar(50),
@TrailAddress varchar(50),
@F varchar(50),
@L varchar(50),
@BD date,
@Rating varchar(50),
@Date date,
@ConditionName varchar(50),
@Diff varchar(50)
AS
   DECLARE @TID INT, @UID INT, @RID INT, @CID INT, @DID INT, @Review_ID INT
   EXEC GetTrailID
   @Trail = @TrailName,
   @Address = @TrailAddress,
   @T_ID = @TID OUTPUT
   IF @TID IS NULL
     BEGIN
        PRINT '@TID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@TID cannot be NULL; statement is terminating', 1;
     END
   EXEC GetUserID
   @Fname = @F,
   @Lname = @L,
   @Birth = @BD,
   @U_ID = @UID OUTPUT
   IF @UID IS NULL
     BEGIN
        PRINT '@UID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@UID cannot be NULL; statement is terminating', 1;
     END
   EXEC GetRatingID
   @RatingName = @Rating,
   @R_ID = @RID OUTPUT
   IF @RID IS NULL
     BEGIN
        PRINT '@RID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@RID cannot be NULL; statement is terminating', 1;
     END
   EXEC GetConditionID
   @Condition = @ConditionName,
   @C_ID = @CID OUTPUT
   IF @CID IS NULL
     BEGIN
        PRINT '@CID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@CID cannot be NULL; statement is terminating', 1;
     END
   EXEC GetDifficultyID
   @Difficulty = @Diff,
   @D_ID = @DID OUTPUT
   IF @DID IS NULL
     BEGIN
        PRINT '@DID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
        THROW 56575, '@DID cannot be NULL; statement is terminating', 1;
     END
BEGIN TRANSACTION T1
   INSERT INTO tblREVIEW(TrailID, ReviewHeader, ReviewDescr, ReviewDate, UserID, RatingID, DifficultyID, EditDate)
   VALUES (@TID, @Header, @Body, @Date, @UID, @RID, @DID, GETDATE())

   SET @Review_ID = (SELECT scope_identity())

   INSERT INTO tblREVIEW_CONDITION(ReviewID, ConditionID)
   VALUES (@Review_ID, @CID)
   IF @@ERROR <> 0
       BEGIN
           ROLLBACK TRANSACTION T1
       end
   ELSE
   COMMIT TRANSACTION T1
go


--- Stored Procedure: Add another Review/Condition, since it's many-to-many, and that's not reflected in the original (AJ)

CREATE PROCEDURE INSERT_AdditionalReviewCondition_ajw
@RHeader varchar(30),
@ReviewDate date,
@ConditionName varchar(50)
AS
    DECLARE @RevID INT, @CondID INT, @CheckRC INT
    
    EXEC GetReviewID @Review=@RHeader, @RDate=@ReviewDate, @R_ID=@RevID OUTPUT
    IF @RevID IS NULL
        BEGIN 
            PRINT 'Review not found; cannot update this review. Check original Header and ReviewDate.';
            THROW 56580, '@RevID cannot be NULL; statement is terminating', 1;
        END

    EXEC GetConditionID @Condition = @ConditionName, @C_ID = @CondID OUTPUT
    IF @CondID IS NULL
        BEGIN
            PRINT '@CondID is NULL and will fail during the INSERT transaction; check spelling of all parameters';
            THROW 56581, '@CondID cannot be NULL; statement is terminating', 1;
        END
    
    SET @CheckRC=(SELECT ReviewConditionID FROM tblREVIEW_CONDITION WHERE ReviewID=@RevID AND ConditionID=@CondID)
    IF @CheckRC is NOT NULL
        BEGIN
            PRINT 'This Review/Condition association is already registered, and does not need to be registered again.';
            THROW 56581, 'ReviewID to ConditionID pairs should be unique; statement is terminating', 1;
        END

    BEGIN TRANSACTION AddReviewCondition
        INSERT INTO tblREVIEW_CONDITION(ReviewID, ConditionID)
        VALUES (@RevID, @CondID)
        IF @@ERROR <> 0
            BEGIN
                ROLLBACK TRANSACTION AddReviewCondition
            END
        ELSE
        COMMIT TRANSACTION AddReviewCondition
GO

--- Stored Procedure: Edit/Update a review (AJ)
CREATE PROCEDURE UPDATE_Review_ReviewCondition_ajw
@OldHeader varchar(30),
@ReviewDate date,
@NewHeader varchar(30) = NULL,
@NewBody varchar(1000) = NULL,

@NewTrailName varchar(50) = NULL,
@NewTrailAddress varchar(50) = NULL,

@NewRating varchar(50) = NULL,
@NewDiff varchar(50) = NULL,
@NewConditionName varchar(50) = NULL,

@EditDate date = NULL
AS
    IF @EditDate IS NULL BEGIN SET @EditDate = GetDate() END
    IF DATEDIFF(day,@ReviewDate,@EditDate) > 30
        BEGIN 
            PRINT 'Reviews older than 30 days old cannot be edited.';
            THROW 56574, 'DATEDIFF(day,@ReviewDate,@EditDate)) > 30; statement terminating', 1;
        END

    DECLARE @Review_ID INT, @TID INT, @RID INT, @CID INT, @DID INT
    EXEC GetReviewID @Review=@OldHeader, @RDate=@ReviewDate, @R_ID=@Review_ID OUTPUT
    IF @Review_ID IS NULL
        BEGIN 
            PRINT 'Review not found; cannot update this review. Check original Header and ReviewDate.';
            THROW 56575, '@Review_ID cannot be NULL; statement is terminating', 1;
        END
    --If new values were not specified, keep the old ones
    IF @NewHeader IS NULL BEGIN SET @NewHeader=(SELECT ReviewHeader FROM tblREVIEW WHERE ReviewID=@Review_ID) END
    IF @NewBody IS NULL BEGIN SET @NewBody=(SELECT ReviewDescr FROM tblREVIEW WHERE ReviewID=@Review_ID) END
    
    --Deal with new/old trail addresses
    IF @NewTrailName IS NOT NULL AND @NewTrailAddress IS NOT NULL
        BEGIN EXEC GetTrailID @Trail=@NewTrailName, @Address=@NewTrailAddress,@T_ID=@TID OUTPUT
        END
    ELSE IF @NewTrailName IS NULL AND @NewTrailAddress IS NULL
        BEGIN SET @TID=(SELECT TrailID FROM tblREVIEW WHERE ReviewID=@Review_ID)
        END
    ELSE IF @NewTrailName IS NOT NULL OR @NewTrailAddress IS NOT NULL
        BEGIN
            If @NewTrailName IS NULL 
                BEGIN 
                    SET @NewTrailName=(SELECT TrailName FROM tblTRAIL 
                    WHERE TrailID=(SELECT TrailID FROM tblREVIEW WHERE ReviewID=@Review_ID))
                END
            ELSE IF @NewTrailAddress IS NULL 
                BEGIN
                    SET @NewTrailAddress=(SELECT TrailAddress FROM tblTRAIL 
                    WHERE TrailID=(SELECT TrailID FROM tblREVIEW WHERE ReviewID=@Review_ID))
                END
            EXEC GetTrailID @Trail=@NewTrailName, @Address=@NewTrailAddress,@T_ID=@TID OUTPUT
        END
    IF @TID IS NULL
        BEGIN
            PRINT '@TID is NULL and will fail during the UPDATE transaction; check spelling of all parameters';
            THROW 56575, '@TID cannot be NULL; statement is terminating', 1;
        END

    IF @NewRating IS NOT NULL
        BEGIN EXEC GetRatingID @RatingName = @NewRating, @R_ID = @RID OUTPUT END
    ELSE BEGIN SET @RID=(SELECT RatingID FROM tblREVIEW WHERE ReviewID=@Review_ID) END
    IF @RID IS NULL
        BEGIN
            PRINT '@RID is NULL and will fail during the UPDATE transaction; check spelling of all parameters';
            THROW 56575, '@RID cannot be NULL; statement is terminating', 1;
        END

    IF @NewDiff IS NOT NULL
        BEGIN EXEC GetDifficultyID @Difficulty = @NewDiff, @D_ID = @DID OUTPUT END
    ELSE BEGIN SET @DID=(SELECT DifficultyID FROM tblREVIEW WHERE ReviewID=@Review_ID) END
    IF @DID IS NULL
        BEGIN
            PRINT '@DID is NULL and will fail during the UPDATE transaction; check spelling of all parameters';
            THROW 56575, '@DID cannot be NULL; statement is terminating', 1;
        END

    DECLARE @OldCID INT
    SET @OldCID = (SELECT ConditionID FROM tblREVIEW_CONDITION WHERE ReviewID=@Review_ID)
    IF @NewConditionName IS NOT NULL
        BEGIN EXEC GetConditionID @Condition = @NewConditionName, @C_ID = @CID OUTPUT END
    ELSE BEGIN SET @CID=@OldCID END
    IF @CID IS NULL
        BEGIN
            PRINT '@CID is NULL and will fail during the UPDATE transaction; check spelling of all parameters';
            THROW 56575, '@CID cannot be NULL; statement is terminating', 1;
        END

    BEGIN TRANSACTION UpdateReviewT1
        UPDATE tblREVIEW
        SET TrailID = @TID,
            ReviewHeader = @NewHeader,
            ReviewDescr = @NewBody,
            RatingID = @RID,
            DifficultyID = @DID,
            EditDate = @EditDate
        WHERE ReviewID=@Review_ID

        IF @NewConditionName IS NOT NULL --If it was, we set @CID but never actually changed this! So we only update this if it's new.
            BEGIN TRANSACTION UpdateRevConT2
                UPDATE tblREVIEW_CONDITION
                SET ConditionID = @CID
                WHERE ReviewID=@Review_ID AND ConditionID=@OldCID
            COMMIT TRANSACTION UpdateRevConT2
        
        IF @@ERROR <> 0
            ROLLBACK TRANSACTION UpdateReviewT1
        ELSE
            COMMIT TRANSACTION UpdateReviewT1
GO

------- COMPLEX QUERIES

-- Complex Query: Determine the account type distributions of users ages 25-34 for all states/provinces (Leo)

CREATE VIEW RankAccountTotals_25to34Users_PartitionbyState_lpm AS
(SELECT S.StateProvName, AT.AccountTypeName, Count(A.AccountID) AS NumAccounts, 
RANK() OVER (PARTITION BY StateProvName ORDER BY Count(A.AccountID) DESC) AS RankAccountTotal
FROM tblUSER U
    JOIN tblSTATE_PROVINCE S ON S.StateProvID = U.StateProvID
    JOIN tblACCOUNT A ON A.UserID = U.UserID
    JOIN tblACCOUNT_TYPE AT ON AT.AccountTypeID = A.AccountTypeID
WHERE DATEDIFF(YEAR, U.UserBirthDate, GETDATE()) BETWEEN 25 AND 34
GROUP BY AT.AccountTypeName, S.StateProvName)

SELECT * FROM RankAccountTotals_25to34Users_PartitionbyState_lpm

--- Complex Query: Select the highest rated trails in the PNW (Washington, Oregon, Idaho, British Columbia) that fit the following criteria (Leo): 
-- 1) Rated for snow sport activities (Cross country skiing, Skiing, Snowshoeing)
-- 2) Rated 'Easiest' to 'Moderate' in difficulty

CREATE VIEW RankingEasytoModeratePNWSnowSportTrailsbyRating_lpm AS
(SELECT T.TrailID, T.TrailName, SP.StateProvName, (Sum(R.RatingNumeric)/COUNT(R.RatingID)) AS AvgRating,
    DENSE_RANK() OVER (ORDER BY (Sum(R.RatingNumeric)/COUNT(R.RatingID)) DESC ) AS AvgRatingRanking
FROM tblRATING R
    JOIN tblREVIEW RW ON R.RatingID = RW.RatingID
    JOIN tblDIFFICULTY D ON RW.DifficultyID = D.DifficultyID
    JOIN tblUSER U ON U.UserID = RW.UserID
    JOIN tblTRAIL T ON RW.TrailID = T.TrailID
    JOIN tblTRAIL_ACTIVITY TA ON TA.TrailID = T.TrailID
    JOIN tblACTIVITY A ON A.ActivityID = TA.ActivityID
    JOIN tblEXPERIENCE E ON E.ExperienceID = U.ExperienceID
    JOIN tblSTATE_PROVINCE SP on T.StateProvID = SP.StateProvID
WHERE SP.StateProvName in ('Washington', 'Oregon', 'Idaho', 'British Columbia')
    AND A.ActivityName in ('Snowshoeing', 'Cross country skiing', 'Skiing')
    AND DifficultyName in ('Easiest', 'Moderate')
GROUP BY T.TrailID, T.TrailName, SP.StateProvName)

SELECT * FROM RankingEasytoModeratePNWSnowSportTrailsbyRating_lpm

-- Complex Query: Select top 10 trails by rating in each state via average rating (Peter)

ALTER VIEW Top10TrailsRatingByState
AS
WITH CTE__Top10TrailsRatingByState(TrailID, Trailname,StateProvince, Rating, RankRating)
AS
(SELECT T.TrailID, T.TrailName,SP.StateProvName, AVG(RatingNumeric) AS AverageRating,
DENSE_RANK() OVER (PARTITION BY StateProvName ORDER BY AVG(RatingNumeric) DESC) AS AverageRatingRank
FROM tblTRAIL T
JOIN tblREVIEW RV ON RV.TrailID = T.TrailID
JOIN tblRATING R ON R.RatingID = RV.RatingID
JOIN tblSTATE_PROVINCE SP ON SP.StateProvID = T.StateProvID
GROUP BY T.TrailID, T.TrailName,SP.StateProvName)

SELECT * 
FROM CTE__Top10TrailsRatingByState
WHERE RankRating <= 10

SELECT * FROM Top10TrailsRatingByState


-- Complex Query: Select top 10 trails by rating for each Season (Peter)

ALTER VIEW Top10TrailsRatingBySeason
AS
WITH CTE__Top10TrailsRatingBySeason(TrailID, Trailname, Season, StateProvince, Rating, RankRating)
AS
(SELECT T.TrailID, T.TrailName,S.SeasonName, SP.StateProvName, AVG(RatingNumeric) AS AverageRating,
DENSE_RANK() OVER (PARTITION BY SeasonName ORDER BY AVG(RatingNumeric) DESC) AS AverageRatingRank
FROM tblTRAIL T
JOIN tblREVIEW RV ON RV.TrailID = T.TrailID
JOIN tblSEASON S ON S.SeasonID = T.SeasonID
JOIN tblRATING R ON R.RatingID = RV.RatingID
JOIN tblSTATE_PROVINCE SP ON SP.StateProvID = T.StateProvID
JOIN tblDIFFICULTY D ON D.DifficultyID = RV.DifficultyID
GROUP BY T.TrailID, T.TrailName,S.SeasonName, SP.StateProvName)
 
 
SELECT * 
FROM CTE__Top10TrailsRatingBySeason
WHERE RankRating <= 10

SELECT * FROM Top10TrailsRatingBySeason


-- Complex Query: What are the most needed types of equipment for Trails in the PNW (Washington, Oregon, Idaho, British Columbia)
-- that have at least 1,200 ft of elevation gain (Makenna)

CREATE VIEW PNW1200ElevationGainEquipmentTypes_mb AS
(SELECT ET.EquipmentTypeName, COUNT(E.EquipmentTypeID) NumTypeEquip,
       DENSE_RANK() over (ORDER BY COUNT(E.EquipmentTypeID) DESC ) AS EquipmentTypeRanking
FROM tblEQUIPMENT_TYPE ET
JOIN tblEQUIPMENT E ON ET.EquipmentTypeID = E.EquipmentTypeID
JOIN tblTRAIL_EQUIPMENT TE ON E.EquipmentID = TE.EquipmentID
JOIN tblTRAIL T ON TE.TrailID = T.TrailID
JOIN tblSTATE_PROVINCE S ON T.StateProvID = S.StateProvID
WHERE TrailElevationGain > 1200.00
AND (StateProvName = 'Washington'
OR StateProvName = 'Idaho'
OR StateProvName = 'Oregon'
OR StateProvName = 'British Columbia')
GROUP BY ET.EquipmentTypeName)

SELECT * FROM PNW1200ElevationGainEquipmentTypes_mb

-- Complex Query: What States, that have at least 2000 trail ratings, have the most highly rated trails on average? (Makenna)

CREATE VIEW RankingStatesWithAtLeast2000ReviewsByAvgTrailRating_mb AS
(SELECT StateProvName, (Sum(R.RatingNumeric)/COUNT(R.RatingID)) AS AvgRating, COUNT(RW.TrailID) AS NumTrailReviews,
     DENSE_RANK() over (ORDER BY (Sum(R.RatingNumeric)/COUNT(R.RatingID)) DESC ) AS AvgRatingRanking
FROM tblRATING R
JOIN tblREVIEW RW ON R.RatingID = RW.RatingID
JOIN tblTRAIL T ON RW.TrailID = T.TrailID
JOIN tblSTATE_PROVINCE SP on T.StateProvID = SP.StateProvID
GROUP BY StateProvName
HAVING COUNT(RW.TrailID) >= 2000)

SELECT * FROM PNW1200ElevationGainEquipmentTypes_mb


--- Complex Query: Select the top three most-cited Conditions in each state (AJ)

Create View TopThreeMostCitedConditions_ByState as 
    With CountConditions as (
        Select StateProvName, ConditionName, c.ConditionID, Count(c.ConditionID) as CountCited_Cond, 
            Rank() over (
                Partition By StateProvName
                Order By Count(c.ConditionID) Desc) as RankCited_Cond
        From tblREVIEW r 
            join tblREVIEW_CONDITION rc on r.ReviewID=rc.ReviewID
            join tblCONDITION c on c.ConditionID=rc.ConditionID
            join tblDIFFICULTY d on d.DifficultyID=r.DifficultyID
            join tblTRAIL t on t.TrailID = r.TrailID
            join tblSTATE_PROVINCE s on s.StateProvID = t.StateProvID
        Group By StateProvName, ConditionName, c.ConditionID) 
    Select StateProvName, RankCited_Cond, ConditionName, CountCited_Cond
    From CountConditions
    Where RankCited_Cond <= 3



--- Complex Query: Select the Trails with the highest number of reviews from Pro accounts (Pro, Pro Plus), 
--ranked by the average number of reviews those accounts give them per month (AJ)

Create View TrailsWithMostProReviews as 
    With TrailMonthRevs as (
        Select TrailName, MONTH(ReviewDate) as [Month], count(r.ReviewID) as NumReviews
        From tblREVIEW r
            join tblTRAIL t on t.TrailID = r.TrailID
            join tblSTATE_PROVINCE sp on sp.StateProvID = t.StateProvID
            join tblUSER u on u.UserID = r.UserID
            join tblACCOUNT a on a.UserID = u.UserID
            join tblACCOUNT_TYPE act on act.AccountTypeID = a.AccountTypeID
        Where AccountTypeName LIKE 'Pro%'
        Group By TrailName, MONTH(ReviewDate)
        )
    Select TrailName, avg(NumReviews) as AvgProRevsPerMonth, 
        RANK() Over (Order By avg(NumReviews) Desc) as Rank_AvgRevsPerMonth
    From TrailMonthRevs
    Group By TrailName
Go
    Select * from TrailsWithMostProReviews
    Order By Rank_AvgRevsPerMonth Asc