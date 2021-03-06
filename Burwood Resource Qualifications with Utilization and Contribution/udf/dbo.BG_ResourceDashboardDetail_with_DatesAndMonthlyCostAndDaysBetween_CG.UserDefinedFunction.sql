USE [Changepoint]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_ResourceDashboardDetail_with_DatesAndMonthlyCostAndDaysBetween_CG]    Script Date: 10/17/2019 3:12:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[BG_ResourceDashboardDetail_with_DatesAndMonthlyCostAndDaysBetween_CG] 
(@StartDate date, @EndDate date)
RETURNS TABLE 
AS
RETURN 

SELECT 
	*,
	case when TerminationDate is not NULL and TerminationDate<>'20120101' then 'Yes' else 'No' end as Terminated,
	case when Type='HC' then PS_Actual else 0 end as HC_Margin,
	case when Type='HC' then PS_Budget else 0 end as HC_Budget,
	case when Type<>'HC' then PS_Actual else 0 end as PS_Actual1,
	case when Type<>'HC' then PS_Budget else 0 end as PS_Budget1,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]>= [Month1End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month1Start] and [CostEffectiveStart]<= [Month1End] and [CostEffectiveEnd]>[Month1End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month1End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]= [Month1End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]= [Month1Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]<= [Month1Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]< [Month1End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month1Start] and [CostEffectiveEnd]>= [Month1End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month1Start] and [CostEffectiveEnd]<=[Month1End]
		 then Daily_Cost
		 else 0
	end as Month1Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]>= [Month2End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month2Start] and [CostEffectiveStart]<= [Month2End] and [CostEffectiveEnd]>[Month2End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month2End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]= [Month2End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]= [Month2Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]<= [Month2Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]< [Month2End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month2Start] and [CostEffectiveEnd]>= [Month2End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month2Start] and [CostEffectiveEnd]<=[Month2End]
		 then Daily_Cost
		 else 0
	end as Month2Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]>= [Month3End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month3Start] and [CostEffectiveStart]<= [Month3End] and [CostEffectiveEnd]>[Month3End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month3End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]= [Month3End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]= [Month3Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]<= [Month3Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]< [Month3End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month3Start] and [CostEffectiveEnd]>= [Month3End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month3Start] and [CostEffectiveEnd]<=[Month3End]
		 then Daily_Cost
		 else 0
	end as Month3Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]>= [Month4End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month4Start] and [CostEffectiveStart]<= [Month4End] and [CostEffectiveEnd]>[Month4End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month4End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]= [Month4End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]= [Month4Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]<= [Month4Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]< [Month4End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month4Start] and [CostEffectiveEnd]>= [Month4End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month4Start] and [CostEffectiveEnd]<=[Month4End]
		 then Daily_Cost
		 else 0
	end as Month4Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]>= [Month5End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month5Start] and [CostEffectiveStart]<= [Month5End] and [CostEffectiveEnd]>[Month5End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month5End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]= [Month5End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]= [Month5Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]<= [Month5Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]< [Month5End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month5Start] and [CostEffectiveEnd]>= [Month5End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month5Start] and [CostEffectiveEnd]<=[Month5End]
		 then Daily_Cost
		 else 0
	end as Month5Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]>= [Month6End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month6Start] and [CostEffectiveStart]<= [Month6End] and [CostEffectiveEnd]>[Month6End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month6End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]= [Month6End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]= [Month6Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]<= [Month6Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]< [Month6End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month6Start] and [CostEffectiveEnd]>= [Month6End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month6Start] and [CostEffectiveEnd]<=[Month6End]
		 then Daily_Cost
		 else 0
	end as Month6Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]>= [Month7End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month7Start] and [CostEffectiveStart]<= [Month7End] and [CostEffectiveEnd]>[Month7End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month7End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]= [Month7End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]= [Month7Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]<= [Month7Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]< [Month7End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month7Start] and [CostEffectiveEnd]>= [Month7End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month7Start] and [CostEffectiveEnd]<=[Month7End]
		 then Daily_Cost
		 else 0
	end as Month7Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]>= [Month8End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month8Start] and [CostEffectiveStart]<= [Month8End] and [CostEffectiveEnd]>[Month8End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month8End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]= [Month8End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]= [Month8Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]<= [Month8Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]< [Month8End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month8Start] and [CostEffectiveEnd]>= [Month8End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month8Start] and [CostEffectiveEnd]<=[Month8End]
		 then Daily_Cost
		 else 0
	end as Month8Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]>= [Month9End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month9Start] and [CostEffectiveStart]<= [Month9End] and [CostEffectiveEnd]>[Month9End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month9End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]= [Month9End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]= [Month9Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]<= [Month9Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]< [Month9End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month9Start] and [CostEffectiveEnd]>= [Month9End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month9Start] and [CostEffectiveEnd]<=[Month9End]
		 then Daily_Cost
		 else 0
	end as Month9Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]>= [Month10End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month10Start] and [CostEffectiveStart]<= [Month10End] and [CostEffectiveEnd]>[Month10End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month10End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]= [Month10End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]= [Month10Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]<= [Month10Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]< [Month10End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month10Start] and [CostEffectiveEnd]>= [Month10End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month10Start] and [CostEffectiveEnd]<=[Month10End]
		 then Daily_Cost
		 else 0
	end as Month10Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]>= [Month11End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month11Start] and [CostEffectiveStart]<= [Month11End] and [CostEffectiveEnd]>[Month11End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month11End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]= [Month11End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]= [Month11Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]<= [Month11Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]< [Month11End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month11Start] and [CostEffectiveEnd]>= [Month11End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month11Start] and [CostEffectiveEnd]<=[Month11End]
		 then Daily_Cost
		 else 0
	end as Month11Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]>= [Month12End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month12Start] and [CostEffectiveStart]<= [Month12End] and [CostEffectiveEnd]>[Month12End] 
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month12End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]= [Month12End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]= [Month12Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]<= [Month12Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]< [Month12End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month12Start] and [CostEffectiveEnd]>= [Month12End]
		 then Daily_Cost
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month12Start] and [CostEffectiveEnd]<=[Month12End]
		 then Daily_Cost
		 else 0
	end as Month12Cost,
		case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]>= [Month1End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month1Start] and [CostEffectiveStart]<= [Month1End] and [CostEffectiveEnd]>[Month1End] 
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month1End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]= [Month1End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]= [Month1Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]<= [Month1Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month1Start] and [CostEffectiveEnd]< [Month1End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month1Start] and [CostEffectiveEnd]>= [Month1End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month1Start] and [CostEffectiveEnd]<=[Month1End]
		 then 405.56
		 else 0
	end as NewMonth1Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]>= [Month2End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month2Start] and [CostEffectiveStart]<= [Month2End] and [CostEffectiveEnd]>[Month2End] 
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month2End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]= [Month2End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]= [Month2Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]<= [Month2Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month2Start] and [CostEffectiveEnd]< [Month2End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month2Start] and [CostEffectiveEnd]>= [Month2End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month2Start] and [CostEffectiveEnd]<=[Month2End]
		 then 405.56
		 else 0
	end as NewMonth2Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]>= [Month3End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month3Start] and [CostEffectiveStart]<= [Month3End] and [CostEffectiveEnd]>[Month3End] 
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month3End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]= [Month3End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]= [Month3Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]<= [Month3Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month3Start] and [CostEffectiveEnd]< [Month3End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month3Start] and [CostEffectiveEnd]>= [Month3End]
		 then 405.56
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month3Start] and [CostEffectiveEnd]<=[Month3End]
		 then 405.56
		 else 0
	end as NewMonth3Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]>= [Month4End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month4Start] and [CostEffectiveStart]<= [Month4End] and [CostEffectiveEnd]>[Month4End] 
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month4End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]= [Month4End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]= [Month4Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]<= [Month4Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month4Start] and [CostEffectiveEnd]< [Month4End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month4Start] and [CostEffectiveEnd]>= [Month4End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month4Start] and [CostEffectiveEnd]<=[Month4End]
		 then 401.1
		 else 0
	end as NewMonth4Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]>= [Month5End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month5Start] and [CostEffectiveStart]<= [Month5End] and [CostEffectiveEnd]>[Month5End] 
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month5End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]= [Month5End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]= [Month5Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]<= [Month5Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month5Start] and [CostEffectiveEnd]< [Month5End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month5Start] and [CostEffectiveEnd]>= [Month5End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month5Start] and [CostEffectiveEnd]<=[Month5End]
		 then 401.1
		 else 0
	end as NewMonth5Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]>= [Month6End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month6Start] and [CostEffectiveStart]<= [Month6End] and [CostEffectiveEnd]>[Month6End] 
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month6End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]= [Month6End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]= [Month6Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]<= [Month6Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month6Start] and [CostEffectiveEnd]< [Month6End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month6Start] and [CostEffectiveEnd]>= [Month6End]
		 then 401.1
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month6Start] and [CostEffectiveEnd]<=[Month6End]
		 then 401.1
		 else 0
	end as NewMonth6Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]>= [Month7End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month7Start] and [CostEffectiveStart]<= [Month7End] and [CostEffectiveEnd]>[Month7End] 
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month7End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]= [Month7End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]= [Month7Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]<= [Month7Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month7Start] and [CostEffectiveEnd]< [Month7End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month7Start] and [CostEffectiveEnd]>= [Month7End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month7Start] and [CostEffectiveEnd]<=[Month7End]
		 then 396.74
		 else 0
	end as NewMonth7Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]>= [Month8End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month8Start] and [CostEffectiveStart]<= [Month8End] and [CostEffectiveEnd]>[Month8End] 
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month8End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]= [Month8End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]= [Month8Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]<= [Month8Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month8Start] and [CostEffectiveEnd]< [Month8End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month8Start] and [CostEffectiveEnd]>= [Month8End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month8Start] and [CostEffectiveEnd]<=[Month8End]
		 then 396.74
		 else 0
	end as NewMonth8Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]>= [Month9End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month9Start] and [CostEffectiveStart]<= [Month9End] and [CostEffectiveEnd]>[Month9End] 
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month9End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]= [Month9End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]= [Month9Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]<= [Month9Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month9Start] and [CostEffectiveEnd]< [Month9End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month9Start] and [CostEffectiveEnd]>= [Month9End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month9Start] and [CostEffectiveEnd]<=[Month9End]
		 then 396.74
		 else 0
	end as NewMonth9Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]>= [Month10End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month10Start] and [CostEffectiveStart]<= [Month10End] and [CostEffectiveEnd]>[Month10End] 
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month10End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]= [Month10End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]= [Month10Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]<= [Month10Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month10Start] and [CostEffectiveEnd]< [Month10End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month10Start] and [CostEffectiveEnd]>= [Month10End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month10Start] and [CostEffectiveEnd]<=[Month10End]
		 then 396.74
		 else 0
	end as NewMonth10Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]>= [Month11End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month11Start] and [CostEffectiveStart]<= [Month11End] and [CostEffectiveEnd]>[Month11End] 
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month11End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]= [Month11End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]= [Month11Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]<= [Month11Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month11Start] and [CostEffectiveEnd]< [Month11End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month11Start] and [CostEffectiveEnd]>= [Month11End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month11Start] and [CostEffectiveEnd]<=[Month11End]
		 then 396.74
		 else 0
	end as NewMonth11Cost,
	case when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]>= [Month12End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month12Start] and [CostEffectiveStart]<= [Month12End] and [CostEffectiveEnd]>[Month12End] 
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>[Month12End] then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]= [Month12End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]= [Month12Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]<= [Month12Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]<= [Month12Start] and [CostEffectiveEnd]< [Month12End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>= [Month12Start] and [CostEffectiveEnd]>= [Month12End]
		 then 396.74
		 when [Type] not in ('EX', 'PS', 'CS') and [CostEffectiveStart]>=[Month12Start] and [CostEffectiveEnd]<=[Month12End]
		 then 396.74
		 else 0
	end as NewMonth12Cost
FROM 
	[BG_ResourceDashboardDetail_with_DaysBetween_CG] (@StartDate, @EndDate)
GO
