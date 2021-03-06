USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[BG_spWriteUpWriteOff_CG]    Script Date: 10/17/2019 4:47:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[BG_spWriteUpWriteOff_CG] AS

BEGIN


truncate table BG_Promo_Expense_Table_CG
	insert into BG_Promo_Expense_Table_CG select * from BG_Promo_Expense_CG




--select * from [BG_EngagementBillingRates_Tablesave_CG] 
--select *  from [BG_EngagementBillingRates_Table_CG]

	truncate table BG_Forecast_Actual_QTD_Table_CG
		insert into BG_Forecast_Actual_QTD_Table_CG select * from BG_Forecast_Actual_QTD_CG

truncate table [BG_Forecast_Actual_QTD_Detail_Table_CG]
	insert into [BG_Forecast_Actual_QTD_Detail_Table_CG] select * from [BG_Forecast_Actual_QTD_Detail_CG]
		
--truncate table BG_WriteUpWriteOff_Adjustments_Table_CG 
--insert into BG_WriteUpWriteOff_Adjustments_Table_CG select * from BG_Time_and_WriteOff_Category_CG
truncate table BG_RealizationTable_CG
insert into BG_RealizationTable_CG select * from BG_Realization_CG

truncate table BG_RealizationTable2017_CG
insert into BG_RealizationTable2017_CG select * from [BG_Realization_2017_CG]

truncate table [BG_Realization_2017_Detail_Table_CG]
insert into [BG_Realization_2017_Detail_Table_CG] select * from [BG_Realization_2017_Detail_CG]

--drop table [BG_Realization_2017_Detail_Table_CG]
-- select * into [BG_Realization_2017_Detail_Table_CG] from [BG_Realization_2017_Detail_CG]


truncate table BG_RealizationNoContractorTable_CG
insert into BG_RealizationNoContractorTable_CG select * from BG_RealizationNoContactor_CG

truncate table [BG_Realization_WithandWithoutContractor_Table_CG]
insert into [BG_Realization_WithandWithoutContractor_Table_CG] select *  from [BG_Realization_WithandWithoutContractor_CG]




	
truncate table BG_Services_RevRec_Product_Table_CG
	insert into BG_Services_RevRec_Product_Table_CG select i.Industry, s.* from BG_Services_RevRec_Product_AE_CG s left outer join [chil-crm-04].[BurwoodGroupInc_MSCRM].dbo.BG_AccountIndustry_CG i with (nolock) on s.Customer=i.Account

truncate table BG_Client_Services_Product_Table_CG
	insert into BG_Client_Services_Product_Table_CG select * from BG_Client_Services_Product_CG

truncate table BG_Services_RevRec_Product_AE_Deal_Table_CG
	insert into BG_Services_RevRec_Product_AE_Deal_Table_CG select * from BG_Services_RevRec_Product_AE_Deal_CG

truncate table BG_ClientServicesProductAEs_Table_CG
	insert into BG_ClientServicesProductAEs_Table_CG select distinct AccountExecutive from BG_ClientServicesProductSummary_CG

truncate table BG_ClientServicesProductCustomers_Table_CG
	insert into BG_ClientServicesProductCustomers_Table_CG select distinct Customer from BG_ClientServicesProductSummary_CG

truncate table BG_ClientServicesProductRegions_Table_CG
	insert into BG_ClientServicesProductRegions_Table_CG SELECT distinct Region FROM BG_ClientServicesProductSummary_CG


truncate table [BG_FiscalPeriod_Table_CG]
insert into [BG_FiscalPeriod_Table_CG]
SELECT [FiscalYear]
      ,[FiscalPeriod]
      ,[PeriodStartDate]
      ,[PeriodEndDate]
  FROM [Changepoint].[dbo].[BG_FiscalPeriod_CG]


--truncate table BG_UtilizationForecast_Table_CG
--	insert into BG_UtilizationForecast_Table_CG select * from BG_UtilizationForecast_CG

	--select * from BG_New_UtilizationForecast_Table_CG where Workgroup in ('Cloud & Automation (Blatin)','Data Center (Wons)')

