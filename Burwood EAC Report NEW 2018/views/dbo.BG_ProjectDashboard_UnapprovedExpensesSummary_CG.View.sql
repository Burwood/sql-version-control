USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_UnapprovedExpensesSummary_CG]    Script Date: 10/18/2019 4:57:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO








CREATE view [dbo].[BG_ProjectDashboard_UnapprovedExpensesSummary_CG] AS 
select
e.Name as Engagement,
e.EngagementStatus,
e.EngagementId,
p.Name as Project,
p.ProjectStatus,
p.ProjectId,
count(*) as UnapprovedExpenses,
sum(ex.Quantity*ex.UnitPrice) as TotalExpense
from 
	Expense ex with (nolock)
		join
	Project p with (nolock) on ex.ProjectId=p.ProjectId
		join
	Engagement e with (nolock) on p.EngagementId=e.EngagementId
where
	ApprovalStatusDate IS NULL
group by 
	e.Name, 
	e.EngagementStatus,
	e.EngagementId, 
	p.Name, 
	p.ProjectStatus,
	p.ProjectId

GO
