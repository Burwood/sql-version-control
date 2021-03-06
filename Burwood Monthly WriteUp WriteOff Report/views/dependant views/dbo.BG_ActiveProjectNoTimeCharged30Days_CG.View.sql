USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ActiveProjectNoTimeCharged30Days_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[BG_ActiveProjectNoTimeCharged30Days_CG] as
SELECT 
	p.Region,
	p.ProjectManager, 
	p.ProjectName as Project, 
	p.CustomerName as Customer, 
	p.EngagementName as Engagement, 
	bt.Description as BillingType,
	pd.RemainingContractAmount,
	convert(date, t.LastDate) as LastDateTimeWasCharged, 
	convert(date, p.BaselineFinish) BaselineFinish, 
	convert(date, p.PlannedFinish) PlannedFinish, 
	convert(date, p.RollupForecastFinish) ForecastFinish,
	convert(nvarchar(2048), p.ProjectDescription) as ProjectDescription,
	p.ProjectManagerid, 
	p.ProjectId, 
	p.CustomerId, 
	p.EngagementId, 
	c.ProjectCostCenter, 
	convert(date, t.LastDate30) LastDate30
	
FROM 
	BG_LastTimeChargedToProject_VIEW t
		INNER JOIN 

	(SELECT b.Description as Region, 
			p.deleted,  
			p.Billable,  
			p.name AS 'ProjectName',  
			P.projectstatus AS 'ProjectStatusCode',  
			p.BaselineFinish,  
			p.EngagementId,  
			p.ProjectId,  
			p.rollupforecastfinish,  
			p.CustomerId,  
			cast(p.Description as nvarchar(2048)) AS 'ProjectDescription',  
			mmr.name AS 'ProjectManager',  
			pcu.name AS 'CustomerName', 
			mm.resourceid AS 'ProjectManagerid',  
			e.name AS 'EngagementName', 
			e.BillingType, 
			p.PlannedFinish FROM project AS p  WITH (NOLOCK)  
		INNER JOIN 
	Customer AS pcu  WITH (NOLOCK) ON p.customerid=pcu.customerid 
		INNER JOIN 
	Engagement AS e  WITH (NOLOCK) ON p.engagementid=e.engagementid and p.customerid = e.customerid 
		join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		LEFT OUTER JOIN 
	managemember AS mm  WITH (NOLOCK) ON mm.CustomerId = p.CustomerId and mm.EngagementId=p.EngagementId and mm.ProjectId=p.ProjectId 
		LEFT OUTER JOIN 
	resources AS mmr  WITH (NOLOCK) ON mmr.resourceid=mm.resourceid ) AS p ON t.Projectid=p.ProjectId 
		INNER JOIN 
	BG_ProjectCostCenter_VIEW c ON t.Projectid=c.ProjectId 
		left outer join
	BillingType bt with (nolock) on p.BillingType=bt.Code
		left outer join
	BG_ProjectDashboard_Engagement_CG pd with (nolock) on p.ProjectId=pd.ProjectId
WHERE 
	(( p.BILLABLE = 1  )  
	AND ( p.DELETED = 0  )  
	AND ( p.PROJECTSTATUSCODE = 'A'  )  
	AND convert(date, t.LASTDATE30) < getdate())


GO
