USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectsCreatedOnByAEandPM_CG]    Script Date: 10/14/2019 4:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[BG_ProjectsCreatedOnByAEandPM_CG] as 
select
	case when b.Description in ('SL-St. Louis', 'PE-Peoria', 'QC-Quad Cities') then 'EA-Eastern Region'
		 else b.Description 
	end as Region,
	c.Name as Customer,
	--c.CustomerId,
	e.Name as Engagement,
	p.Name as Project,
	ae.AccountExecutive,
	mmr.Name as PM,
	coalesce(e.ContractAmount,0) as ContractAmount,
	coalesce(p.LabourBudget,0) as LaborBudget,
	coalesce(e.RevRec,0) as RevRec,
	e.ContractAmount-coalesce(e.RevRec,0) as ContractRemaining,
	ps.Description as Status,
	
	e.CreatedOn,
	convert(date, p.ActualStart) as ActualStart,
	convert(date, p.ActualFinish) as ActualFinishDate
from
	dbo.Engagement e with (nolock)
		join
	dbo.Customer c with (nolock) on e.CustomerId=c.CustomerId
		join
	dbo.Project p with (nolock) on e.EngagementId=p.EngagementId
		join
	dbo.ProjectStatus ps with (nolock) on p.ProjectStatus=ps.Code
		left outer join
	dbo.managemember mm WITH (NOLOCK) ON mm.CustomerId = p.CustomerId and mm.EngagementId=p.EngagementId and mm.ProjectId=p.ProjectId 
		left outer join 
	dbo.Resources as mmr WITH (NOLOCK) ON mm.resourceid=mmr.resourceid
		left outer join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	(select u.EntityId as ProjectId, r.Name as AccountExecutive from UDFCode u with (nolock) join Resources r with (nolock) on u.UDFCode=r.ResourceId where ItemName='ProjectCode4 ') ae on ae.ProjectId=p.ProjectId
where 
	e.Name not like '%promo%'
	and c.Name <> '.Burwood Internal Expenses'
	and b.Description<>'LA-LATAM Region'
	and c.CustomerId <>'3E09B148-69D8-4023-9F75-2AF9852D753E'

--order by
--	c.Name

GO
