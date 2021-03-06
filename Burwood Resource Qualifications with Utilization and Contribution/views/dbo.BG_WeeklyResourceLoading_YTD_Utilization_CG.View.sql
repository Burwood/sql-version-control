USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_WeeklyResourceLoading_YTD_Utilization_CG]    Script Date: 10/17/2019 3:05:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW [dbo].[BG_WeeklyResourceLoading_YTD_Utilization_CG] AS
select 
	Resource,
	ResourceId,
	sum(RegularHours) as RegularHours,
	sum(UtilizationHours) as UtilizationHours,
	sum(WeekHours) as AvailableHours,
	--case when sum(UtilizationHours)=0 then 0 else sum(UtilizationHours)/sum(RegularHours) end as Utilization,  ---name has to be Utilization for weekly loading report
	sum(UtilizationHours)/sum(WeekHours) as Utilization
from 
	BG_WeeklyResourceLoading_Utilization_CG
where
	FYear=datepart(year, getdate())
	and datepart(week, PeriodEndDate) < datepart(week, getdate())
group by
	Resource,
	ResourceId





GO
