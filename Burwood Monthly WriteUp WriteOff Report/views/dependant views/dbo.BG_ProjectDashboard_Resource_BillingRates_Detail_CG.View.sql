USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_Resource_BillingRates_Detail_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--select Project, Resource, Title, Task, BillingRole, TimeDate, StandardHourlyCostRate, ProjectBillingRate, PlannedMarginPercent, ResourceRateMarginDecimal, ActualHours, ActualRateTimesHours, RevenueRecognized, PlannedRemainingHours, PlannedRemainingRateTimesHours, RevRecMatches from BG_ProjectDashboard_Resource_BillingRates_Detail_CG where Project='ACC West Coast University - Disaster Recovery- Zerto Azure Deployment' and Resource='Cacioppo, Doug'


CREATE VIEW [dbo].[BG_ProjectDashboard_Resource_BillingRates_Detail_CG] AS


with a as (
select
	b.Description as Region,
	cc.Name as Practice,
	w.Name as Workgroup,
	p.Name as Project,
	bt.Description as BillingType,
	p.ProjectStatus,
	cast(p.ActualFinish as date) as ActualFinish,
	cast(p.PlannedFinish as date) as PlannedFinish,
	--p.EngagementId,
	p.ProjectId,
	r.Name as Resource,
	case when r.EmployeeType='CO' then 2 else 1 end as EmployeeTypeSort,
	r.ResourceId,
	(select rr.HourlyBillRate from ResourceRate rr where rr.Active=1 and rr.ResourceId=r.ResourceId and rr.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr.ResourceId=r2.ResourceId)) 
	as StandardHourlyBillRate,
	(select rr2.HourlyCostRate from ResourceRate rr2 where rr2.Active=1 and rr2.ResourceId=r.ResourceId and rr2.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr2.ResourceId=r2.ResourceId)) 
	as StandardHourlyCostRate,
	eb.NegotiatedRate as ProjectBillingRate,
	--min(bt.BillingRate) as coalesce(ProjectBillingRate,0),
	e.OvertimePercentage/100 as OvertimePercentage,
	br.BillingRoleId,
	br.Description as BillingRole,
	r.Title,
	eb.CostRate as EngagementCostRate,
	coalesce(c.PlannedMarginPercent,0) as PlannedMarginPercent,
	ta.Task,
	ta.TaskId
from 
	Project p with (nolock)
		left outer join
	BG_ProjectDashboard_CustomFields_CG c with (nolock) on p.ProjectId=c.ProjectId and p.EngagementId=c.EngagementId
		join
	(select distinct t.Name as Task, t.TaskId, ta1.EngagementId, ta1.ProjectId, ta1.BillingRole, ta1.ResourceId from TaskAssignment ta1 with (nolock) join Tasks t with (nolock) on ta1.TaskId=t.TaskId where ta1.Deleted=0 and t.Billable=1) as ta on p.ProjectId=ta.ProjectId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
		join
	EngagementBillingRates eb with (nolock) on ta.BillingRole=eb.BillingRoleId and ta.EngagementId=eb.EngagementId
		join
	BillingRole br with (nolock) on eb.BillingRoleId=br.BillingRoleId and br.Deleted=0
		join
	dbo.Engagement e with (nolock) on p.EngagementId=e.EngagementId
		join 
	BillingType bt on e.BillingType=bt.Code
		left outer join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		left outer join
	Workgroup w with (nolock) on e.AssociatedWorkgroup=w.WorkgroupId
--where
--	p.Name ='ACC West Coast University - Disaster Recovery- Zerto Azure Deployment'--in ('Rush University Medical Center - Cybersecurity Strategy', 'Wahl Power BI Phase 2')
--	and r.Name='Cacioppo, Doug'
),
n as (
select
	p.ProjectId,
	r.ResourceId,
	count(ta.BillingRole) as NumberResourceRoles
from 
	Project p with (nolock)
		join
	(select distinct ta1.ProjectId, ta1.BillingRole, ta1.ResourceId from TaskAssignment ta1 with (nolock) join Tasks t with (nolock) on ta1.TaskId=t.TaskId where ta1.Deleted=0 and t.Billable=1) as ta on p.ProjectId=ta.ProjectId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
--where
--	p.Name='ACC West Coast University - Disaster Recovery- Zerto Azure Deployment'
group by
	p.Name,
	p.ProjectStatus,
	p.ProjectId,
	r.Name,
	r.ResourceId
),
b as (
select
	a.*,
	coalesce(b.TaskPlannedHours,0) as TaskPlannedHours,
	coalesce(b.ta_PlannedHours,0) as ta_PlannedHours,
	coalesce(b.ActualHours,0) as ActualHours,
	coalesce(b.RemainingHours,0) as RemainingHours,
	coalesce(b.PlannedRemainingHours,0) as PlannedRemainingHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0)) as EACHours,
	round((coalesce(b.ActualHours,0))*coalesce(ProjectBillingRate,0),2) as ActualRateTimesHours,
	(coalesce(b.RemainingHours,0))*coalesce(ProjectBillingRate,0) as RemainingRateTimesHours,
	(coalesce(b.PlannedRemainingHours,0))*coalesce(ProjectBillingRate,0) as PlannedRemainingRateTimesHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0))*coalesce(ProjectBillingRate,0) as EACRateTimesHours,
	coalesce(ProjectBillingRate,0)-EngagementCostRate as EngagementMarginRate,
	coalesce(ProjectBillingRate,0)-coalesce(StandardHourlyCostRate,0) as ResourceMarginRate,
	case when coalesce(ProjectBillingRate,0)=0 then 0 else (coalesce(ProjectBillingRate,0)-EngagementCostRate)/coalesce(ProjectBillingRate,0) end as 'EngagementRateMarginDecimal',
	case when coalesce(ProjectBillingRate,0)=0 then 0 else round((((coalesce(ProjectBillingRate,0)-EngagementCostRate)/coalesce(ProjectBillingRate,0))*100),2) end as 'EngagementRateMargin%',
	case when coalesce(ProjectBillingRate,0)=0 then 0 else (coalesce(ProjectBillingRate,0)-coalesce(StandardHourlyCostRate,0))/coalesce(ProjectBillingRate,0) end as 'ResourceRateMarginDecimal',
	case when coalesce(ProjectBillingRate,0)=0 then 0 else round((((coalesce(ProjectBillingRate,0)-coalesce(StandardHourlyCostRate,0))/coalesce(ProjectBillingRate,0))*100),2) end as 'ResourceRateMargin%',
	(PlannedMarginPercent*100) as 'PlannedMargin%'
