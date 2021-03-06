USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_AdjustmentsByType_byEngagement_CG]    Script Date: 9/30/2019 5:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[BG_ProjectDashboard_AdjustmentsByType_byEngagement_CG] as 
with e as (
select
	Name as Engagement,
	EngagementId,
	EngagementStatus,
	convert(date, d.UDFDate) as CloseDate
from
	Engagement with (nolock)
		left outer join 
	UDFDate d with (nolock) on Engagement.EngagementId=d.EntityId and d.ItemName='EngagementText1'
),
ap as (
SELECT 
	r.EngagementId,
	a.Description as AdjustmentType,
	-sum(r.RevenueAmount) as 'Adjustment to Close a Project'
FROM 
	[Changepoint].[dbo].[RevenueDetail] r with (nolock)
		join
	RevRecAdjCodes a with (nolock) on r.ReasonCode=a.RRARCID
where
	a.Description='Adjustment to Close a Project'
group by
	r.EngagementId,
	a.Description
),
cm as (
SELECT 
	r.EngagementId,
	a.Description as AdjustmentType,
	-sum(r.RevenueAmount) as 'Contractor Margin Adjustment'
FROM 
	[Changepoint].[dbo].[RevenueDetail] r with (nolock)
		join
	RevRecAdjCodes a with (nolock) on r.ReasonCode=a.RRARCID
where
	a.Description='Contractor Margin'
group by
	r.EngagementId,
	a.Description
),
cp as (
SELECT 
	r.EngagementId,
	a.Description as AdjustmentType,
	-sum(r.RevenueAmount) as 'Contractor Pass-through Adjustment'
FROM 
	[Changepoint].[dbo].[RevenueDetail] r with (nolock)
		join
	RevRecAdjCodes a with (nolock) on r.ReasonCode=a.RRARCID
where
	a.Description='Contractor Pass-through'
group by
	r.EngagementId,
	a.Description
),
er as (
SELECT 
	r.EngagementId,
	a.Description as AdjustmentType,
	-sum(r.RevenueAmount) as 'Expense Recognition Adjustment'
FROM 
	[Changepoint].[dbo].[RevenueDetail] r with (nolock)
		join
	RevRecAdjCodes a with (nolock) on r.ReasonCode=a.RRARCID
where
	a.Description='Expense Recognition'
group by
	r.EngagementId,
	a.Description
),	
oa as (
SELECT 
	r.EngagementId,
	a.Description as AdjustmentType,
	-sum(r.RevenueAmount) as 'Other Adjustment'
FROM 
	[Changepoint].[dbo].[RevenueDetail] r with (nolock)
		join
	RevRecAdjCodes a with (nolock) on r.ReasonCode=a.RRARCID
where
	a.Description='Other Adjustment'
group by
	r.EngagementId,
	a.Description
)
,
alladj as (
SELECT 
	r.EngagementId,
	'All Adjustments' as AdjustmentType,
	-sum(r.RevenueAmount) as 'Total Adjustments'
FROM 
	[Changepoint].[dbo].[RevenueDetail] r with (nolock)
		join
	RevRecAdjCodes a with (nolock) on r.ReasonCode=a.RRARCID
where
	a.Description in ('Adjustment to Close a Project', 'Contractor Margin', 'Contractor Pass-through', 'Expense Recognition Adjustment', 'Other Adjustment')
group by
	r.EngagementId
)
select
	e.Engagement,
	e.EngagementStatus,
	e.CloseDate,
	e.EngagementId,
	coalesce(ap.[Adjustment to Close a Project],0) as [Adjustment to Close a Project],
	coalesce(cm.[Contractor Margin Adjustment],0) as [Contractor Margin Adjustment],
	coalesce(cp.[Contractor Pass-through Adjustment],0) as [Contractor Pass-through Adjustment],
	coalesce(er.[Expense Recognition Adjustment],0) as [Expense Recognition Adjustment],
	coalesce(oa.[Other Adjustment],0) as [Other Adjustment],
	coalesce(alladj.[Total Adjustments],0) as [Total Adjustments]
from
	e
		left outer join
	ap on e.EngagementId=ap.EngagementId
		left outer join
	cm on e.EngagementId=cm.EngagementId
		left outer join
	cp on e.EngagementId=cp.EngagementId
		left outer join
	er on e.EngagementId=er.EngagementId
		left outer join
	oa on e.EngagementId=oa.EngagementId
		left outer join
	alladj on e.EngagementId=alladj.EngagementId
--where 
--	e.EngagementStatus='W'
--	and e.EngagementId='8DE35660-C29A-449C-A593-0D0B0341E400'


--	select * from Project where EngagementId='8DE35660-C29A-449C-A593-0D0B0341E400'

GO
