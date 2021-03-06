USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_Invoices2018_CG]    Script Date: 10/14/2019 11:47:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




--select * from BG_ProjectDashboard_Invoices_CG where Project like 'Memorial Health System Cisco ISE' and (Status='Unpaid' or Paid='Unpaid')


/****** Object:  View dbo.BG_InvoicesByProject_VIEW    Script Date: 6/20/2007 1:07:01 PM ******/
CREATE VIEW [dbo].[BG_ProjectDashboard_Invoices2018_CG] AS 
with a as (
SELECT 
	e.Name as Engagement,
	e.ContractAmount as POContractAmount,
	e.BillingType,
	p.Name as Project,
	p.ProjectId,
	p.EngagementId,
	p.ExpenseBudget
FROM         
	dbo.Project p WITH (nolock)
		join
	Engagement e with (nolock) on p.EngagementId=e.EngagementId
		
WHERE 
	p.Deleted = 0
	and e.CustomerId<>'D6FCCBED-6B49-4914-BA89-9CB554DB1165'
),
i as (
select 
	i.EngagementID,
	i.InvoiceID  ,
	coalesce(i.DisplayInvoiceID, 'No Invoice to Display') as Invoice, 
	i.InvoiceDate, 
	i.InvoiceTotal, 
	CASE WHEN i.status='X' 
				THEN 'Archived' 
			WHEN i.status='CR' 
				THEN 'Credited' 
			WHEN i.status='DC' 
				THEN 'Discarded' 
			WHEN i.status='P2A' 
				THEN 'Pending Second Approval' 
			WHEN i.status='P' 
				THEN 'Paid' 
			WHEN i.status='A' 
				THEN 'Approved' 
			WHEN i.status='S'
				THEN 'Sent' 
			WHEN i.status='C' 
				THEN 'Committed' 
			WHEN i.status='D' 
				THEN 'Draft' 
			WHEN i.status='PA' 
				THEN 'Pending Approval' 
			ELSE 'Partially Paid'  
	END AS InvoiceStatus,   
	--i.Status,
	ists.Description as Status,
	--i.Paid as PaidStatus,
	case when coalesce(i.Paid,0)=1
		 then 'Paid'
		 when i.DisplayInvoiceID is null
		 then 'No Invoice to Display'
		 else 'Unpaid'
	end as Paid,
	(( coalesce(i.TimeTotal,  0) ) + ( coalesce(i.TimeTotalAdj,  0) ) + ( coalesce(i.WOTimeTotal,  0) )) AS Hourly_Time, 
	(( coalesce(i.ExpenseTotal,  0) ) + ( coalesce(i.ExpenseTotalAdj,  0) ) + ( coalesce(i.WOExpenseTotal,  0) )) AS Expenses, 
	(( coalesce(i.SupportTotal,  0) ) + ( coalesce(i.SupportTotalAdj,  0) ) + ( coalesce(i.WOSupportTotal,  0) )) AS Requests,
	(( coalesce(i.ProductTotal,  0) ) + ( coalesce(i.ProductTotalAdj,  0) ) + ( coalesce(i.WOProductTotal,  0) )) AS Products,
	i.Description, 
	i.FixedFeeTotal, 
	i.WOTimeTotal, 
	i.PaymentDueDate
from dbo.Invoice i WITH (nolock) 
		JOIN  
	dbo.InvoiceFormats im  WITH (nolock) ON i.InvoiceFormatId = im.InvoiceFormatId
		join
	InvoiceStatus ists with (nolock) on i.Status=ists.Code ---i ON p.EngagementId = i.EngagementId
)
select
	a.Engagement,
	a.POContractAmount,
	a.BillingType,
	a.Project,
	a.ProjectId,
	a.ExpenseBudget,
	i.*
from
	a
		left outer join
	i on a.EngagementId=i.EngagementId



GO
