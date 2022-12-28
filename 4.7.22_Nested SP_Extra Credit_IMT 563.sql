CREATE PROCEDURE lpmGetQuarterID
@Q_Name varchar(50),
@Quarter_ID INT OUTPUT
AS
SET @Quarter_ID = (SELECT QuarterID FROM tblQUARTER WHERE QuarterName = @Q_Name)
GO

CREATE PROCEDURE lpmGetCourseID
@C_Name varchar(50),
@Course_ID INT OUTPUT
AS
SET @Course_ID = (SELECT CourseID FROM tblCOURSE WHERE CourseName = @C_Name)
GO

CREATE PROCEDURE lpmGetClassroomID
@C_Room varchar(50),
@Classroom_ID INT OUTPUT
AS
SET @Classroom_ID = (SELECT ClassroomID FROM tblCLASSROOM WHERE ClassroomName = @C_Room)
GO

CREATE PROCEDURE lpmGetScheduleID
@Schedule_Name varchar(50),
@Schedule_ID INT OUTPUT
AS
SET @Schedule_ID = (SELECT ScheduleID FROM tblSCHEDULE WHERE ScheduleName = @Schedule_Name)
GO

CREATE PROCEDURE lpmINSERT_CLASS
@Quarter_Name varchar(50),
@Course_Name varchar(50),
@Classroom_Name varchar(50),
@Sched_Name varchar(50),
@Section char(2),
@Yr char(4)
AS
DECLARE @Q_ID INT, @C_ID INT, @CR_ID INT, @S_ID INT

EXEC lpmGetQuarterID
@Q_Name = @Quarter_Name,
@Quarter_ID = @Q_ID OUTPUT

IF @Q_ID IS NULL
	BEGIN
		PRINT '@Q_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters'; 
		THROW 56676, '@Q_ID cannot be NULL; statement is terminating', 1; 
	END

EXEC lpmGetCourseID
@C_Name = @Course_Name,
@Course_ID = @C_ID OUTPUT

IF @C_ID IS NULL
	BEGIN
		PRINT '@C_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters'; 
		THROW 56676, '@C_ID cannot be NULL; statement is terminating', 1; 
	END

EXEC lpmGetClassroomID
@C_Room = @Classroom_Name,
@Classroom_ID = @CR_ID OUTPUT

IF @CR_ID IS NULL
	BEGIN
		PRINT '@CR_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters'; 
		THROW 56676, '@CR_ID cannot be NULL; statement is terminating', 1; 
	END

EXEC lpmGetScheduleID
@Schedule_Name = @Sched_Name,
@Schedule_ID = @S_ID OUTPUT

IF @S_ID IS NULL
	BEGIN
		PRINT '@S_ID is NULL and will fail during the INSERT transaction; check spelling of all parameters'; 
		THROW 56676, '@S_ID cannot be NULL; statement is terminating', 1; 
	END

BEGIN TRAN T1
INSERT INTO tblCLASS (CourseID, QuarterID, [YEAR], ClassroomID, ScheduleID, Section)
VALUES (@C_ID, @Q_ID, @Yr, @CR_ID, @S_ID, @Section)
COMMIT TRAN T1

-----

EXEC lpmINSERT_CLASS
@Quarter_Name = 'Winter',
@Course_Name = 'CEP113',
@Classroom_Name = 'PATTR650',
@Sched_Name = 'MonWed4',
@Section = '2',
@Yr = '2015'


----
SELECT *
FROM tblQUARTER

SELECT *
FROM tblCOURSE

SELECT *
FROM tblCLASSROOM

SELECT *
FROM tblSCHEDULE

