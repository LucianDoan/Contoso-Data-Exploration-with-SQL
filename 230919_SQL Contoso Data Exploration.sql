Use Contoso
Go

/*Total Revenue by Channel*/
WITH cte_SalesByChannel AS (
	SELECT c.ChannelName, SUM(S.SalesAmount) as RevenueByChannel
	From FACTSales as S
		Left Join DIMChannel as C
		ON s.channelKey = c.ChannelKey
	GROUP BY c.ChannelName
	)

SELECT cte_SalesByChannel.ChannelName, cte_SalesByChannel.RevenueByChannel, 100*cte_SalesByChannel.RevenueByChannel /
	(SELECT SUM(FactSales.SalesAmount) as TotalRevenue
	FROM FactSales)
AS "RevenueContributionByChannel"
FROM cte_SalesByChannel
ORDER BY RevenueByChannel desc

/*Revenue by Channel Over Time*/
SELECT c.ChannelName, d.CalendarYear, SUM(S.SalesAmount) as RevenueByChannelOT
	From FACTSales as S
		Left Join DIMChannel as C
		ON s.channelKey = c.ChannelKey
		Left Join DIMDate as D
		ON s.DateKey = d.Date
GROUP BY c.ChannelName, d.CalendarYear
ORDER BY d.CalendarYear asc, RevenueByChannelOT desc

/*Revenue Per Transaction in 2007 by Channel*/
WITH cte_ChannelAnalysis AS (
SELECT c.ChannelName, d.CalendarYear, SUM(S.SalesAmount) as RevenueByChannelOT, COUNT(DISTINCT S.SalesKey) as NbrOfSalesKey
		From FACTSales as S
			Left Join DIMChannel as C
			ON s.channelKey = c.ChannelKey
			Left Join DIMDate as D
			ON s.DateKey = d.Date
	GROUP BY c.ChannelName, d.CalendarYear
)

SELECT cte_ChannelAnalysis.ChannelName, cte_ChannelAnalysis.CalendarYear, cte_ChannelAnalysis.RevenueByChannelOT, cte_ChannelAnalysis.NbrOfSalesKey, cte_ChannelAnalysis.RevenueByChannelOT/cte_ChannelAnalysis.NbrOfSalesKey as "RevenuePerTransaction"
FROM cte_ChannelAnalysis
WHERE CalendarYear = 2007
ORDER BY RevenuePerTransaction desc

/*Revenue by Geography By Quarter, Month, Year*/
SELECT g.ContinentName, d.CalendarYear, d.CalendarQuarter, SUM(s.SalesAmount) as RevenueByGeography, SUM(s.SalesQuantity) as TotalQuantity, COUNT(DISTINCT s.SalesKey) as NbrOfSalesKey
FROM FACTSales as s
Left Join DimDate as d
ON s.DateKey = d.Date
Left Join [DIM Geography] as g
ON s.GeographyKey = g.GeographyKey
GROUP BY g.ContinentName, d.CalendarYear, d.CalendarQuarter
ORDER BY d.CalendarYear, d.CalendarQuarter, g.ContinentName

/*Revenue & #Transactions by Products*/
WITH cte_R08_YoY AS (
SELECT R07.ProductSubcategoryName, R07.RevenueBySubCategory07, R08.RevenueBySubCategory08, Ceiling(100*(R08.RevenueBySubCategory08 - R07.RevenueBySubCategory07)/R07.RevenueBySubCategory07) as "YoY"
FROM (
	SELECT psc.ProductSubcategoryName, d.CalendarYear, SUM(s.SalesAmount) as RevenueBySubCategory07
			FROM FactSales as S
			Left Join DIMDate as D
			ON s.DateKey = d.Date
			Left Join DimProduct as P
			ON s.ProductKey = p.ProductKey
			Left Join DIMProductSubCategory as PSC
			ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
	WHERE d.CalendarYear = 2007
	GROUP BY psc.ProductSubcategoryName, d.CalendarYear
) as R07
INNER JOIN (
SELECT psc.ProductSubcategoryName, d.CalendarYear, SUM(s.SalesAmount) as RevenueBySubCategory08
		FROM FactSales as S
		Left Join DIMDate as D
		ON s.DateKey = d.Date
		Left Join DimProduct as P
		ON s.ProductKey = p.ProductKey
		Left Join DIMProductSubCategory as PSC
		ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
	WHERE d.CalendarYear = 2008
	GROUP BY psc.ProductSubcategoryName, d.CalendarYear
) as R08
ON R07.ProductSubcategoryName = R08.ProductSubcategoryName
)

SELECT cte_R08_YoY.ProductSubcategoryName, cte_R08_YoY.YoY,
CASE
	WHEN cte_R08_YoY.YoY < 0 THEN 'Negative'
	WHEN cte_R08_YoY.YoY = 0 THEN 'TheSame'
	WHEN cte_R08_YoY.YoY > 0 THEN 'Positive'
	ELSE 'uh oh...please check'
END AS GROWTHCLASS
FROM cte_R08_YoY