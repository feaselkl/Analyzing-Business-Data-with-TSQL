USE [WideWorldImporters]
GO
IF (OBJECT_ID('dbo.Calendar') IS NULL)
BEGIN
	CREATE TABLE dbo.Calendar
	(
		DateKey INT NOT NULL,
		[Date] DATE NOT NULL,
		[Day] TINYINT NOT NULL,
		DayOfWeek TINYINT NOT NULL,
		DayName VARCHAR(10) NOT NULL,
		IsWeekend BIT NOT NULL,
		DayOfWeekInMonth TINYINT NOT NULL,
		CalendarDayOfYear SMALLINT NOT NULL,
		WeekOfMonth TINYINT NOT NULL,
		CalendarWeekOfYear TINYINT NOT NULL,
		CalendarMonth TINYINT NOT NULL,
		MonthName VARCHAR(10) NOT NULL,
		CalendarQuarter TINYINT NOT NULL,
		CalendarQuarterName CHAR(2) NOT NULL,
		CalendarYear INT NOT NULL,
		FirstDayOfMonth DATE NOT NULL,
		LastDayOfMonth DATE NOT NULL,
		FirstDayOfWeek DATE NOT NULL,
		LastDayOfWeek DATE NOT NULL,
		FirstDayOfQuarter DATE NOT NULL,
		LastDayOfQuarter DATE NOT NULL,
		CalendarFirstDayOfYear DATE NOT NULL,
		CalendarLastDayOfYear DATE NOT NULL,
		FirstDayOfNextMonth DATE NOT NULL,
		CalendarFirstDayOfNextYear DATE NOT NULL,
		FiscalDayOfYear SMALLINT NOT NULL,
		FiscalWeekOfYear TINYINT NOT NULL,
		FiscalMonth TINYINT NOT NULL,
		FiscalQuarter TINYINT NOT NULL,
		FiscalQuarterName CHAR(2) NOT NULL,
		FiscalYear INT NOT NULL,
		FiscalFirstDayOfYear DATE NOT NULL,
		FiscalLastDayOfYear DATE NOT NULL,
		FiscalFirstDayOfNextYear DATE NOT NULL,
		HolidayName VARCHAR(60) NULL,
		CONSTRAINT [PK_Calendar] PRIMARY KEY CLUSTERED([Date]),
		CONSTRAINT [UKC_Calendar] UNIQUE(DateKey)
	);
END
GO

