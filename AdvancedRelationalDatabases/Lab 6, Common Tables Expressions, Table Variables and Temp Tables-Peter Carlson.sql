--1) RANK() + PARTITION

--* Write the SQL to determine the 300 students with the lowest GPA (all students/classes) during years 1975 -1981 partitioned by StudentPermState.
--Common Table Expression
WITH CTE_lowestgpas75to81(StudentID, StudentFName, StudentLname,studentpermstate, GPA, Ranked)
AS(
SELECT S.StudentID, StudentFname,StudentLname, studentpermstate, SUM(GRADE*credits)/SUM(CREDITS),
RANK() OVER (PARTITION BY StudentPermState ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))ASC) AS RankGPA 
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
WHERE C.[YEAR] BETWEEN 1975 AND 1981
GROUP BY S.StudentID, StudentFname,StudentLname,studentpermstate
)

SELECT *

FROM CTE_lowestgpas75to81
WHERE Ranked <= 300
ORDER BY studentpermstate, Ranked

--Table Variable
DECLARE @temp1 TABLE 
(PKID INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(50),
LastName VARCHAR(50),
PermState VARCHAR(50),
GPA NUMERIC(8,2),
Permstateranked INT)

INSERT INTO @temp1(FirstName, LastName, PermState, GPA, Permstateranked)
SELECT StudentFname,StudentLname, studentpermstate, SUM(GRADE*credits)/SUM(CREDITS),
RANK() OVER (PARTITION BY StudentPermState ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))ASC) AS RankGPA 
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
WHERE C.[YEAR] BETWEEN 1975 AND 1981
GROUP BY S.StudentID, StudentFname,StudentLname,studentpermstate 

SELECT *
FROM @temp1
WHERE Permstateranked <= 300
ORDER BY Permstate, Permstateranked

-- #Temp Table

SELECT S.StudentID, StudentFname,StudentLname, studentpermstate, SUM(GRADE*credits)/SUM(CREDITS) AS GPA,
RANK() OVER (PARTITION BY StudentPermState ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))ASC) AS RankGPA 
INTO #temp1
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
WHERE C.[YEAR] BETWEEN 1975 AND 1981
GROUP BY S.StudentID, StudentFname,StudentLname,studentpermstate

GO
select * 
from #temp1
WHERE RankGPA <= 300
ORDER BY studentpermstate, RankGPA

DROP TABLE #temp1

--2) DENSE_RANK()

--* Write the SQL to determine the 26th highest GPA during the 1970's for all business classes

--Common Table Expression
WITH CTE_26highestgpa1970sbusiness(StudentID, StudentFName, StudentLname, GPA, DenseRanked)
AS(
SELECT S.StudentID, StudentFname,StudentLname,  (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits)) AS GPA,
DENSE_RANK() OVER ( ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))DESC) AS RankGPA 
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
JOIN tblDEPARTMENT D ON D.DeptID = CR.DeptID
JOIN tblCOLLEGE CO ON CO.CollegeID = D.CollegeID
WHERE C.[YEAR] BETWEEN 1970 AND 1979
AND CO.CollegeName = 'Business (Foster)'
GROUP BY S.StudentID, StudentFname,StudentLname)

SELECT * 
FROM CTE_26highestgpa1970sbusiness
WHERE DenseRanked = 26

--Table Variable
DECLARE @temp2 TABLE 
(PKID INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(50),
LastName VARCHAR(50),
GPA NUMERIC(8,2),
Denseranked INT)

INSERT INTO @temp2
SELECT StudentFname,StudentLname,  (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits)) AS GPA,
DENSE_RANK() OVER ( ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))DESC) AS Denserank 
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
JOIN tblDEPARTMENT D ON D.DeptID = CR.DeptID
JOIN tblCOLLEGE CO ON CO.CollegeID = D.CollegeID
WHERE C.[YEAR] BETWEEN 1970 AND 1979
AND CO.CollegeName = 'Business (Foster)'
GROUP BY S.StudentID, StudentFname,StudentLname 

SELECT *
FROM @temp2
WHERE Denseranked = 26
ORDER BY Denseranked

-- #Temp Table

SELECT S.StudentID, StudentFname,StudentLname, SUM(GRADE*credits)/SUM(CREDITS) AS GPA,
DENSE_RANK() OVER ( ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))DESC) AS Denserank
INTO #temp2
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
JOIN tblDEPARTMENT D ON D.DeptID = CR.DeptID
JOIN tblCOLLEGE CO ON CO.CollegeID = D.CollegeID
WHERE C.[YEAR] BETWEEN 1970 AND 1979
AND CO.CollegeName = 'Business (Foster)'
GROUP BY S.StudentID, StudentFname,StudentLname 


select * 
from #temp2
WHERE Denserank = 26

DROP TABLE #temp2



--3) NTILE

--* Write the SQL to divide ALL students into 100 groups based on GPA for Arts & Sciences classes during 1980's

--Common Table Expression
WITH CTE_26highestgpa1970sbusiness(StudentID, StudentFName, StudentLname, GPA, Ntilerank)
AS(
SELECT S.StudentID, StudentFname,StudentLname,  (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits)) AS GPA,
NTILE(100) OVER ( ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))DESC) AS NtileRankGPA 
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
JOIN tblDEPARTMENT D ON D.DeptID = CR.DeptID
JOIN tblCOLLEGE CO ON CO.CollegeID = D.CollegeID
WHERE C.[Year] LIKE '198%'
AND CO.CollegeName = 'Arts and Sciences'
GROUP BY S.StudentID, StudentFname,StudentLname)

SELECT *

FROM CTE_26highestgpa1970sbusiness


--Table Variable
DECLARE @temp3 TABLE 
(PKID INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(50),
LastName VARCHAR(50),
GPA NUMERIC(8,2),
NTILERANK NUMERIC)

INSERT INTO @temp3
SELECT StudentFname,StudentLname,  (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits)) AS GPA,
NTILE(100) OVER ( ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))DESC) AS NtileRankGPA 
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
JOIN tblDEPARTMENT D ON D.DeptID = CR.DeptID
JOIN tblCOLLEGE CO ON CO.CollegeID = D.CollegeID
WHERE C.[Year] LIKE '198%'
AND CO.CollegeName = 'Arts and Sciences'
GROUP BY S.StudentID, StudentFname,StudentLname 

SELECT *
FROM @temp3
ORDER BY NTILERANK


-- #Temp Table

SELECT S.StudentID, StudentFname,StudentLname, SUM(GRADE*credits)/SUM(CREDITS) AS GPA,
NTILE(100) OVER ( ORDER BY (SUM(CR.Credits * CL.Grade)) / (SUM(CR.Credits))DESC) AS NtileRankGPA 
INTO #temp3
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON CL.StudentID = S.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CR ON CR.CourseID = C.CourseID
JOIN tblDEPARTMENT D ON D.DeptID = CR.DeptID
JOIN tblCOLLEGE CO ON CO.CollegeID = D.CollegeID
WHERE C.[Year] LIKE '198%'
AND CO.CollegeName = 'Arts and Sciences'
GROUP BY S.StudentID, StudentFname,StudentLname 


select * 
from #temp3
ORDER BY NtileRankGpa

DROP TABLE #temp3

