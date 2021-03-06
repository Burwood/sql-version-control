USE [Changepoint]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_GetUtilizationForecastTotals_CG]    Script Date: 10/17/2019 4:33:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[BG_GetUtilizationForecastTotals_CG](@FiscalYear nvarchar(281), @StartDate as date)
returns table
as
return

--select * from BG_GetUtilizationForecastTotals_CG('2019 [2018-12-29 - 2019-12-27]', '20190330')


select
	Resource,
	Title,
	Region,
	Practice,
	Workgroup,
	UtilizationGoal,
	sum(UtilizationHours) as UtilizationHours,
	sum(TotalHours) as TotalHours,
	sum(UtilizationWeekly) as WeeklyUtilization,
	sum(HoursPerWeek) as HoursPerWeek,
	sum(ForecastHours) as ForecastHours,
	sum(UtilizationHours)-sum(ForecastHours) as VarianceHours,
	--case when PeriodStartDate=@StartDate then UtilizationHours-ForecastHours else 0 end as VarianceHours,
	sum(YTDUtilizationHours) as YTDUtilizationHours,
	sum(YTDHoursPerWeek) as YTDHoursPerWeek,
	sum(YTDForecastHours) as YTDForecastHours,
	case when sum(YTDHoursPerWeek)=0
		 then 0
		 else sum(YTDUtilizationHours)/sum(YTDHoursPerWeek) 
	end as YTDUtilization,
	sum(YTDUtilizationHours)-sum(YTDForecastHours) as YTDVarianceHours
from	
	dbo.BG_GetUtilizationForecast_CG(@FiscalYear, @StartDate)
where
FiscalYear = @FiscalYear
	and PeriodStartDate<=@StartDate

--(case when month(getdate())=1 then ((select 
--	distinct
--	fy.Name+' ['+LEFT(CONVERT(VARCHAR, fy.StartDate, 120), 10)+' - '+LEFT(CONVERT(VARCHAR, fy.EndDate, 120), 10)+']' as FiscalYear
--from
--	FiscalYear fy with (nolock)
--		join
--	FiscalPeriod fp with (nolock) on fy.FiscalYearId=fp.FiscalYearId and fp.Deleted=0
--		join
--	BillingOffice b with (nolock) on fy.BillingOfficeId=b.BillingOfficeId
--where
--	fy.BillingOfficeId='A688AC3B-03DA-44C3-8A05-CBE069E1A6F2'
--	and (fy.name=convert(varchar(4), year(getdate())-1)))) else @FiscalYear end)
	--FiscalYear=@FiscalYear
	--and PeriodStartDate<=@StartDate
group by
	Resource,
	Title,
	Region,
	Practice,
	Workgroup,
	UtilizationGoal

GO
