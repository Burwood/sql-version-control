USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ResourceWeeklyScheduleAcknowledgeDetail_PWApps]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






--select count(*) from [BG_ResourceWeeklyScheduleAcknowledgeDetail_PWApps]


CREATE view [dbo].[BG_ResourceWeeklyScheduleAcknowledgeDetail_PWApps] as 
with rsc as (
select
	distinct
	w.Workgroup,
	rtrim(r.FirstName)+' '+rtrim(r.LastName) as ResourceName,
	r.ResourceId,
	r.Name as Resource,
	convert(date, DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE())) as PeriodStartDate,
	DATEADD(DAY, 7, (convert(date, DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE())))) as PeriodEndDate,
	coalesce(p.Project, 'No Projects in Forecast for Current Period') as Project,
	'No Tasks in Forecast for Current Period' as Task,
	convert(numeric(38,2), 0) as PlannedHours,
	convert(numeric(38,2), 0) as UpdatedHours,
	convert(varchar(200), NULL) as Comments,
	convert(varchar(20), 'No') as Acknowledge,
	convert(varchar(20), NULL) as Status,
	m.Name as ProjectManager,
	ma.EmailAddress as PMemail,
	m.Name as Manager,
	ma.EmailAddress as ManagerEmail
from
	Resources r with (nolock)
		left outer join
	Resources m with (nolock) on r.ReportsTo=m.ResourceId
		left outer join
	ResourceAddress a with (nolock) on m.ResourceId=a.ResourceId
		left outer join
	ResourceAddress ma with (nolock) on m.ResourceId=ma.ResourceId
		join
	ResourcePayroll rp with (nolock) on r.ResourceId=rp.ResourceId 
		left outer join
	[BG_ResourceCurrentWorkgroup_Forecast_CG] w with (nolock) on r.ResourceId=w.ResourceId
		left outer join
	(select distinct ta.ResourceId, p.Name as Project from	TaskAssignment ta with (nolock)
																join
															Project p with (nolock) on ta.ProjectId=p.ProjectId and p.ProjectStatus<>'C'
													   where ta.Deleted=0)
		as p on r.ResourceId=p.ResourceId
where
	r.EmployeeType<>'CO'
	and r.TerminationDate is NULL
	and (rp.CertificationHours>0 or r.Name in ('Walder, Maggie', 'Kerstetter, Edward', 'Poczatek, Ellie'))
	and w.Workgroup is not null
),
a as (
select
	w.Workgroup,
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
		left outer join
	[BG_ResourceCurrentWorkgroup_Forecast_CG] w with (nolock) on f.ResourceId=w.ResourceId
where
	Convert(date, f.PeriodStartDate)=convert(date, DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE()))
	and f.ProjectName is not NULL
	and r.EmployeeType<>'CO'
	and r.TerminationDate is NULL
	and (rp.CertificationHours>0 or r.Name in ('Walder, Maggie', 'Kerstetter, Edward', 'Poczatek, Ellie'))


union all

SELECT 
	w.Workgroup,
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
		left outer join
	[BG_ResourceCurrentWorkgroup_Forecast_CG] w with (nolock) on f.ResourceId=w.ResourceId
where
	Convert(date, PeriodStartDate)=convert(date, DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE()))
	and r.EmployeeType<>'CO'
	and r.TerminationDate is NULL
	and (rp.CertificationHours>0 or r.Name in ('Walder, Maggie', 'Kerstetter, Edward', 'Poczatek, Ellie'))
)

select
	'Existing Forecast for Current Period' as Type,
	a.Workgroup,
	a.ResourceName,
	a.ResourceId,
	a.Resource,
	a.PeriodStartDate,
	a.PeriodEndDate,
	a.Project,
	a.Task,
	a.PlannedHours,
	a.UpdatedHours,
	a.Comments,
	a.Acknowledge,
	a.Status,
	a.ProjectManager,
	a.PMemail,
	a.Manager,
	a.ManagerEmail
from
	a
	--order by a.Workgroup
union all

select
	'No Forecast for Current Period' as Type,
	rsc.Workgroup,
	rsc.ResourceName,
	rsc.ResourceId,
	rsc.Resource,
	rsc.PeriodStartDate,
	rsc.PeriodEndDate,
	rsc.Project,
	rsc.Task,
	rsc.PlannedHours,
	rsc.UpdatedHours,
	rsc.Comments,
	rsc.Acknowledge,
	rsc.Status,
	rsc.ProjectManager,
	rsc.PMemail,
	rsc.Manager,
	rsc.ManagerEmail
from
	rsc
where
	rsc.Resource not in (select distinct Resource from a)
	




GO
