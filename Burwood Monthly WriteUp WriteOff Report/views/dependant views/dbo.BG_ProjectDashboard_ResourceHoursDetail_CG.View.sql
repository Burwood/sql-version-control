USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_ResourceHoursDetail_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[BG_ProjectDashboard_ResourceHoursDetail_CG] as 
with a as (
select
	b.Description as Region,
	cc.Name as Practice,
	w.Name as Workgroup,
	p.Name as Project,
	cast(p.ActualFinish as date) as ActualFinish,
	cast(p.PlannedFinish as date) as PlannedFinish,
	p.ProjectId,
	r.Name as Resource,
	case when r.EmployeeType='CO' then 2 else 1 end as EmployeeTypeSort,
	r.ResourceId,
	(select rr.HourlyBillRate from ResourceRate rr where rr.Active=1 and rr.ResourceId=r.ResourceId and rr.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr.ResourceId=r2.ResourceId)) 
	as StandardHourlyBillRate,
	(select rr2.HourlyCostRate from ResourceRate rr2 where rr2.Active=1 and rr2.ResourceId=r.ResourceId and rr2.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr2.ResourceId=r2.ResourceId)) 
	as StandardHourlyCostRate,
	eb.NegotiatedRate as ProjectBillingRate,
	--min(bt.BillingRate) as ProjectBillingRate,
	e.OvertimePercentage/100 as OvertimePercentage,
	br.BillingRoleId,
	br.Description,
	r.Title,
	eb.CostRate as EngagementCostRate,
	c.PlannedMarginPercent
from 
	Project p with (nolock)
		left outer join
	BG_ProjectDashboard_CustomFields_CG c with (nolock) on p.ProjectId=c.ProjectId and p.EngagementId=c.EngagementId
		join
	(select distinct EngagementId, ProjectId, BillingRole, ResourceId from TaskAssignment with (nolock)) as ta on p.ProjectId=ta.ProjectId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
		join
	EngagementBillingRates eb with (nolock) on ta.BillingRole=eb.BillingRoleId and ta.EngagementId=eb.EngagementId
		join
	BillingRole br with (nolock) on eb.BillingRoleId=br.BillingRoleId and br.Deleted=0
		join
	dbo.Engagement e with (nolock) on p.EngagementId=e.EngagementId
		left outer join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		left outer join
	Workgroup w with (nolock) on e.AssociatedWorkgroup=w.WorkgroupId
--where
--	p.Name ='Carle Foundation Hospital Cisco ISE Project 2017'--in ('Rush University Medical Center - Cybersecurity Strategy', 'Wahl Power BI Phase 2')
),
b as (
select
	p.EngagementId,
	p.ProjectId,
	p.Name as Project,
	r.ResourceId,
	r.Name as Resource,
	ta.BillingRole,
	t.Name as Task,
	sum(ta.PlannedHours) as PlannedHours,
	sum(ta.ActualHours) as ActualHours,
	sum(ta.RemainingHours) as RemainingHours,
	sum(ta.PlannedRemainingHours) as PlannedRemainingHours
from
	Project p with (nolock)
		join
	Tasks t with (nolock) on p.ProjectId=t.ProjectId
		join
	TaskAssignment ta with (nolock) on t.ProjectId=ta.ProjectId and t.TaskId=ta.TaskId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
--where
--	p.ProjectId='949CFD9A-7EF6-4A34-AEEE-C57BD401A9AF'
group by
	p.EngagementId,
	p.ProjectId,
	p.Name,
	r.ResourceId,
	r.Name,
	ta.BillingRole,
	t.Name
),
c as (
select
	a.*,
	b.Task,
	coalesce(b.PlannedHours,0) as PlannedHours,
	coalesce(b.ActualHours,0) as ActualHours,
	coalesce(b.RemainingHours,0) as RemainingHours,
	coalesce(b.PlannedRemainingHours,0) as PlannedRemainingHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0)) as EACHours,
	(coalesce(b.PlannedHours,0))*ProjectBillingRate as PlannedRateTimesHours,
	(coalesce(b.ActualHours,0))*ProjectBillingRate as ActualRateTimesHours,
	(coalesce(b.RemainingHours,0))*ProjectBillingRate as RemainingRateTimesHours,
	(coalesce(b.PlannedRemainingHours,0))*ProjectBillingRate as PlannedRemainingRateTimesHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0))*ProjectBillingRate as EACRateTimesHours,
	ProjectBillingRate-EngagementCostRate as EngagementMarginRate,
	ProjectBillingRate-StandardHourlyCostRate as ResourceMarginRate,
	case when ProjectBillingRate=0 then 0 else (ProjectBillingRate-EngagementCostRate)/ProjectBillingRate end as 'EngagementRateMarginDecimal',
	case when ProjectBillingRate=0 then 0 else round((((ProjectBillingRate-EngagementCostRate)/ProjectBillingRate)*100),2) end as 'EngagementRateMargin%',
	case when ProjectBillingRate=0 then 0 else (ProjectBillingRate-StandardHourlyCostRate)/ProjectBillingRate end as 'ResourceRateMarginDecimal',
	case when ProjectBillingRate=0 then 0 else round((((ProjectBillingRate-StandardHourlyCostRate)/ProjectBillingRate)*100),2) end as 'ResourceRateMargin%',
	(PlannedMarginPercent*100) as 'PlannedMargin%'
from
	a
		join
	b  on a.ProjectId=b.ProjectId and a.ResourceId=b.ResourceId and a.BillingRoleId=b.BillingRole
)

select
	Region,
	Practice,
	Workgroup,
	Project,
	ProjectId,
	Resource,
	Task,
	sum(PlannedHours) as PlannedHours,
	sum(ActualHours) as ActualHours,
	sum(PlannedRateTimesHours) as PlannedFees,
	sum(ActualRateTimesHours) as ActualFees,
	sum(PlannedRemainingHours) as PlannedRemainingHours,
	sum(PlannedRemainingRateTimesHours) as PlannedRemainingFees,
	case when sum(PlannedHours)=0 then 0 else sum(ActualHours)/sum(PlannedHours) end as BurnRate
from
	c
group by
	Region,
	Practice,
	Workgroup,
	Project,
	ProjectId,
	Resource,
	Task

GO
