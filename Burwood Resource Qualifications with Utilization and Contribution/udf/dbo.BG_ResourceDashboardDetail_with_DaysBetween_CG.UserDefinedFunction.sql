USE [Changepoint]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_ResourceDashboardDetail_with_DaysBetween_CG]    Script Date: 10/17/2019 3:12:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create FUNCTION [dbo].[BG_ResourceDashboardDetail_with_DaysBetween_CG] 
(@StartDate date, @EndDate date)
RETURNS TABLE 
AS
RETURN 

SELECT 
	*,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month1Start] and [EffectiveEndDate]>= [Month1End]
		 then datediff(day,  [Month1Start], [Month1End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month1Start] and [EffectiveDate]<= [Month1End] and [EffectiveEndDate]>[Month1End] 
		 then datediff(day, [EffectiveDate], [Month1End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month1End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month1Start] and [EffectiveEndDate]= [Month1End]
		 then datediff(day, [Month1Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month1Start] and [EffectiveEndDate]= [Month1Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month1Start] and [EffectiveEndDate]<= [Month1Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month1Start] and [EffectiveEndDate]< [Month1End]
		 then datediff(day, [Month1Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month1Start] and [EffectiveEndDate]>= [Month1End]
		 then datediff(day, [Month1Start], [Month1End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month1Start] and [EffectiveEndDate]<=[Month1End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month1DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month2Start] and [EffectiveEndDate]>= [Month2End]
		 then datediff(day,  [Month2Start], [Month2End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month2Start] and [EffectiveDate]<= [Month2End] and [EffectiveEndDate]>[Month2End] 
		 then datediff(day, [EffectiveDate], [Month2End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month2End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month2Start] and [EffectiveEndDate]= [Month2End]
		 then datediff(day, [Month2Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month2Start] and [EffectiveEndDate]= [Month2Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month2Start] and [EffectiveEndDate]<= [Month2Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month2Start] and [EffectiveEndDate]< [Month2End]
		 then datediff(day, [Month2Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month2Start] and [EffectiveEndDate]>= [Month2End]
		 then datediff(day, [Month2Start], [Month2End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month2Start] and [EffectiveEndDate]<=[Month2End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month2DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month3Start] and [EffectiveEndDate]>= [Month3End]
		 then datediff(day,  [Month3Start], [Month3End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month3Start] and [EffectiveDate]<= [Month3End] and [EffectiveEndDate]>[Month3End] 
		 then datediff(day, [EffectiveDate], [Month3End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month3End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month3Start] and [EffectiveEndDate]= [Month3End]
		 then datediff(day, [Month3Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month3Start] and [EffectiveEndDate]= [Month3Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month3Start] and [EffectiveEndDate]<= [Month3Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month3Start] and [EffectiveEndDate]< [Month3End]
		 then datediff(day, [Month3Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month3Start] and [EffectiveEndDate]>= [Month3End]
		 then datediff(day, [Month3Start], [Month3End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month3Start] and [EffectiveEndDate]<=[Month3End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month3DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month4Start] and [EffectiveEndDate]>= [Month4End]
		 then datediff(day,  [Month4Start], [Month4End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month4Start] and [EffectiveDate]<= [Month4End] and [EffectiveEndDate]>[Month4End] 
		 then datediff(day, [EffectiveDate], [Month4End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month4End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month4Start] and [EffectiveEndDate]= [Month4End]
		 then datediff(day, [Month4Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month4Start] and [EffectiveEndDate]= [Month4Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month4Start] and [EffectiveEndDate]<= [Month4Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month4Start] and [EffectiveEndDate]< [Month4End]
		 then datediff(day, [Month4Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month4Start] and [EffectiveEndDate]>= [Month4End]
		 then datediff(day, [Month4Start], [Month4End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month4Start] and [EffectiveEndDate]<=[Month4End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month4DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month5Start] and [EffectiveEndDate]>= [Month5End]
		 then datediff(day,  [Month5Start], [Month5End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month5Start] and [EffectiveDate]<= [Month5End] and [EffectiveEndDate]>[Month5End] 
		 then datediff(day, [EffectiveDate], [Month5End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month5End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month5Start] and [EffectiveEndDate]= [Month5End]
		 then datediff(day, [Month5Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month5Start] and [EffectiveEndDate]= [Month5Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month5Start] and [EffectiveEndDate]<= [Month5Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month5Start] and [EffectiveEndDate]< [Month5End]
		 then datediff(day, [Month5Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month5Start] and [EffectiveEndDate]>= [Month5End]
		 then datediff(day, [Month5Start], [Month5End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month5Start] and [EffectiveEndDate]<=[Month5End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month5DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month6Start] and [EffectiveEndDate]>= [Month6End]
		 then datediff(day,  [Month6Start], [Month6End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month6Start] and [EffectiveDate]<= [Month6End] and [EffectiveEndDate]>[Month6End] 
		 then datediff(day, [EffectiveDate], [Month6End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month6End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month6Start] and [EffectiveEndDate]= [Month6End]
		 then datediff(day, [Month6Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month6Start] and [EffectiveEndDate]= [Month6Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month6Start] and [EffectiveEndDate]<= [Month6Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month6Start] and [EffectiveEndDate]< [Month6End]
		 then datediff(day, [Month6Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month6Start] and [EffectiveEndDate]>= [Month6End]
		 then datediff(day, [Month6Start], [Month6End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month6Start] and [EffectiveEndDate]<=[Month6End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month6DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month7Start] and [EffectiveEndDate]>= [Month7End]
		 then datediff(day,  [Month7Start], [Month7End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month7Start] and [EffectiveDate]<= [Month7End] and [EffectiveEndDate]>[Month7End] 
		 then datediff(day, [EffectiveDate], [Month7End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month7End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month7Start] and [EffectiveEndDate]= [Month7End]
		 then datediff(day, [Month7Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month7Start] and [EffectiveEndDate]= [Month7Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month7Start] and [EffectiveEndDate]<= [Month7Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month7Start] and [EffectiveEndDate]< [Month7End]
		 then datediff(day, [Month7Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month7Start] and [EffectiveEndDate]>= [Month7End]
		 then datediff(day, [Month7Start], [Month7End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month7Start] and [EffectiveEndDate]<=[Month7End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month7DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month8Start] and [EffectiveEndDate]>= [Month8End]
		 then datediff(day,  [Month8Start], [Month8End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month8Start] and [EffectiveDate]<= [Month8End] and [EffectiveEndDate]>[Month8End] 
		 then datediff(day, [EffectiveDate], [Month8End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month8End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month8Start] and [EffectiveEndDate]= [Month8End]
		 then datediff(day, [Month8Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month8Start] and [EffectiveEndDate]= [Month8Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month8Start] and [EffectiveEndDate]<= [Month8Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month8Start] and [EffectiveEndDate]< [Month8End]
		 then datediff(day, [Month8Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month8Start] and [EffectiveEndDate]>= [Month8End]
		 then datediff(day, [Month8Start], [Month8End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month8Start] and [EffectiveEndDate]<=[Month8End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month8DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month9Start] and [EffectiveEndDate]>= [Month9End]
		 then datediff(day,  [Month9Start], [Month9End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month9Start] and [EffectiveDate]<= [Month9End] and [EffectiveEndDate]>[Month9End] 
		 then datediff(day, [EffectiveDate], [Month9End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month9End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month9Start] and [EffectiveEndDate]= [Month9End]
		 then datediff(day, [Month9Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month9Start] and [EffectiveEndDate]= [Month9Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month9Start] and [EffectiveEndDate]<= [Month9Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month9Start] and [EffectiveEndDate]< [Month9End]
		 then datediff(day, [Month9Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month9Start] and [EffectiveEndDate]>= [Month9End]
		 then datediff(day, [Month9Start], [Month9End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month9Start] and [EffectiveEndDate]<=[Month9End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month9DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month10Start] and [EffectiveEndDate]>= [Month10End]
		 then datediff(day,  [Month10Start], [Month10End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month10Start] and [EffectiveDate]<= [Month10End] and [EffectiveEndDate]>[Month10End] 
		 then datediff(day, [EffectiveDate], [Month10End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month10End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month10Start] and [EffectiveEndDate]= [Month10End]
		 then datediff(day, [Month10Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month10Start] and [EffectiveEndDate]= [Month10Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month10Start] and [EffectiveEndDate]<= [Month10Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month10Start] and [EffectiveEndDate]< [Month10End]
		 then datediff(day, [Month10Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month10Start] and [EffectiveEndDate]>= [Month10End]
		 then datediff(day, [Month10Start], [Month10End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month10Start] and [EffectiveEndDate]<=[Month10End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month10DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month11Start] and [EffectiveEndDate]>= [Month11End]
		 then datediff(day,  [Month11Start], [Month11End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month11Start] and [EffectiveDate]<= [Month11End] and [EffectiveEndDate]>[Month11End] 
		 then datediff(day, [EffectiveDate], [Month11End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month11End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month11Start] and [EffectiveEndDate]= [Month11End]
		 then datediff(day, [Month11Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month11Start] and [EffectiveEndDate]= [Month11Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month11Start] and [EffectiveEndDate]<= [Month11Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month11Start] and [EffectiveEndDate]< [Month11End]
		 then datediff(day, [Month11Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month11Start] and [EffectiveEndDate]>= [Month11End]
		 then datediff(day, [Month11Start], [Month11End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month11Start] and [EffectiveEndDate]<=[Month11End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month11DaysBetween,
	case when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month12Start] and [EffectiveEndDate]>= [Month12End]
		 then datediff(day,  [Month12Start], [Month12End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month12Start] and [EffectiveDate]<= [Month12End] and [EffectiveEndDate]>[Month12End] 
		 then datediff(day, [EffectiveDate], [Month12End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>[Month12End] 
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month12Start] and [EffectiveEndDate]= [Month12End]
		 then datediff(day, [Month12Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month12Start] and [EffectiveEndDate]= [Month12Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month12Start] and [EffectiveEndDate]<= [Month12Start]
		 then 0
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]<= [Month12Start] and [EffectiveEndDate]< [Month12End]
		 then datediff(day, [Month12Start], [EffectiveEndDate])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>= [Month12Start] and [EffectiveEndDate]>= [Month12End]
		 then datediff(day, [Month12Start], [Month12End])+1
		 when [Type] not in ('EX', 'PS', 'CS') and [EffectiveDate]>=[Month12Start] and [EffectiveEndDate]<=[Month12End]
		 then datediff(day, [EffectiveDate], [EffectiveEndDate])+1
		 else 0
	end as Month12DaysBetween
FROM 
	[BG_ResourceDashboardDetail_with_MonthStartandEndDates_CG] (@StartDate, @EndDate)
GO
