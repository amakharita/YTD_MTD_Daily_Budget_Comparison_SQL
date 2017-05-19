USE XXX 
GO

DROP TABLE DailyPremiumBudgetComparison

CREATE TABLE #results1 (Product VARCHAR(20), 
                        Month_Number INT, 
                        Year_Number INT, 
                        Daily_Premium DECIMAL, 
                        MTD_Premium DECIMAL, 
                        Current_Month_Budget DECIMAL, 
                        MYD_PCT_TP_Budget DECIMAL, 
                        YTP_Premium DECIMAL, 
                        YTD_Month_Budget DEC , 
                        YTD_PCT_to_Budget DEC)

INSERT INTO #results1

SELECT CASE WHEN A.product = 'Package - Fine Art' 
            THEN 'Package – FA' 
            WHEN A.product = 'Package - Jewelers Block' 
            THEN 'Package – JB'
            ELSE A.product 
       END AS product, 
       A.Month_Number, 
       A.Year_Number, 
       A.Daily_Premium, 
       A.MTD_Premium, 
       B.Current_Month_Budget, 
       CASE WHEN B.Current_Month_Budget = 0 
            THEN 0
             ELSE MTD_Premium / B.Current_Month_Budget
       END AS MTD_PCT_TO_BUDGET, 
       A.YTD_Premium, 
       B.YTD_Month_Budget, 
       CASE WHEN B.YTD_Month_Budget = 0 
            THEN 0
            ELSE YTD_Premium / B.YTD_Month_Budget
       END AS YTD_PCT_TO_BUDGET
FROM vw_rpt_sharepoint_premium_snapshot_part_1 AS A
    INNER JOIN(SELECT Product, 
                      month_number, 
                      year, 
                      Current_Month_Budget, 
                      YTD_Month_Budget
               FROM vw_rpt_sharepoint_premium_snapshot_part_2_w_london
               )AS B
               ON A.Year_Number = B.year
               AND A.Month_Number = B.month_number
               AND A.product = B.Product
ORDER BY B.Product

SELECT CASE WHEN s2.product like '%Jeweller%'
            THEN 'Jewelers Block'
            WHEN s2.product = 'Cash in Transit' 
            THEN 'Specie'
            WHEN s2.product = 'General Specie'
            THEN 'Specie'
            WHEN s2.product = 'Pawnbrokers'
      THEN  'Jewelers Block'
          ELSE s2.product
       END AS 'Product',
       SUM(s2.ggwp) Daily_Premium 
INTO #t2
FROM XXX_syndicate.dbo.syndicate s2
    LEFT JOIN primaryit.dbo.dim_Date dd 
    ON CAST(GETDATE() as DATE) = dd.FullDate

--When Monday compare to previous friday

WHERE writtendate >=  CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                           --When 1st business day of  month reflect last day of the prev month 
                           --(logic pulls last day of previous month)
               THEN CAST(DATEADD(DAY, -(DAY(GETDATE())), GETDATE()) as DATE) 
               WHEN DATEPART(DW,GETDATE()) = 2 THEN CAST(GETDATE() - 3  as DATE)
               ELSE CAST(GETDATE() - 1 as DATE) 
                      END

AND writtendate < CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                       --When 1st business day of the month reflect last day of prev month 
                       --(logic pulls 1st day of current month)
                       THEN CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) as DATE)
             WHEN DATEPART(DW,GETDATE()) = 2  
             THEN CAST(GETDATE() - 2 as DATE)
               ELSE  CAST(GETDATE() as DATE)   
                  END

AND MONTH(d_book) = --When 1st business day of month and January look at December
                    CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                         AND MONTH(GETDATE()) = 1 
                         THEN 12 
                         --When 1st business day of month pull previous month's numbers
                         WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                         AND MONTH(GETDATE()) <> 1 
                         THEN (MONTH(GETDATE()) - 1) 
                         WHEN DATEPART(DW,GETDATE()) = 2 
                         --When monday show previous Friday
                         THEN MONTH(CAST(GETDATE() - 3 as DATE)) 
                         ELSE MONTH(GETDATE())
                     END

AND YEAR(d_book) = --When 1st business day of month AND January look at prev year
                   CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y' AND MONTH(GETDATE()) = 1 
                        THEN (YEAR(GETDATE()) - 1) 
                        --When monday show previous Friday
                        WHEN DATEPART(DW,GETDATE()) = 2 
                        THEN YEAR(CAST(GETDATE() - 3 as DATE)) 
                        ELSE YEAR(GETDATE())
                   END
GROUP BY product

SELECT CASE WHEN s4.product like '%Jeweller%'
            THEN 'Jewelers Block'
            WHEN s4.product = 'Cash in Transit' 
            THEN 'Specie'
            WHEN s4.product = 'General Specie'
            THEN 'Specie'
            WHEN s4.product = 'Pawnbrokers' 
            THEN  'Jewelers Block'
            ELSE s4.product
       END AS 'Product', 
       SUM(ggwp) MTD_Premium

