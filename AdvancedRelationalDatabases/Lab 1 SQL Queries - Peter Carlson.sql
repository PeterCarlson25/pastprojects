USE MovieDB
GO
--What is the shortest movie (issues with nulls)
SELECT TOP 1 movieOriginalTitle, movieruntime
FROM tblMovie
WHERE movieRuntime IS NOT NULL
ORDER BY movieRuntime ASC



--What is the movie with the most number of votes?
SELECT TOP 1 movieoriginaltitle, movieVoteCount
FROM tblMovie
ORDER BY movieVoteCount DESC

--Which movie made the most net profit?
SELECT TOP 1 movieoriginaltitle, (movieRevenue-movieBudget) AS NetProfit
FROM tblMovie
ORDER BY NetProfit DESC

--Which movie lost the most money
SELECT TOP 1 movieoriginaltitle, (movieRevenue-movieBudget) AS NetProfit
FROM tblMovie
ORDER BY NetProfit ASC


--How many movies were made in the 80s
SELECT count(movieID) AS totalmoviesinthe80s
FROM tblMovie
WHERE YEAR(movieReleaseDate) BETWEEN 1980 AND 1989


--What is the most popular movie released in the year 1980
SELECT movieoriginaltitle, moviepopularity
FROM tblMovie
WHERE YEAR(movieReleaseDate)=1980
ORDER BY moviePopularity DESC


--How long was the longest movie made before 1900
SELECT TOP 1 movieoriginaltitle, movieRuntime, movieReleaseDate
FROM tblMovie
WHERE YEAR(movieReleaseDate)<1900
ORDER BY movieRuntime DESC


-- Which language has the shortest movie
SELECT top 1 movieoriginaltitle, movieruntime, languagename
FROM tblMovie M 
    JOIN tblLanguage L ON L.languageID = M.languageID
WHERE movieRuntime IS NOT NULL 
ORDER BY movieRuntime ASC


--What was the most expensive movie that ended up getting canceled
SELECT TOP 1 movieoriginaltitle, movieBudget
FROM tblMovie
    JOIN tblStatus ON tblStatus.statusID=tblMovie.statusID
WHERE statusname = 'Canceled'
ORDER BY movieBudget DESC



--How many collections have movies that are in production for the lanuage French(FR)
SELECT count(tblcollection.collectionID) AS totalfrenchcollections
FROM tblcollection 
    JOIN tblmovie M ON M.collectionID = tblcollection.collectionID
    JOIN tblLanguage L ON L.languageID = M.languageID
    JOIN tblStatus S ON S.statusID = M.statusID
WHERE languageName = 'Français'
AND statusName = 'In Production'




