USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectManager_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [dbo].[BG_ProjectManager_CG] as
select
	r.Description as Region,
	cc.Name as Practice,
	p.EngagementId,
	p.ProjectId,
	pm.ResourceId,
	p.Name as Project,
	pm.Name as ProjectManager,
	ra.EmailAddress,
	p.ProjectStatus,
	convert(date, d.UDFDate) as EngagementCloseDate
from
	Project p with (nolock) 
		join
	Engagement e with (nolock) on p.EngagementId=e.EngagementId
		join
	BillingOffice r with (nolock) on e.BillingOfficeId=r.BillingOfficeId
		left outer JOIN 
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		join
	dbo.managemember mm WITH (NOLOCK) ON mm.CustomerId = p.CustomerId AND mm.EngagementId=p.EngagementId AND mm.ProjectId=p.ProjectId 
		join
	dbo.Resources AS pm WITH (NOLOCK) ON mm.resourceid=pm.resourceid
		join
	dbo.ResourceAddress ra with (Nolock) on pm.ResourceId=ra.ResourceId
		left outer join 
	UDFDate d with (nolock) on p.EngagementId=d.EntityId and d.ItemName='EngagementText1'



GO