INTO #t4
FROM XXX_syndicate.dbo.syndicate s4
    LEFT JOIN primaryit.dbo.dim_Date dd 
ON CAST(GETDATE() as DATE) = dd.FullDate
WHERE MONTH(d_book) = CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y'  
                           AND MONTH(GETDATE()) = 1 
                           THEN 12 --When 1st business day of month & Jan look at Dec
                           WHEN dd.IsFirstBusinessDayOfMonth = 'Y'  
                           AND MONTH(GETDATE()) <> 1 
                           --When 1st business day of month pull prev month's numbers
                           THEN (MONTH(GETDATE()) - 1) 
                           WHEN DATEPART(DW,GETDATE()) = 2 
                           --When monday show previous Friday
                           THEN MONTH(CAST(GETDATE() - 3 as DATE)) 
                           ELSE MONTH(GETDATE())
                       END

AND YEAR(d_book) = CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y'  
                        AND MONTH(GETDATE()) = 1 
                        --When 1st business day of month AND January look at prev year
                        THEN (YEAR(GETDATE()) - 1) 
                        WHEN DATEPART(DW,GETDATE()) = 2 THEN YEAR(CAST(GETDATE() - 3 as DATE)) --When monday show previous Friday
                        ELSE YEAR(GETDATE())
                    END

GROUP BY product


SELECT CASE WHEN s5.product like '%Jeweller%'
            THEN 'Jewelers Block'
            WHEN s5.product = 'Cash in Transit' 
            THEN 'Specie'
            WHEN s5.product = 'General Specie'
            THEN 'Specie'
            WHEN s5.product = 'Pawnbrokers' 
            THEN  'Jewelers Block'
            ELSE s5.product
       END AS 'Product', SUM(ggwp) YTD_Premium 
INTO #t5
FROM XXX_syndicate.dbo.syndicate s5
    LEFT JOIN primaryit.dbo.dim_Date dd 
    ON CAST(GETDATE() as DATE) = dd.FullDate
    /***changed per Craig via meeting 05/03/2015*****/   
    --WHERE d_book >= DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) 
    --AND d_book < DATEADD( DD,+1, CONVERT( CHAR(8) , CURRENT_TIMESTAMP , 112 ))
WHERE MONTH(d_book) <= CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                            AND MONTH(GETDATE()) = 1 
                            --When 1st business day of month AND Jan look at Dec
                            THEN 12 
                            WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                            AND MONTH(GETDATE()) <> 1 
                            --When 1st business day of month pull prev month's numbers
                            THEN (MONTH(GETDATE()) - 1) 
                            WHEN DATEPART(DW,GETDATE()) = 2 
                            --When monday show previous Friday
                            THEN MONTH(CAST(GETDATE() - 3 as DATE)) 
                            ELSE MONTH(GETDATE())
                        END

AND YEAR(d_book) = CASE WHEN dd.IsFirstBusinessDayOfMonth = 'Y' 
                        AND MONTH(GETDATE()) = 1 
                        --When 1st business day of month AND Jan look at prev year
                        THEN (YEAR(GETDATE()) - 1) 
                        WHEN DATEPART(DW,GETDATE()) = 2 
                        --When monday show previous Friday
                        THEN YEAR(CAST(GETDATE() - 3 as DATE)) 
                        ELSE YEAR(GETDATE())
                   END

GROUP BY product


SELECT #results1.product, 
       isnull(MAX(#t2.Daily_Premium), 0) Daily_Premium, 
       isnull(MAX(#t4.MTD_Premium), 0 ) MTD_Premium,
       isnull(MAX(#t5.YTD_Premium), 0) YTD_Premium
INTO #results2
FROM #results1
    left join #t2 ON #t2.Product = #results1.Product
    left join #t4 ON #t4.product = #results1.Product
    left join #t5 ON #t5.product = #results1.Product
GROUP BY #results1.roduct


SELECT #results1.Product, 
       SUM(#results1.Daily_Premium + #results2.Daily_Premium) Daily_Premium, 
       SUM(#results1.MTD_Premium + #results2.MTD_Premium) MTD_Premium, 
       Current_Month_Budget, 
       SUM(#results1.YTD_Premium + #results2.YTD_Premium) YTD_Premium,
       YTD_Month_Budget 
INTO #final
FROM #results1
    LEFT JOIN #results2 ON #results2.product = #results1.product
GROUP BY #results1.product,  
         Current_Month_Budget,
         YTD_Month_Budget 

 SELECT Product, 
        MAX(Daily_Premium) Daily_Premium, 
        MAX(MTD_Premium) MTD_Premium, 
        SUM(Current_Month_Budget) Current_Month_Budget, 
        MAX(YTD_Premium) YTD_Premium, 
        SUM(YTD_Month_Budget) YTD_Month_Budget
 INTO DailyPremiumBudgetComparison
 FROM #final
 GROUP BY Product