IF NOT EXISTS
(
	SELECT *
	FROM dbo.Calendar
)
BEGIN
	DECLARE
		@StartDate DATE = '18000101',
		@NumberOfYears INT = 726;
 
	--Remove ambiguity with regional settings.
	SET DATEFIRST 7;
	SET DATEFORMAT mdy;
	SET LANGUAGE US_ENGLISH;
 
	DECLARE
		@EndDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);
 
	WITH
	L0 AS(SELECT 1 AS c UNION ALL SELECT 1),
	L1 AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
	L2 AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
	L3 AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
	L4 AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
	L5 AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
	Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS n FROM L5)
	INSERT INTO dbo.Calendar
	(
		DateKey,
		[Date],
		[Day],
		[DayOfWeek],
		[DayName],
		IsWeekend,
		DayOfWeekInMonth,
		CalendarDayOfYear,
		WeekOfMonth,
		CalendarWeekOfYear,
		CalendarMonth,
		[MonthName],
		CalendarQuarter,
		CalendarQuarterName,
		CalendarYear,
		FirstDayOfMonth,
		LastDayOfMonth,
		FirstDayOfWeek,
		LastDayOfWeek,
		FirstDayOfQuarter,
		LastDayOfQuarter,
		CalendarFirstDayOfYear,
		CalendarLastDayOfYear,
		FirstDayOfNextMonth,
		CalendarFirstDayOfNextYear,
		FiscalDayOfYear,
		FiscalWeekOfYear,
		FiscalMonth,
		FiscalQuarter,
		FiscalQuarterName,
		FiscalYear,
		FiscalFirstDayOfYear,
		FiscalLastDayOfYear,
		FiscalFirstDayOfNextYear
	)
	SELECT
		CAST(D.DateKey AS INT) AS DateKey,
		D.[DATE] AS [Date],
		CAST(D.[day] AS TINYINT) AS [day],
		CAST(d.[dayofweek] AS TINYINT) AS [DayOfWeek],
		CAST(DATENAME(WEEKDAY, d.[Date]) AS VARCHAR(10)) AS [DayName],
		CAST(CASE WHEN [DayOfWeek] IN (1, 7) THEN 1 ELSE 0 END AS BIT) AS [IsWeekend],
		CAST(ROW_NUMBER() OVER (PARTITION BY d.FirstOfMonth, d.[DayOfWeek] ORDER BY d.[Date]) AS TINYINT) AS DayOfWeekInMonth,
		CAST(DATEPART(DAYOFYEAR, d.[Date]) AS SMALLINT) AS CalendarDayOfYear,
		CAST(DENSE_RANK() OVER (PARTITION BY d.[year], d.[month] ORDER BY d.[week]) AS TINYINT) AS WeekOfMonth,
		CAST(d.[week] AS TINYINT) AS CalendarWeekOfYear,
		CAST(d.[month] AS TINYINT) AS CalendarMonth,
		CAST(d.[monthname] AS VARCHAR(10)) AS [MonthName],
		CAST(d.[quarter] AS TINYINT) AS CalendarQuarter,
		CONCAT('Q', d.[quarter]) AS CalendarQuarterName,
		d.[year] AS CalendarYear,
		d.FirstOfMonth AS FirstDayOfMonth,
		MAX(d.[Date]) OVER (PARTITION BY d.[year], d.[month]) AS LastDayOfMonth,
		MIN(d.[Date]) OVER (PARTITION BY d.[year], d.[week]) AS FirstDayOfWeek,
		MAX(d.[Date]) OVER (PARTITION BY d.[year], d.[week]) AS LastDayOfWeek,
		MIN(d.[Date]) OVER (PARTITION BY d.[year], d.[quarter]) AS FirstDayOfQuarter,
		MAX(d.[Date]) OVER (PARTITION BY d.[year], d.[quarter]) AS LastDayOfQuarter,
		FirstOfYear AS CalendarFirstDayOfYear,
		MAX(d.[Date]) OVER (PARTITION BY d.[year]) AS CalendarLastDayOfYear,
		DATEADD(MONTH, 1, d.FirstOfMonth) AS FirstDayOfNextMonth,
		DATEADD(YEAR, 1, d.FirstOfYear) AS CalendarFirstDayOfNextYear,
		DATEDIFF(DAY, fy.FYStart, d.[Date]) + 1 AS FiscalDayOfYear,
		DATEDIFF(WEEK, fy.FYStart, d.[Date]) + 1 AS FiscalWeekOfYear,
		CASE
			WHEN d.[month] >= 7 THEN d.[month] - 6
			ELSE d.[month] + 6
		END AS FiscalMonth,
		CASE d.[quarter]
			WHEN 1 THEN 3
			WHEN 2 THEN 4
			WHEN 3 THEN 1
			WHEN 4 THEN 2
		END AS FiscalQuarter,
		CONCAT('Q', CASE d.[quarter]
			WHEN 1 THEN 3
			WHEN 2 THEN 4
			WHEN 3 THEN 1
			WHEN 4 THEN 2
		END) AS FiscalQuarterName,
		YEAR(fy.FYStart) AS FiscalYear,
		fy.FYStart AS FiscalFirstDayOfYear,
		MAX(d.[Date]) OVER (PARTITION BY fy.FYStart) AS FiscalLastDayOfYear,
		DATEADD(YEAR, 1, fy.FYStart) AS FiscalFirstDayOfNextYear
	FROM Nums n
		CROSS APPLY
		(
			SELECT
				DATEADD(DAY, n - 1, @StartDate) AS [DATE]
		) d0
		CROSS APPLY
		(
			SELECT
				d0.[date],
				DATEPART(DAY, d0.[date]) AS [day],
				DATEPART(MONTH, d0.[date]) AS [month],
				CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, d0.[date]), 0)) AS FirstOfMonth,
				DATENAME(MONTH, d0.[date]) AS [MonthName],
				DATEPART(WEEK, d0.[date]) AS [week],
				DATEPART(WEEKDAY, d0.[date]) AS [DayOfWeek],
				DATEPART(QUARTER, d0.[date]) AS [quarter],
				DATEPART(YEAR, d0.[date]) AS [year],
				CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, d0.[date]), 0)) AS FirstOfYear,
				CONVERT(CHAR(8), d0.[date], 112) AS DateKey
		) d
		CROSS APPLY
		(
			SELECT
				--Fiscal year starts July 1.
				FYStart = DATEADD(MONTH, -6, DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(MONTH, 6, d.[date])), 0))
		) fy
		CROSS APPLY
		(
			SELECT
				FYyear = YEAR(fy.FYStart)
		) fyint
	WHERE
		n.n <= DATEDIFF(DAY, @StartDate, @EndDate)
	ORDER BY
		[date] OPTION (MAXDOP 1);
