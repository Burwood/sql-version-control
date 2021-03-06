USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_Time_and_WriteOff_Category_withEngStatus_CG]    Script Date: 10/11/2019 2:02:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











--select * from [BG_Time_and_WriteOff_Category_withEngStatus_CG] where Engagement='Adtalem- Telepresence Cluster Merge Updates' and TimeYear=2018 and TimeMonth=9


--select * from [BG_Time_and_WriteOff_Category_withEngStatus_CG] where Contractor<>0 or Expenses<>0 or Other<>0




CREATE VIEW [dbo].[BG_Time_and_WriteOff_Category_withEngStatus_CG] AS


SELECT 
e.EngagementId, 
e.OpportunityId,
es.Description as EngagementStatus,
c.CustomerId, 
b.BillingOfficeId, 
tw.ProjectCostCenter, 
e.Name as Engagement, 
e.BillingType,
c.Name as Customer, 
b.Description as BillingOffice, 
r.Name as Resource,
tw.AdjustmentReasonCode,
tw.AdjustmentTimeStatus,
tw.AdjustmentTimeParent,
--d.UDFDate as CloseDate,
cast(tw.TimeDate as date) as TimeDate,
year(tw.TimeDate) as TimeYear,
month(tw.TimeDate) as TimeMonth,
datename(month, tw.TimeDate) as TimeMonthName,
tw.RegularHours+tw.OvertimeHours as RegularHours,
-(coalesce(tw.AmountWrittenOff,0)) AS AmountWrittenOff, 

round(coalesce(tw.RateTimesHours,0),2) as RateTimesHours,


--round(coalesce(tw.RateTimesHours,0),2) as PotentialFeesOrg,
case when tw.AdjustmentReasonCode is not null
	 then round(0,2)
	 when tw.AdjustmentReasonCode IS NULL 
		  and coalesce(tw.RevRec,0)<>0 
		  and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
	 then coalesce(tw.RevRec,0)
	 else round(coalesce(tw.RateTimesHours,0),2)
	 --else 0
end as PotentialFees,--New,

coalesce(tw.RevRec,0) as RevenueRecognized,

case when tw.AdjustmentReasonCode IS NULL
	 then (case when tw.AdjustmentReasonCode is not null
				then round(0,2)
				when tw.AdjustmentReasonCode IS NULL 
					and coalesce(tw.RevRec,0)<>0 
					and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
				then coalesce(tw.RevRec,0)
				else round(coalesce(tw.RateTimesHours,0),2)
			end) 
		- (coalesce(tw.RevRec,0)) 
	 else 0
end AS FixedFeeOverage, 
case when tw.AdjustmentReasonCode IS NULL or tw.AdjustmentReasonCode = 'Adjustment to Close a Project'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS OldFixedFeeOverage, 
case when tw.AdjustmentReasonCode = 'Adjustment to Close a Project'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS AdjustmenttoCloseProject,
case when tw.AdjustmentReasonCode = 'Contractor Pass-through'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS ContractorPassThrough,
case when tw.AdjustmentReasonCode = 'Contractor Margin'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS ContractorMargin,  
case when tw.AdjustmentReasonCode = 'Expense Recognition'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Expenses, 
case when tw.AdjustmentReasonCode = 'Other Adjustment'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Other, 
---*-(round(coalesce(tw.RateTimesHours,0),2) - coalesce(tw.RevRec,0) + coalesce(tw.AmountWrittenOff,0)) AS TotalWriteUpWriteOff,
(-(( round(coalesce(tw.RateTimesHours,0),2) )- ( ISNULL(tw.RevRec,  0) )) + ( ISNULL(tw.AmountWrittenOff,  0) )) AS OldTotalWriteUpWriteOff,
(-((case when tw.AdjustmentReasonCode is not null
		 then round(0,2)
		 when tw.AdjustmentReasonCode IS NULL 
				and coalesce(tw.RevRec,0)<>0 
				and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
		 then coalesce(tw.RevRec,0)
		 else round(coalesce(tw.RateTimesHours,0),2)
	end)
	- ( coalesce(tw.RevRec,0) )) + ( ISNULL(tw.AmountWrittenOff,  0) )) AS TotalWriteUpWriteOff
FROM 
	[BG_Time_and_Writeoff_with_Effective_BillingRate_CG]  tw with (nolock)
		left outer  JOIN 
	Customer c with (nolock) ON tw.CustomerId=c.CustomerId 
		left outer JOIN 
	Engagement e with (nolock) on tw.EngagementId=e.EngagementId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		LEFT OUTER JOIN 
	BillingOffice AS b  WITH (NOLOCK) ON b.BillingOfficeId = e.BillingOfficeId
		INNER JOIN 
	Resources r with (nolock) on tw.ResourceId=r.ResourceId 
		left outer join 
	EngRequestBillingRule er with (nolock) on tw.EngagementId=er.EngagementId and er.RequestType='TM'
		left outer join
	EngagementStatus es with (nolock) on e.EngagementStatus=es.Code
		left outer join 
	UDFDate d with (nolock) on e.EngagementId=d.EntityId and d.ItemName='EngagementText1'
WHERE 
	e.Name IS NOT NULL 
	and e.Deleted=0
	AND tw.TimeDate IS NOT NULL  
	and tw.Billable=1
	--AND (( tw.BILLABLE = 1  )  AND  ( (- ( ISNULL(tw.AMOUNTWRITTENOFF,  0) ))  != 0  OR (( ISNULL(tw.RATETIMESHOURS,  0) )  -  ( ISNULL(tw.REVREC,  0) ))  != 0  )) 
	and tw.ApprovalStatus='A' 
	and(tw.AdjustmentTimeStatus <> 'A' OR tw.AdjustmentTimeStatus is null)
	and tw.TimeDate>='20130101'
	and er.EngRequestBillingRuleId is NULL
	and e.BillingType<>'H'
	and d.UDFDate is NULL
	and tw.EngagementId not in ('9F24B4FB-212C-4359-87E5-DA52BB6F61F6', '4B009190-F3AC-41FA-9474-FF3A050001BB')

