USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ResourceWeeklyScheduleAcknowledgeDetailThisPeriodForward_PWApps]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





--select distinct ResourceName, Resource from [BG_ResourceWeeklyScheduleAcknowledgeDetail_PWApps]


create view [dbo].[BG_ResourceWeeklyScheduleAcknowledgeDetailThisPeriodForward_PWApps] as 

select
	rtrim(r.FirstName)+' '+rtrim(r.LastName) as ResourceName,
	f.ResourceId,
	r.Name as Resource,
	convert(date, f.PeriodStartDate) as PeriodStartDate,
	convert(date, f.PeriodEndDate) as PeriodEndDate,
	f.ProjectName as Project,
	f.TaskName as Task,
	convert(numeric(38,2), f.PlannedHours) as PlannedHours,
	convert(numeric(38,2), f.PlannedHours) as UpdatedHours,
	convert(varchar(200), NULL) as Comments,
	convert(varchar(20), 'No') as Acknowledge,
	convert(varchar(20), NULL) as Status,
	pm.ProjectManager,
	pm.EmailAddress as PMemail,
	m.Name as Manager,
	me.EmailAddress as ManagerEmail
from
	BG_ForecastWeeklyBillableSchedule_withRequests_VIEW f
		join
	Resources r with (nolock) on f.ResourceId=r.ResourceId
		left outer join
	Project p with (nolock) on f.ProjectName=p.Name
		left outer join
	BG_ProjectManager_CG pm with (nolock) on p.ProjectId=pm.ProjectId
		left outer join
	Resources m with (nolock) on r.ReportsTo=m.ResourceId
		left outer join
	ResourceAddress me with (nolock) on m.ResourceId=me.ResourceId
		join
	ResourcePayroll rp with (nolock) on r.ResourceId=rp.ResourceId --and rp.CertificationHours>0
where
	Convert(date, f.PeriodStartDate)>=convert(date, DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE()))
	and f.ProjectName is not NULL
	and r.EmployeeType<>'CO'
	and r.TerminationDate is NULL
	and (rp.CertificationHours>0 or r.Name in ('Walder, Maggie', 'Kerstetter, Edward'))


union all

SELECT 
	r.FirstName+' '+r.LastName as ResourceName,
	f.ResourceId,
	r.Name as Resource,
	convert(date, f.PeriodStartDate) as PeriodStartDate,
	convert(date, f.PeriodEndDate) as PeriodEndDate,
	f.Type as Project,
	f.TimeDescription,
	f.Hours,
	convert(numeric(38,2), f.Hours) as UpdatedHours,
	convert(varchar(200), NULL) as Comments,
	convert(varchar(20), 'No') as Acknowledge,
	convert(varchar(20), NULL) as Status,
	m.Name as ProjectManager,
	a.EmailAddress,
	m.Name as ProjectManager,
	a.EmailAddress
  
FROM 
	[Changepoint].[dbo].[BG_NonProject_Time_CG] f with (Nolock)
		join
	Resources r with (nolock) on f.ResourceId=r.ResourceId
		left outer join
	Resources m with (nolock) on r.ReportsTo=m.ResourceId
		left outer join
	ResourceAddress a with (nolock) on m.ResourceId=a.ResourceId
		join
	ResourcePayroll rp with (nolock) on r.ResourceId=rp.ResourceId --and rp.CertificationHours>0
where
	Convert(date, PeriodStartDate)>=convert(date, DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE()))
	and r.EmployeeType<>'CO'
	and r.TerminationDate is NULL
	and (rp.CertificationHours>0 or r.Name in ('Walder, Maggie', 'Kerstetter, Edward'))


	




GO