truncate table BG_New_UtilizationForecast_Table_CG
	insert into BG_New_UtilizationForecast_Table_CG 
		select *,
	(case 
		when AnnualTargetHours=1040 then (((DaysInPeriod)-(NonWorkingDays))*8)*.50
		when AnnualTargetHours=416 then (((DaysInPeriod)-(NonWorkingDays))*8)*.20
		when AnnualTargetHours=312 then (((DaysInPeriod)-(NonWorkingDays))*8)*.15
		when AnnualTargetHours=208 then (((DaysInPeriod)-(NonWorkingDays))*8)*.10
		 else (DaysInPeriod-NonWorkingDays)*8 end) as HoursPerWeek1, 
	(((DaysInPeriod-NonWorkingDays)*8)*i.UtilizationPercent) as HoursPerWeek, 
	case when (case 
		when AnnualTargetHours=1040 then (((DaysInPeriod)-(NonWorkingDays))*8)*.50
		when AnnualTargetHours=416 then (((DaysInPeriod)-(NonWorkingDays))*8)*.20
		when AnnualTargetHours=312 then (((DaysInPeriod)-(NonWorkingDays))*8)*.15
		when AnnualTargetHours=208 then (((DaysInPeriod)-(NonWorkingDays))*8)*.10
		else (DaysInPeriod-NonWorkingDays)*8 end)=0 then 0 else UtilizationHours
		/
		(case 
			when AnnualTargetHours=1040 then (((DaysInPeriod)-(NonWorkingDays))*8)*.50
		when AnnualTargetHours=416 then (((DaysInPeriod)-(NonWorkingDays))*8)*.20
		when AnnualTargetHours=312 then (((DaysInPeriod)-(NonWorkingDays))*8)*.15
		when AnnualTargetHours=208 then (((DaysInPeriod)-(NonWorkingDays))*8)*.10
			else (DaysInPeriod-NonWorkingDays)*8 end) end as UtilizationWeekly1,  
		case when(((DaysInPeriod-NonWorkingDays)*8)*i.UtilizationPercent)=0 
			 then 0 
			 else UtilizationHours 
				/
			 (((DaysInPeriod-NonWorkingDays)*8)*i.UtilizationPercent) 
		end as UtilizationWeekly  ,
		i.UtilizationPercent as UtilizationGoal,
		convert(numeric(38,2), 2080/52) as AvailableHoursPerWeek
		--into BG_New_UtilizationForecast_Table_CG
from 
	BG_NewUtilizationForecast_View_CG 
		left outer join
	(select Resource as ResourceGoalResource, MAX(AvailableHours) as AvailableHours, MAX(Utilization) as UtilizationPercent from BG_2019_PracticeWorkGroupDashboard_IndividualGoals_CG with (nolock) group by Resource) i on BG_NewUtilizationForecast_View_CG.Resource=i.ResourceGoalResource
	--select *,
	--(case 
	--	when AnnualTargetHours=1040 then (((DaysInPeriod)-(NonWorkingDays))*8)*.50
	--	when AnnualTargetHours=416 then (((DaysInPeriod)-(NonWorkingDays))*8)*.20
	--	when AnnualTargetHours=312 then (((DaysInPeriod)-(NonWorkingDays))*8)*.15
	--	when AnnualTargetHours=208 then (((DaysInPeriod)-(NonWorkingDays))*8)*.10
	--	 else (DaysInPeriod-NonWorkingDays)*8 end) as HoursPerWeek, 
	--case when (case 
	--	when AnnualTargetHours=1040 then (((DaysInPeriod)-(NonWorkingDays))*8)*.50
	--	when AnnualTargetHours=416 then (((DaysInPeriod)-(NonWorkingDays))*8)*.20
	--	when AnnualTargetHours=312 then (((DaysInPeriod)-(NonWorkingDays))*8)*.15
	--	when AnnualTargetHours=208 then (((DaysInPeriod)-(NonWorkingDays))*8)*.10
	--	else (DaysInPeriod-NonWorkingDays)*8 end)=0 then 0 else UtilizationHours
	--	/
	--	(case 
	--		when AnnualTargetHours=1040 then (((DaysInPeriod)-(NonWorkingDays))*8)*.50
	--	when AnnualTargetHours=416 then (((DaysInPeriod)-(NonWorkingDays))*8)*.20
	--	when AnnualTargetHours=312 then (((DaysInPeriod)-(NonWorkingDays))*8)*.15
	--	when AnnualTargetHours=208 then (((DaysInPeriod)-(NonWorkingDays))*8)*.10
	--		else (DaysInPeriod-NonWorkingDays)*8 end) end as UtilizationWeekly  
	--from dbo.BG_NewUtilizationForecast_View_CG