END
GO

/* Easter comes courtesy of Daniel Hutmacher
   https://sqlsunday.com/2014/07/06/calculating-easter/ */
CREATE TABLE #EasterBuilder
(
	Year INT,
	a TINYINT,
	b TINYINT,
	c TINYINT,
	d TINYINT,
	e TINYINT,
	f TINYINT,
	g TINYINT,
	h TINYINT,
	i TINYINT,
	k TINYINT,
	l TINYINT,
	M TINYINT,
	EasterDay DATE
);
 
INSERT INTO #EasterBuilder 
(
	Year,
	a,
	b,
	c
)
SELECT DISTINCT
	c.CalendarYear,
	c.CalendarYear % 19,
	FLOOR(1.0 * c.CalendarYear / 100),
	c.CalendarYear % 100
FROM dbo.Calendar c;
 
UPDATE #EasterBuilder
SET
	d = FLOOR(1.0 * b / 4),
	e = b % 4,
	f = FLOOR((8.0 + b) / 25);
 
UPDATE #EasterBuilder
SET
	g = FLOOR((1.0 + b - f) / 3);
 
UPDATE #EasterBuilder
SET
	h = (19 * a + b - d - g + 15) % 30,
	i = FLOOR(1.0 * c / 4),
	k = year % 4;
 
UPDATE #EasterBuilder
SET
	l = (32.0 + 2 * e + 2 * i - h - k) % 7;
 
UPDATE #EasterBuilder
SET
	m = FLOOR((1.0 * a + 11 * h + 22 * l) / 451);
 
UPDATE #EasterBuilder
SET
	EasterDay =
	DATEADD(dd, (h + l - 7 * m + 114) % 31,
	DATEADD(mm, FLOOR((1.0 * h + l - 7 * m + 114) / 31) - 1,
	DATEADD(yy, year - 2000, { D '2000-01-01' })
	)
	);
 
UPDATE c
SET
	HolidayName = 'Easter'
FROM dbo.Calendar c
	INNER JOIN #EasterBuilder eb
		ON c.Date = eb.EasterDay;

/* For other holidays, Karl Schmitt has a way.
   https://www.tek-tips.com/faqs.cfm?fid=5075 */
