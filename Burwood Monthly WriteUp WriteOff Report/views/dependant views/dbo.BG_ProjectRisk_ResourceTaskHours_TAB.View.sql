USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectRisk_ResourceTaskHours_TAB]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[BG_ProjectRisk_ResourceTaskHours_TAB] as 
select Distinct
	cst.Name as Customer,
	e.Name as Engagement,
	p.Name as Project,
	pm.ProjectManager,
	o.Owner as AccountExecutive,
	o.Solutions_Expert as SolutionExpert,
	o.SolutionArchitect as SolutionArchitect,
	p.ProjectId,
	ps.Skills as ProjectSkills,
	p.ProjectValue,
	e.ContractAmount,
	convert(date, p.BaselineStart) as StartBaseline,
	convert(date, p.PlannedStart) as StartPlanned,
    convert(date, p.ActualStart) as StartActual,
	convert(date, p.BaselineFinish) as FinishBaseline,
	convert(date, p.PlannedFinish) as FinishPlanned,
	convert(date, ActualFinish) as FinishActual,
	p.BaselineHours ProjectBaselineHours,
	p.PlannedHours ProjectPlannedHours,
	p.ActualHours ProjectActualHours, 
	r.Name as Resource,
	r.ResourceId,
	rr.Region,
	cc.Name as Practice,
	t.Name as Task,
	t.BaselineHours TaskBaselineHours,
	t.PlannedHours TaskPlannedHours,
	t.RollupActualHours as TaskActualHours,
	convert(date, tw.TimeDate) as TimeDate,
	tw.BillingRate,
	tw.RegularHours+tw.OvertimeHours as Hours,
	tw.AdjustedRegularHours,
	tw.AmountWrittenOff,

	tw.BillingRate*(tw.RegularHours+tw.OvertimeHours) as BillingAmount
from 
	BG_Time_and_WriteOff_VIEW tw
		left outer join
	Tasks t with (nolock) on tw.TaskId=t.TaskId and tw.ProjectId=t.ProjectId
		left outer join
	Project p with (nolock) on tw.ProjectId=p.ProjectId
		left outer join
	Resources r with (nolock) on tw.ResourceId=r.ResourceId
		left outer join
	BG_ProjectSkills_TAB ps with (nolock) on tw.ProjectId=ps.ProjectId
		left outer join
	CostCenters cc with (nolock) on r.CostCenterId=cc.CostCenter
		left outer join
	BG_ResourceRegion_CG rr on tw.ResourceId=rr.ResourceId
		left outer join
	Customer cst with (nolock) on tw.CustomerId=cst.CustomerId
		left outer join
	Engagement e with (nolock) on p.EngagementId=e.EngagementId
		left outer join
	BG_ProjectManager_CG pm with (nolock) on p.ProjectId=pm.ProjectId
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].dbo.BG_Opportunity_Resources_CG o with (nolock) on e.OpportunityId=o.OpportunityId
where 
	tw.ApprovalStatus='A'
	--and tw.ProjectId='012E87CC-9126-4DE5-8E59-01B801BB2505'



GO