union all

SELECT 
e.EngagementId, 
e.OpportunityId,
es.Description as EngagementStatus,
c.CustomerId, 
b.BillingOfficeId, 
tw.ProjectCostCenter, 
e.Name as Engagement, 
e.BillingType,
c.Name as Customer, 
b.Description as BillingOffice, 
r.Name as Resource,
tw.AdjustmentReasonCode,
tw.AdjustmentTimeStatus,
tw.AdjustmentTimeParent,
--d.UDFDate as CloseDate,
cast(d.UDFDate as date) as TimeDate,
year(d.UDFDate) as TimeYear,
month(d.UDFDate) as TimeMonth,
datename(month, d.UDFDate) as TimeMonthName,
tw.RegularHours+tw.OvertimeHours as RegularHours,
-(coalesce(tw.AmountWrittenOff,0)) AS AmountWrittenOff, 
round(coalesce(tw.RateTimesHours,0),2) as RateTimesHours,
case when tw.AdjustmentReasonCode is not null
	 then round(0,2)
	 when tw.AdjustmentReasonCode IS NULL 
		  and coalesce(tw.RevRec,0)<>0 
		  and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
	 then coalesce(tw.RevRec,0)
	 else round(coalesce(tw.RateTimesHours,0),2)
end as PotentialFees,

coalesce(tw.RevRec,0) as RevenueRecognized,

case when tw.AdjustmentReasonCode IS NULL
	 then (case when tw.AdjustmentReasonCode is not null
				then round(0,2)
				when tw.AdjustmentReasonCode IS NULL 
					and coalesce(tw.RevRec,0)<>0 
					and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
				then coalesce(tw.RevRec,0)
				else round(coalesce(tw.RateTimesHours,0),2)
			end) 
		- (coalesce(tw.RevRec,0)) 
	 else 0
end AS FixedFeeOverage, 
case when tw.AdjustmentReasonCode IS NULL or tw.AdjustmentReasonCode = 'Adjustment to Close a Project'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS OldFixedFeeOverage, 
case when tw.AdjustmentReasonCode = 'Adjustment to Close a Project'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS AdjustmenttoCloseProject,
case when tw.AdjustmentReasonCode = 'Contractor Pass-through'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS ContractorPassThrough,
case when tw.AdjustmentReasonCode = 'Contractor Margin'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS ContractorMargin,  
case when tw.AdjustmentReasonCode = 'Expense Recognition'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Expenses, 
case when tw.AdjustmentReasonCode = 'Other Adjustment'
	 then (round(coalesce(tw.RateTimesHours,0),2)) - (coalesce(tw.RevRec,0)) 
	 else 0
end AS Other, 
(-(( round(coalesce(tw.RateTimesHours,0),2) )- ( ISNULL(tw.RevRec,  0) )) + ( ISNULL(tw.AmountWrittenOff,  0) )) AS OldTotalWriteUpWriteOff,

(-((case when tw.AdjustmentReasonCode is not null
		 then round(0,2)
		 when tw.AdjustmentReasonCode IS NULL 
				and coalesce(tw.RevRec,0)<>0 
				and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
		 then coalesce(tw.RevRec,0)
		 else round(coalesce(tw.RateTimesHours,0),2)
	end)
	- ( coalesce(tw.RevRec,0) )) + ( ISNULL(tw.AmountWrittenOff,  0) )) AS TotalWriteUpWriteOff

FROM 
	BG_Time_and_Writeoff_with_Effective_BillingRate_CG  tw with (nolock)
		left outer  JOIN 
	Customer c with (nolock) ON tw.CustomerId=c.CustomerId 
		left outer JOIN 
	Engagement e with (nolock) on tw.EngagementId=e.EngagementId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		LEFT OUTER JOIN 
	BillingOffice AS b  WITH (NOLOCK) ON b.BillingOfficeId = e.BillingOfficeId
		INNER JOIN 
	Resources r with (nolock) on tw.ResourceId=r.ResourceId 
		left outer join 
	EngRequestBillingRule er with (nolock) on tw.EngagementId=er.EngagementId and er.RequestType='TM'
		left outer join
	EngagementStatus es with (nolock) on e.EngagementStatus=es.Code
		left outer join 
	UDFDate d with (nolock) on e.EngagementId=d.EntityId and d.ItemName='EngagementText1'
WHERE 
	e.Name IS NOT NULL 
	and e.Deleted=0
	AND tw.TimeDate IS NOT NULL  
	and tw.Billable=1
	--AND (( tw.BILLABLE = 1  )  AND  ( (- ( ISNULL(tw.AMOUNTWRITTENOFF,  0) ))  != 0  OR (( ISNULL(tw.RATETIMESHOURS,  0) )  -  ( ISNULL(tw.REVREC,  0) ))  != 0  )) 
	--and tw.TimeDate>='20130101'
	and er.EngRequestBillingRuleId is NULL
	and e.BillingType<>'H'
	and d.UDFDate is not NULL
	and tw.EngagementId not in ('9F24B4FB-212C-4359-87E5-DA52BB6F61F6', '4B009190-F3AC-41FA-9474-FF3A050001BB')
















GO