--update BG_New_UtilizationForecast_Table_CG set Practice='150-Cloud & Auto-End User Comp/Cloud', Workgroup='Cloud & Automation (Blatin)' where Resource='Blatin, Vladimir' and year(PeriodEndDate)>=2018
--update BG_New_UtilizationForecast_Table_CG set Practice='120-Cloud & Auto-Data Ctr/Networking', Workgroup='Data Center (Wons)' where Resource='Wons, Dan' and year(PeriodEndDate)>=2018

--insert into BG_New_UtilizationForecast_Table_CG
--SELECT [Region]
--      ,'120-Cloud & Auto-Data Ctr/Networking' as [Practice]
--      ,'Networking (Wons)' as [Workgroup]
--      ,[Resource]
--      ,[FYear]
--      ,[FiscalYear]
--      ,[FiscalPeriod]
--      ,[PeriodStartDate]
--      ,[PeriodEndDate]
--      ,[DaysInPeriod]
--      ,[NonWorkingDays]
--      ,[TotalHours]
--      ,[AnnualTargetHours]
--      ,[UtilizationHours]
--      ,[WeeklyUtilization]
--      ,[ForecastHours]
--      ,[ActualHours]
--      ,[VarianceHours]
--      ,[YTDUtilizationHours]
--      ,[YTDUtilization]
--      ,[YTDForecastHours]
--      ,[HoursPerWeek]
--      ,[UtilizationWeekly]
--  FROM [Changepoint].[dbo].[BG_New_UtilizationForecast_Table_CG]
--  where Resource='Wons, Dan' and year(PeriodEndDate)>=2018

--select * from BG_New_UtilizationForecast_Table_CG where Resource in ('Blatin, Vladimir', 'Wons, Dan') and year(PeriodEndDate)>=2018


truncate table BG_WeeklyResourceLoading_Periods_Table_CG
	insert into BG_WeeklyResourceLoading_Periods_Table_CG 
	select       p.Period0,	      p.StartDate0,	      p.Period1,	      p.StartDate1,	      p.Period2,	      p.StartDate2,	      p.Period3,	      p.StartDate3,	      
				 p.Period4,	      p.StartDate4,	      p.Period5,	      p.StartDate5,	      p.Period6,	      p.StartDate6,	      p.Period7,	      p.StartDate7,	      
				 p.Period8,	      p.StartDate8,	      p.Period9,	      p.StartDate9,	      p.Period10,	      p.StartDate10,	      p.Period11,	      p.StartDate11,	      
				 p.Period12,	      p.StartDate12,	      p.Period13,	      p.StartDate13,	      p.Period14,	      p.StartDate14
	from dbo.BG_WeeklyResourceLoadingPeriods_CG p

Truncate table BG_WeeklyResourceLoading_Table_CG
	insert into BG_WeeklyResourceLoading_Table_CG select * from BG_WeeklyResourceLoading_CG

--drop table BG_WeeklyResourceLoading_Periods_Table_CG
--	insert into BG_WeeklyResourceLoading_Periods_Table_CG select * from BG_WeeklyResourceLoading_Periods_CG

truncate table BG_WeeklyResourceLoadingBillable_Table_CG
	insert into BG_WeeklyResourceLoadingBillable_Table_CG select * from BG_WeeklyResourceLoading_CG

--2018 engagement profitability
truncate table BG_EngagementProject_Profitability_2018_Table_CG
insert into BG_EngagementProject_Profitability_2018_Table_CG select * from BG_EngagementProject_Profitability_2018_CG

--here
truncate table BG_ProjectProfitability_NoContractor_CG
	insert into BG_ProjectProfitability_NoContractor_CG select * from [BG_EngagementProject_Profitability_NoContractor_CG]

truncate table BG_ProjectProfitability_NoContractor_2017_CG
	insert into BG_ProjectProfitability_NoContractor_2017_CG select * from [BG_EngagementProject_Profitability_NoContractor_2017_CG]

truncate table BG_ProjectProfitability_NoContractor_2017_PM_CG
	insert into BG_ProjectProfitability_NoContractor_2017_PM_CG select * from BG_EngagementProject_Profitability_NoContractor_PM_2017_CG

--drop table BG_ProjectProfitability_NoContractor_2017_CG
--	select * into BG_ProjectProfitability_NoContractor_2017_CG from [BG_EngagementProject_Profitability_NoContractor_2017_CG]

truncate table BG_ProjectProfitability_CG
	insert into BG_ProjectProfitability_CG select * from [BG_EngagementProject_Profitability_CG]

truncate table BG_TimeandWriteOff_Table_CG
	insert into BG_TimeandWriteOff_Table_CG select *  from BG_Time_and_WriteOff_VIEW where TimeDate>='20140101'
END


GO