IF (OBJECT_ID('dbo.HolidayDef') IS NULL)
BEGIN
	CREATE TABLE [dbo].[HolidayDef] (
		[HolidayKey] [int] NOT NULL ,
		[OffsetKey] [int] NOT NULL ,
		[Type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
		[FixedMonth] [int] NOT NULL ,
		[FixedDay] [int] NOT NULL ,
		[DayOfWeek] [int] NOT NULL ,
		[WeekOfMonth] [int] NOT NULL ,
		[Adjustment] [int] NOT NULL ,
		[HolidayName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ) ON [PRIMARY]
END
GO

CREATE OR ALTER function dbo.Chanukah (@Yr as int)
returns datetime
AS
Begin
return case datediff(dd,dbo.Passover(@Yr),dbo.Passover(@Yr+1))
          when 355 then dateadd(dd,246,dbo.Passover(@Yr))
          when 385 then dateadd(dd,246,dbo.Passover(@Yr))
          else  dateadd(dd,245,dbo.Passover(@Yr)) end
END
GO

CREATE OR ALTER FUNCTION dbo.Easter (@Yr as int)
RETURNS datetime
AS  
BEGIN
   Declare @Cent int, @I int, @J int, @K int, @Metonic int, @EMo int, @EDay int
   Set @Cent=@Yr/100
   Set @Metonic=@Yr % 19
   Set @K=(@Cent-17)/25
   Set @I=(@Cent-@Cent/4-(@Cent-@K)/3+19*@Metonic+15) % 30
   Set @I=@I-(@I/28)*(1-(@I/28)*(29/(@I+1))*((21-@Metonic)/11))
   Set @J=(@Yr+@Yr/4+@I+2-@Cent+@Cent/4) % 7
   Set @EMo=3+(@I-@J+40)/44
   Set @EDay=@I-@J+28-31*(@EMo/4)
   Return cast(str(@EMo)+'/'+str(@EDay)+'/'+str(@Yr) as datetime)
/*This algorithm is from the work done by JM Oudin in 1940 and is accurate from year 1754 to 3400.*/
END
GO

CREATE OR ALTER FUNCTION dbo.GetHolidayDates (@HolidayKey AS int, @StartDate AS datetime, @EndDate AS datetime)
RETURNS @HolidayTable TABLE (HolidayKey int, HolidayDate datetime)
AS BEGIN
   DECLARE @Yr int, @EndYr int, @OffsetKey int
   SET @OffsetKey=isnull((SELECT OffsetKey FROM HolidayDef WHERE HolidayKey=@HolidayKey),0)
   SET @Yr=year(@StartDate) SET @EndYr=year(@EndDate)
   IF @Yr>@EndYr RETURN
   WHILE @Yr<=@EndYr
      BEGIN
         IF @HolidayKey=0 OR @HolidayKey=15 OR @OffsetKey=15
            INSERT INTO @HolidayTable
               SELECT 15,dbo.Passover(@Yr)
         IF @HolidayKey=0 OR @HolidayKey=18 OR @OffsetKey=18
            INSERT INTO @HolidayTable
               SELECT 18,dbo.Easter(@Yr)
         IF @HolidayKey=0 OR @HolidayKey=19 OR @OffsetKey=19
            INSERT INTO @HolidayTable
               SELECT 19,dbo.OEaster(@Yr)
         IF @HolidayKey=0 OR @HolidayKey=45 OR @OffsetKey=45
            INSERT INTO @HolidayTable
               SELECT 45,dbo.Chanukah(@Yr)
         IF @HolidayKey=0 OR @HolidayKey=54 OR @OffsetKey=54
            INSERT INTO @HolidayTable
               SELECT 54,dbo.TuBishvat(@Yr)
         IF @HolidayKey=0 OR @HolidayKey=55 OR @OffsetKey=55
            INSERT INTO @HolidayTable
               SELECT 55,dbo.YomHaAtzmaut(@Yr)
         IF @HolidayKey=0 OR @HolidayKey=56 OR @OffsetKey=56
            INSERT INTO @HolidayTable
               SELECT 56,dbo.TishaBAv(@Yr)
         INSERT INTO @HolidayTable
            SELECT HolidayKey, cast(str(FixedMonth)+'/'+str(FixedDay)+'/'+str(@Yr) AS datetime)
               FROM HolidayDef WHERE type='F' AND (@HolidayKey=0 OR @HolidayKey=HolidayKey)
         INSERT INTO @HolidayTable
            SELECT HolidayKey, cast(str(FixedMonth)+'/'+str((7+DayOfWeek-datepart(dw,cast(str(FixedMonth)+'/01/'+str(@Yr) AS datetime)))%7+1)+'/'+str(@Yr) AS datetime)+(WeekOfMonth-1)*7+Adjustment
               FROM HolidayDef WHERE type='M' AND (@HolidayKey=0 OR @HolidayKey=HolidayKey)
         INSERT INTO @HolidayTable
            SELECT H1.HolidayKey, dateadd(dd,H1.Adjustment,HolidayDate)
               FROM HolidayDef H1 INNER JOIN HolidayDef H2 ON (H1.OffsetKey=H2.HolidayKey)
                  INNER JOIN @HolidayTable HT ON (HT.HolidayKey=H1.OffsetKey AND year(HolidayDate)=@Yr)
                WHERE H1.Type='O' AND (@HolidayKey=0 OR @HolidayKey=H1.HolidayKey)
         SET @Yr=@Yr+1
      END
      DELETE @HolidayTable WHERE HolidayDate<@StartDate OR HolidayDate>@EndDate OR HolidayKey<>@HolidayKey AND @OffsetKey<>0
      RETURN
   END
GO

CREATE OR ALTER FUNCTION dbo.OEaster (@Yr as int)
RETURNS datetime
AS  
BEGIN
   Declare @I int, @J int, @Metonic int, @EMo int, @EDay int, @LeapAdj int
   Set @LeapAdj=@Yr/100-@Yr/400-2
   Set @Metonic=@Yr % 19
   Set @I=(19*@Metonic+15) % 30
   Set @J=(@Yr+@Yr/4+@I) % 7
   Set @EMo=3+(@I-@J+40)/44
   Set @EDay=@I-@J+28-31*(@EMo/4)
   Return DateAdd(dd,@LeapAdj,cast(str(@EMo)+'/'+str(@EDay)+'/'+str(@Yr) as datetime))
/*This algorithm is based upon work done by JM Oudin in 1940.*/
End
GO

CREATE OR ALTER function dbo.Passover(@Yr int)
returns datetime
AS
BEGIN
   Declare @HYear int, @Matonic int, @LeapException int, @Leap int, @DOW int, @Century int
   Declare @fDay float(20), @fFracDay float(20)
   Declare @Mo int, @Day int
   Set @HYear=@Yr+3760
   Set @Matonic=(12*@HYear+17) % 19
   Set @Leap=@HYear % 4
   Set @fDay=32+4343/98496.+@Matonic+@Matonic*(272953/492480.)+@Leap/4.
   Set @fDay=@fDay-@HYear*(313/98496.)
   Set @fFracDay=@fDay-FLOOR(@fDay)
   Set @DOW=cast (3*@HYear+5*@Leap+FLOOR(@fDay)+5 as int) % 7
   IF @DOW=2 or @DOW=4 or @DOW=6
      set @fDay=@fDay+1
   IF @DOW=1 and @Matonic>6 and @fFracDay>=1367/2160.
      set @fDay=@fDay+2
   IF @DOW=0 and @Matonic>11 and @fFracDay>=23269/25920.
      set @fDay=@fDay+1
   Set @Century=FLOOR(@Yr/100.)
   Set @LeapException=FLOOR((3*@Century-5)/4.)
   IF @Yr>1582
      set @fDay=@fDay+@LeapException
   Set @Day=FLOOR(@fDay)
   Set @Mo=3
   IF @Day>153
      Begin
         set @Mo=8
         set @Day=@Day-153
      End
   IF @Day>122
      Begin
         set @Mo=7
         set @Day=@Day-122
      End
   IF @Day>92
      Begin
         set @Mo=6
         set @Day=@Day-92
      End
   IF @Day>61
      Begin
         set @Mo=5
         set @Day=@Day-61
      End
   IF @Day>31
      Begin
         set @Mo=4
         set @Day=@Day-31
      End
   return cast(str(@Mo)+'/'+str(@Day)+'/'+str(@Yr) as datetime)
/* Based on mathematical algorithms first devised by the German mathematician Carl Friedrich Gauss (1777-1855).  I have used the date of Passover to determine most of the other Jewish holidays.*/
END
GO

CREATE OR ALTER FUNCTION dbo.TishaBAv (@Yr as int)
RETURNS datetime
AS  
BEGIN
   return  case datepart(weekday,dbo.Passover(@Yr))
                 when 7 then dateadd(dd,113,dbo.Passover(@Yr))
                 else dateadd(dd,112,dbo.Passover(@Yr)) end
END
GO

CREATE OR ALTER function dbo.TuBishvat (@Yr as int)
returns datetime
AS
Begin
return case when datediff(dd,dbo.Passover(@Yr-1),dbo.Passover(@Yr))>355
          then dateadd(dd,-89,dbo.Passover(@Yr))
          else  dateadd(dd,-59,dbo.Passover(@Yr)) end
END
GO

CREATE OR ALTER FUNCTION dbo.YomHaAtzmaut (@Yr as int)
RETURNS datetime
AS
--The "rule" for this date isn't always observered! In 2004 the holiday was observed on 4/27 instead of 4/26!  
BEGIN
   Declare @Date as datetime
   IF @Yr=2004
      set @Date=cast('2004-04-27' as datetime)
   else
      set @Date=  case datepart(weekday,dbo.Passover(@Yr))
                 when 1 then dateadd(dd,18,dbo.Passover(@Yr))
                 when 7 then dateadd(dd,19,dbo.Passover(@Yr))
                 else dateadd(dd,20,dbo.Passover(@Yr)) end
   return @Date
END
GO

IF NOT EXISTS
(
	SELECT 1
	FROM dbo.HolidayDef
)
BEGIN
	INSERT INTO dbo.HolidayDef 
	(
		HolidayKey,
		OffsetKey,
		Type,
		FixedMonth,
		FixedDay,
		DayOfWeek,
		WeekOfMonth,
		Adjustment,
		HolidayName
	)
	VALUES
	( 1, 0,'F', 1, 1,0,0,  0,'New Year''s Day'),
	( 2, 0,'M', 1, 0,2,3,  0,'Martin Luther King Jr''s BD (Observed)'),
	( 3, 0,'F', 2, 2,0,0,  0,'Ground Hog Day'),
	( 4, 0,'F', 2,12,0,0,  0,'Lincoln''s Birthday'),
	( 5, 0,'F', 2,14,0,0,  0,'Valentine''s Day'),
	( 6, 0,'M', 2, 0,2,3,  0,'President''s Day'),
	( 7,18,'O', 0, 0,0,0,-47,'Paczki Day (Mardi Gras)'),
	( 8,18,'O', 0, 0,0,0,-46,'Ash Wednesday'),
	( 9, 0,'F', 2,22,0,0,  0,'Washington''s Birthday'),
	(10,15,'O', 0, 0,0,0,-30,'Purim'),
	(11, 0,'F', 3,17,0,0,  0,'St. Patrick''s Day'),
	(12, 0,'F', 3,19,0,0,  0,'St. Joseph''s Day'),
	(13,18,'O', 0, 0,0,0,-14,'Passion Sunday'),
	(14,18,'O', 0, 0,0,0, -7,'Palm Sunday'),
	(15, 0,'S', 0, 0,0,0,  0,'Passover'),
	(16,18,'O', 0, 0,0,0, -2,'Good Friday'),
	(17, 0,'M', 4, 0,1,1,  0,'Daylight Savings Begins'),
	(18, 0,'S', 0, 0,0,0,  0,'Easter Sunday'),
	(19, 0,'S', 0, 0,0,0,  0,'Orthodox Easter'),
	(20, 0,'M', 5, 0,7,1, -10,'Administrative Professionals Day'),
	(21, 0,'F', 4,22,0,0,  0,'Earth Day'),
	(22, 0,'M', 5, 0,1,2,  0,'Mother''s Day'),
	(23, 0,'M', 5, 0,7,3,  0,'Armed Forces Day'),
	(24, 0,'F', 5,31,0,0,  0,'Memorial Day'),
	(25, 0,'F', 6,14,0,0,  0,'Flag Day'),
	(26, 0,'M', 6, 0,1,3,  0,'Father''s Day'),
	(27,18,'O', 0, 0,0,0, 49,'Pentecost'),
	(28, 0,'F', 7, 4,0,0,  0,'Independence Day'),
	(29, 0,'M', 9, 0,2,1,  0,'Labor Day'),
	(30,15,'O', 0, 0,0,0,163,'Rosh Hashanah'),
	(31, 0,'M', 9, 0,1,2,  0,'Grandparents Day'),
	(32,15,'O', 0, 0,0,0,172,'Yom Kippur'),
	(33,18,'O', 0, 0,0,0, 39,'Ascension Day'),
	(34, 0,'F',10, 9,0,0,  0,'Leif Erikson Day'),
	(35, 0,'M',10, 0,1,2,  0,'National Children''s Day'),
	(36, 0,'M',10, 0,3,2,  0,'Columbus Day (Traditional)'),
	(37, 0,'F',10,16,0,0,  0,'Boss''s Day'),
	(38, 0,'M',10, 0,7,3,  0,'Sweetest Day'),
	(39, 0,'M',11, 0,1,1, -7,'Daylight Savings Ends'),
	(40, 0,'F',10,31,0,0,  0,'Halloween'),
	(41, 0,'F',11, 1,0,0,  0,'All Saint''s Day'),
	(42, 0,'M',11, 0,2,1,  1,'Election Day'),
	(43, 0,'F',11,11,0,0,  0,'Veterans Day'),
	(44, 0,'M',11, 0,5,4,  0,'Thanksgiving Day'),
	(45, 0,'S', 0, 0,0,0,  0,'Chanukah'),
	(46,18,'O', 0, 0,0,0, 56,'Trinity Sunday'),
	(47, 0,'F',12,25,0,0,  0,'Christmas Day'),
	(48,15,'O', 0, 0,0,0,177,'Sukkot'),
	(49,15,'O', 0, 0,0,0,184,'Shemini Atzeret'),
	(50,15,'O', 0, 0,0,0,185,'Simhat Torah (outside Israel)'),
	(51, 0,'F', 3,19,0,0,  0,'St. Josephs Day'),
	(52,15,'O', 0, 0,0,0, 33,'Lag B''Omar'),
	(53,15,'O', 0, 0,0,0, 50,'Shavuot'),
	(54, 0,'S', 0, 0,0,0,  0,'Tu Bishvat'),
	(55, 0,'S', 0, 0,0,0,  0,'Yom HaAtzma''ut'),
	(56, 0,'S', 0, 0,0,0,  0,'Tisha B''Av');

	CREATE TABLE #HolidayDays
	(
		HolidayKey INT,
		HolidayDate DATE
	);
	
	INSERT INTO #HolidayDays 
	(
		HolidayKey,
		HolidayDate
	)
	SELECT
		HolidayKey,
		HolidayDate
	FROM dbo.GetHolidayDates(0, '1800-01-01', '2525-12-31');
	
	UPDATE c
	SET
		HolidayName = h.HolidayName
	FROM dbo.Calendar c
		INNER JOIN #HolidayDays hd
			ON c.Date = hd.HolidayDate
		INNER JOIN dbo.HolidayDef h
			ON hd.HolidayKey = h.HolidayKey;
END
