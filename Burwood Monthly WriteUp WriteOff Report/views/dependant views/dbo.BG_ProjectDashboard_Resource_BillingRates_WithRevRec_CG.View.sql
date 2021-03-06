USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_Resource_BillingRates_WithRevRec_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




--select * from [BG_ProjectDashboard_Resource_BillingRates_SAVE_CG] where Project='Rush University Medical Center - Cybersecurity Strategy'


--select top 100 * from BG_ProjectDashboard_CustomFields_CG

--select * from BG_ProjectDashboard_Resource_BillingRates_CG where ResourceId='1F6CCEC7-64F1-4AB8-9375-830E064C9033'

--select count(*) from [BG_ProjectDashboard_Resource_BillingRates_WithRevRec_CG]

CREATE VIEW [dbo].[BG_ProjectDashboard_Resource_BillingRates_WithRevRec_CG] AS


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
--	p.Name in ('Rush University Medical Center - Cybersecurity Strategy', 'Wahl Power BI Phase 2')
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
	BG_ProjectDashboard_BillingRoleHours_CG b with (nolock) on a.ProjectId=b.ProjectId and a.ResourceId=b.ResourceId and a.BillingRoleId=b.BillingRole
),
r as (
select
	Engagement,
	EngagementId,
	ProjectId,
	Resource,
	ResourceId,
	BillingRole,
	sum(RegularHours+OvertimeHours) as BillableHours,
	sum(RateTimesHours) as RateTimesHours,
	sum(RevRec) as RevenueRecognized
from
	BG_Time_and_Writeoff_with_Effective_BillingRate_CG
where
	ApprovalStatus='A'
	--and EngagementId='8BBC144D-B895-4429-AA41-66E22ED0F5E0'
	--or ProjectId='7B818865-8410-4A31-8D71-D42A19A8ADF3'

group by
	Engagement,
	EngagementId,
	ProjectId,
	Resource,
	ResourceId,
	BillingRole
)

select
	b.*,
	case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end as ResourceMarginDiff,
	case when (case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end)>=0
				and (case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end)<=.03
		 then 'Yes'
		 else 'No'
	end as 'MarginWithInExpectedRange',
	r.RateTimesHours,
	r.RevenueRecognized
from
	b
		left outer join
	r on b.ProjectId=r.ProjectId and b.ResourceId=r.ResourceId and b.BillingRoleId=r.BillingRole
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
