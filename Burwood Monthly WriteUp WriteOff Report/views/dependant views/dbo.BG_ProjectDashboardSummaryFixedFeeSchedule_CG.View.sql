USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboardSummaryFixedFeeSchedule_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [dbo].[BG_ProjectDashboardSummaryFixedFeeSchedule_CG] as 
--with a as (
select
	--'Burwood Group Inc.' as Company,
	p.*,
	case when coalesce(f.Billed,0)=1 then 'Yes' else 'No' end as Billed,
	f.DoNotInvoice,
	f.Deliverable,
	f.BillingDate,
	coalesce(f.BillingAmount,0) as BillingAmount,
	f.InvoicedAmount,
	f.TotalHours,
	f.RevPrev,
	f.RevPrevDate,
	f.RevRec,
	f.RevRecDate,
	f.RevAdj,
	f.FFSort,
	f.CreatedOn
from
	BG_ProjectDashboardSummaryScheduled_CG p with (nolock)
		join
	BG_ProjectDashboard_FixedFeeSchedule_CG f with (nolock) on p.ProjectId=f.ProjectId and f.FFSort<>1
where
	p.ProjectStatus<>'C'
	--and p.Project='Akorn Pharmaceuticals- Network Services Staff Augmentation October 2017 (Stephen Lotho)'--'LACCD-UC District Wide Design and Oversight'



GO
