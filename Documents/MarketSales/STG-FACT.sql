
-- ---------------stage--------------------

CREATE TABLE stg.MarketSales
	(
	ITEMCODE INT,
	ITEMNAME VARCHAR(255),
	DATE VARCHAR(50),
	AMOUNT DECIMAL(10, 3),
	PRICE DECIMAL(10, 3),
	LINENETTOTAL DECIMAL(10, 3),
	LINENET DECIMAL(10, 3),
	BRANCHNR INT,
	BRANCH VARCHAR(100),
	SALESMAN VARCHAR(100),
	CITY VARCHAR(100),
	REGION VARCHAR(100),
	LATITUDE DECIMAL(9, 6),
	LONGITUDE DECIMAL(9, 6),
	CLIENTCODE INT,
	CLIENTNAME VARCHAR(100),
	BRANDCODE VARCHAR(10),
	BRAND VARCHAR(100),
	CATEGORY_NAME1 VARCHAR(100),
	GENDER CHAR(1)
);

-- ---------------Dimension--------------------

CREATE TABLE dbo.DimBranch(
	Branchkey INT IDENTITY (1,1),
	BranchID INT,
	Branch_Name VARCHAR(100),
	City VARCHAR(100),
	Region VARCHAR(100),
	Latitude DECIMAL(9, 6),
	Longitude DECIMAL (9, 6),
	CreateDate DATETIME DEFAULT GETUTCDATE(),
	CreateBy varchar(50) DEFAULT ORIGINAL_LOGIN(),
	ModifiedDate DATETIME DEFAULT GETUTCDATE(),
	ModifiedDateBy varchar(50) DEFAULT ORIGINAL_LOGIN()
	);

CREATE TABLE dbo.DimCustomer(
	Customerkey INT IDENTITY (1,1),
	CustomerID INT,
	Customer_Name VARCHAR(100),
	Gender CHAR(1)
	);

CREATE TABLE dbo.DimBrand(
	Brandkey INT IDENTITY (1,1),
	Brand_Name VARCHAR(100),
	CreateDate DATETIME DEFAULT GETUTCDATE(),
	CreateBy varchar(50) DEFAULT ORIGINAL_LOGIN(),
	ModifiedDate DATETIME DEFAULT GETUTCDATE(),
	ModifiedDateBy varchar(50) DEFAULT ORIGINAL_LOGIN()
	);

CREATE TABLE dbo.DimProduct(
	Productkey INT IDENTITY(1,1),
	ProductCode INT,
	Product_Name VARCHAR(255),
	Category_Name VARCHAR(100),
	CreateDate DATETIME DEFAULT GETUTCDATE(),
	CreateBy varchar(50) DEFAULT ORIGINAL_LOGIN(),
	ModifiedDate DATETIME DEFAULT GETUTCDATE(),
	ModifiedDateBy varchar(50) DEFAULT ORIGINAL_LOGIN()
	);

CREATE TABLE dbo.DimSalesman(
	Salesmankey INT IDENTITY(1,1),
	Salesman_Name VARCHAR(100),
	BranchID INT,
	CreateDate DATETIME DEFAULT GETUTCDATE(),
	CreateBy varchar(50) DEFAULT ORIGINAL_LOGIN(),
	ModifiedDate DATETIME DEFAULT GETUTCDATE(),
	ModifiedDateBy varchar(50) DEFAULT ORIGINAL_LOGIN()
	);

CREATE TABLE dbo.DimDate(
	Datekey INT IDENTITY(1,1),
	Date Date,
	Year INT,
	Month INT,
	Day INT,
	Quarter INT,
	Week INT,
	Day_of_week INT,
	Is_weekend INT
);

DECLARE @startDate DATE = '2017-01-01';
DECLARE @endDate DATE = GETDATE();    -- @endDate=GETDATE() -> curr date 
DECLARE @currentDate DATE = @startDate; -- #set to startdate store curr date being processes

WHILE @currentDate <= @endDate
BEGIN
    INSERT INTO dimDate (DateKey, Date, Year, Month, Day, Quarter, Week, Day_of_week, Is_weekend)
    VALUES (
        CONVERT(INT, FORMAT(@currentDate, 'yyyyMMdd')), --datekey converted to integer
        @currentDate,   -- actualdate 
        YEAR(@currentDate),
        MONTH(@currentDate),
        DAY(@currentDate),
        DATEPART(QUARTER, @currentDate),
        DATEPART(WEEK, @currentDate),
        DATEPART(WEEKDAY, @currentDate), -- dayofweek (1=sunday, 7=saturday)
        CASE WHEN DATEPART(WEEKDAY, @currentDate) IN (1, 7) THEN 1 ELSE 0 END -- 1=weekend, 0=weekday
    );   
    SET @currentDate = DATEADD(DAY, 1, @currentDate); --incrementing (add 1 day to curr date)
END

--SELECT * FROM dbo.dimDate


-- ----------------Fact Table-------------------

CREATE TABLE [dbo.FactMarket](
	[FactMarketKey] [INT] IDENTITY(1,1) NOT NULL,
	[Branchkey] [INT] NOT NULL,
	[Customerkey] [INT] NOT NULL,
	[Brandkey] [INT] NOT NULL,
	[Productkey] [INT] NOT NULL,
	[Salesmankey] [INT] NOT NULL,
	[Product_Amount] [INT] NOT NULL,
	[Price] [INT] NOT NULL,
	[LineNeTotal] [INT] NOT NULL,
	[LineNet] [INT] NOT NULL,
	[CreatedDate] DATETIME NOT NULL DEFAULT GETUTCDATE(),
	[CreatedBy] [nvarchar](4000) NOT NULL DEFAULT ORIGINAL_LOGIN(),
    [ModifiedDate] DATETIME NOT NULL DEFAULT GETUTCDATE(),
	[ModifieddateBy] [nvarchar](4000) NOT NULL DEFAULT ORIGINAL_LOGIN(), 
	CONSTRAINT [PK_FactOrder] PRIMARY KEY CLUSTERED (FactOrderKey ASC) -- clustered optimal here since the data is physically stored in that order. and faster.
);

CREATE NONCLUSTERED INDEX idx_FactOrderKey
ON dbo.FactMarket (FactMarketKey ASC)
WITH (
    PAD_INDEX = OFF,                -- Don't leave space for growth; fill index pages fully.
    STATISTICS_NORECOMPUTE = OFF,   -- Allow automatic recomputation of statistics.
    IGNORE_DUP_KEY = OFF,           -- Do not ignore duplicate keys; raise errors on duplicates.
    ALLOW_ROW_LOCKS = ON,           -- Allow row-level locking for better concurrency.
    ALLOW_PAGE_LOCKS = ON,           -- Allow page-level locking for better performance on large operations.
	FILLFACTOR = 90,
	SORT_IN_TEMPDB = ON
) ON [PRIMARY]; 