USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_Time_and_WriteOff_Category_CG]    Script Date: 10/14/2019 3:40:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO






--select * from BG_Time_and_WriteOff_Category_CG


CREATE VIEW [dbo].[BG_Time_and_WriteOff_Category_CG] AS


SELECT 
e.EngagementId, 
c.CustomerId, 
b.BillingOfficeId, 
tw.ProjectCostCenter, 
e.Name as Engagement, 
c.Name as Customer, 
b.Description as BillingOffice, 
r.Name as Resource,
tw.AdjustmentReasonCode,
cast(tw.TimeDate as date) as TimeDate,
year(tw.TimeDate) as TimeYear,
month(tw.TimeDate) as TimeMonth,
datename(month, tw.TimeDate) as TimeMonthName,
coalesce(tw.RateTimesHours,0) as PotentialFees,
coalesce(tw.RevRec,0) as RevenueRecognized,
-(coalesce(tw.AmountWrittenOff,0)) AS AmountWrittenOff, 
case when tw.AdjustmentReasonCode IS NULL or tw.AdjustmentReasonCode = 'Adjustment to Close a Project'
	 then (coalesce(tw.RateTimesHours,0)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS FixedFeeOverage, 
case when tw.AdjustmentReasonCode = 'Contractor Pass-through'
	 then (coalesce(tw.RateTimesHours,0)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Contractor, 
case when tw.AdjustmentReasonCode = 'Expense Recognition'
	 then (coalesce(tw.RateTimesHours,0)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Expenses, 
case when tw.AdjustmentReasonCode = 'Other Adjustment'
	 then (coalesce(tw.RateTimesHours,0)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Other, 
---*-(coalesce(tw.RateTimesHours,0) - coalesce(tw.RevRec,0) + coalesce(tw.AmountWrittenOff,0)) AS TotalWriteUpWriteOff,
(-(( ISNULL(tw.RateTimesHours,  0) )- ( ISNULL(tw.RevRec,  0) )) + ( ISNULL(tw.AmountWrittenOff,  0) )) AS TotalWriteUpWriteOff
FROM 
	BG_Time_and_WriteOff_VIEW  tw with (nolock)
		INNER JOIN 
	Customer c with (nolock) ON tw.CustomerId=c.CustomerId 
		INNER JOIN 
	Engagement e with (nolock) on tw.EngagementId=e.EngagementId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		LEFT OUTER JOIN 
	BillingOffice AS b  WITH (NOLOCK) ON b.BillingOfficeId = e.BillingOfficeId
		INNER JOIN 
	Resources r with (nolock) on tw.ResourceId=r.ResourceId 
		left outer join 
	EngRequestBillingRule er with (nolock) on tw.EngagementId=er.EngagementId and er.RequestType='TM'
WHERE e.Name IS NOT NULL 
AND e.Name IS NOT NULL  
AND tw.TimeDate IS NOT NULL  
AND (( tw.BILLABLE = 1  )  AND  ( (- ( ISNULL(tw.AMOUNTWRITTENOFF,  0) ))  != 0  OR (( ISNULL(tw.RATETIMESHOURS,  0) )  -  ( ISNULL(tw.REVREC,  0) ))  != 0  )) 
AND tw.TimeDate IS NOT NULL  
and tw.TimeDate>='20130101'
and er.EngRequestBillingRuleId is NULL
--and tw.BatchNumber <> 'PPC Recognition'
--order by e.Name 












GO