from
	a
		join
	BG_ProjectDashboard_BillingRoleHours_CG b with (nolock) on a.ProjectId=b.ProjectId and a.ResourceId=b.ResourceId and a.BillingRoleId=b.BillingRole
),
r as (
select
	Engagement,
	EngagementId,
	ProjectId,
	Resource,
	ResourceId,
	TaskId,
	BillingRole,
	TimeDate,
	case when coalesce(ApprovalStatus, '')='A'
		 then sum(RegularHours+OvertimeHours)
		 else 0
	end as ApprovedBillableHours,
	case when coalesce(ApprovalStatus, '')<>'A'
		 then sum(RegularHours+OvertimeHours)
		 else 0
	end as UnapprovedBillableHours,
	sum(RegularHours+OvertimeHours) as BillableHours,
	case when coalesce(ApprovalStatus, '')='A'
		 then sum(round(coalesce(RateTimesHours,0),2))
		 else 0
	end as ApprovedRateTimesHours,
	case when coalesce(ApprovalStatus, '')<>'A'
		 then sum(round(coalesce(RateTimesHours,0),2))
		 else 0
	end as UnapprovedRateTimesHours,
	sum(round(coalesce(RateTimesHours,0),2)) as RateTimesHours,
	case when coalesce(ApprovalStatus, '')='A'
		 then sum(RevRec)
		 else 0
	end as ApprovedRevRec,
	case when coalesce(ApprovalStatus, '')<>'A'
		 then sum(RevRec)
		 else 0
	end as UnapprovedRevRec,
	sum(RevRec) as RevenueRecognized
from
	BG_Time_and_Writeoff_with_Effective_BillingRate_CG with (nolock)
	--select * from BG_Time_and_Writeoff_with_Effective_BillingRate_CG where ProjectId='A9356206-DC0F-4A6A-B695-D1A3D043A58F' and ResourceId='DC4F7711-48F7-4F24-BDFE-A3D187D134DA'
where
	coalesce(ApprovalStatus, '') <>'R'
	and Billable=1
	and (ADJUSTMENTTIMESTATUS not in ('A', 'P') OR ADJUSTMENTTIMESTATUS IS NULL)
		--AND  (tw.INVOICESTATUS = 1 OR tw.REVREC IS NOT NULL))
	--and EngagementId='8BBC144D-B895-4429-AA41-66E22ED0F5E0'
	--or ProjectId='7B818865-8410-4A31-8D71-D42A19A8ADF3'

group by
	Engagement,
	EngagementId,
	ProjectId,
	Resource,
	ResourceId,
	TaskId,
	BillingRole,
	TimeDate,
	ApprovalStatus

)

select
	b.*,
	n.NumberResourceRoles,
	r.TimeDate,
	case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end as ResourceMarginDiff,
	case when (case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end)>=0
				and (case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end)<=.03
		 then 'Yes'
		 else 'No'
	end as 'MarginWithInExpectedRange',
	coalesce(r.BillableHours,0) as twBillableHours,
	r.RateTimesHours,
	coalesce(r.RevenueRecognized,0) as RevenueRecognized,
	case when round(b.ActualRateTimesHours,0)=round(coalesce(r.RevenueRecognized,0),0) then 'Yes'
		 when round(b.ActualRateTimesHours,0)<round(coalesce(r.RevenueRecognized,0),0) then 'No'
		 else 'Revenue Recognized Less Than'
	end as RevRecMatches,
	case when coalesce(r.BillableHours,0)=0 then 0 else coalesce(r.RevenueRecognized,0)/coalesce(r.BillableHours,0) end as RevRecRate,
	ApprovedBillableHours,
	UnapprovedBillableHours,
	ApprovedRateTimesHours,
	UnapprovedRateTimesHours,
	ApprovedRevRec,
	UnapprovedRevRec
from
	b
		left outer join
	n on b.ProjectId=n.ProjectId and b.ResourceId=n.ResourceId
		left outer join
	r on b.ProjectId=r.ProjectId and b.ResourceId=r.ResourceId and b.BillingRoleId=r.BillingRole and r.TaskId=b.TaskId
--where
--	b.ProjectId='7B818865-8410-4A31-8D71-D42A19A8ADF3'

--(select 
--	*
--	--rr.HourlyBillRate 
--from 
--	ResourceRate rr 
--where 
--	rr.Active=1 
--	and rr.ResourceId='1AC30377-D2B3-41DA-9200-43482BEA461B'--r.ResourceId 
--	and rr.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where r2.ResourceId='1AC30377-D2B3-41DA-9200-43482BEA461B'))--rr.ResourceId=r2.ResourceId)) 



GO
