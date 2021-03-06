USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_ForecastSummary_CG]    Script Date: 9/30/2019 5:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





--select count(*) from [BG_ProjectDashboard_ForecastDetail_CG] --where EngagementId='53605142-723D-4ECF-A851-5060596281DD'



CREATE view [dbo].[BG_ProjectDashboard_ForecastSummary_CG] as
with a as (
SELECT	
	r.Name as Resource,	
	ta.ResourceId, 
	'Project' AS Type, 
	e.Name as Engagement,
	e.EngagementStatus,
	e.EngagementId,
	p.Name AS Project, 
	p.ProjectStatus,
	p.ProjectId,
	t.Name AS TaskName, 
	ta.PlannedHours, 
	ta.ActualHours, 
	ta.PlannedRemainingHours,
	--f.Period, 
	--f.StartDate AS PeriodStartDate, 
	--f.EndDate AS PeriodEndDate, 
	--f.Period + ' (' + CONVERT(nvarchar(30),f.StartDate,101) + ' - ' + CONVERT(nvarchar(30),f.EndDate,101) + ')' AS Week,
	ebr.NegotiatedRate AS BillingRate, 
	rr.HourlyCostRate AS CostRate, 
	bo.[Description] AS Region,
	(coalesce(ta.PlannedRemainingHours,0)*coalesce(rr.HourlyCostRate,0)) as ForecastCost
FROM		
	
	--(select distinct ResourceId, TaskId, TaskAssignmentId, BillingRole, EngagementId, ProjectId from TaskAssignment with (nolock) where Deleted=0) ta ON w.TaskAssignmentId = ta.TaskAssignmentId  and w.ProjectId=ta.ProjectId --AND ta.Deleted = 0
	--	join
	Engagement e WITH (nolock) 
		INNER JOIN  
	BillingOffice bo WITH (nolock) ON e.BillingOfficeId = bo.BillingOfficeId
		join
	Project p WITH (nolock) ON e.EngagementId=p.EngagementId
		INNER JOIN	
	Tasks t WITH (nolock) ON p.ProjectId=t.ProjectId and t.Deleted=0
		left outer join
	TaskAssignment ta with (nolock) on t.ProjectId=ta.ProjectId and t.TaskId=ta.TaskId and ta.Deleted=0
		left outer join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId	
		LEFT OUTER JOIN 
	EngagementBillingRates ebr WITH (nolock) ON ta.BillingRole = ebr.BillingRoleId AND ta.EngagementId = ebr.EngagementId
		OUTER APPLY 
	(SELECT TOP 1 HourlyCostRate FROM ResourceRate WITH (nolock) WHERE ResourceId = ta.ResourceID AND Active = 1 ORDER BY EffectiveDate DESC) rr
--where
--	--f.StartDate>=convert(date, DATEADD(week, DATEDIFF(week,'19000101',getdate()),'1899-12-30T19:00:00'))
----	--and t.Deleted=0
--	  e.EngagementId='1735A71E-3ED4-4B62-9DBB-9004CBFEB883'
)
select
	Engagement,
	EngagementStatus,
	EngagementId,
	Project,
	ProjectStatus,
	ProjectId,
	--Resource,
	sum(f.PlannedRemainingHours) as ForecastHours,
	sum(f.PlannedRemainingHours*f.BillingRate) as ForecastRevenue,
	sum(f.PlannedRemainingHours*f.CostRate) as ForecastCost
from
	a as f with (nolock)
--where
--	ProjectStatus<>'C'
group by
	Engagement,
	EngagementStatus,
	EngagementId,
	Project,
	ProjectStatus,
	ProjectId
	--Resource

GO
