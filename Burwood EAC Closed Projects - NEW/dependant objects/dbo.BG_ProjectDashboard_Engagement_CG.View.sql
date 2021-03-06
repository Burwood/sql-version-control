USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_Engagement_CG]    Script Date: 10/14/2019 3:21:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








----drop table BG_ProjectDashboard_Engagement_Table_CG
----select * into BG_ProjectDashboard_Engagement_Table_CG from [BG_ProjectDashboard_Engagement_CG] where EngagementId='8BBC144D-B895-4429-AA41-66E22ED0F5E0'
----select * from BG_ProjectDashboard_Engagement_Table_CG where EngagementId='8BBC144D-B895-4429-AA41-66E22ED0F5E0'


CREATE VIEW [dbo].[BG_ProjectDashboard_Engagement_CG] AS
with en as 
(
select
	e.Name as Engagement,
	e.EngagementId,
	e.EngagementStatus,
	p.Name as Project,
	case when p.AllowTaskExpenses=1 then 'Yes' else 'No' end as AllowTaskExpenses,
	p.ProjectId,
	coalesce(p.LabourBudget,0) as LaborBudget,
	coalesce(p.ExpenseBudget,0) as ExpenseBudget,
	coalesce(p.OtherExpenseBudget,0) as OtherExpenseBudget,
	coalesce(p.BaselineHours,0) as BaselineHours,
	coalesce(p.ActualHours,0) as ActualHours,
	coalesce(p.PlannedHours,0) as PlannedHours,
	coalesce(convert(decimal(10,2), u.UDFText),0) as ContingencyAmount,
	e.ContractNumber,
	coalesce(e.ContractAmount,0) as ContractAmount,
	coalesce(e.RevRec,0) as RevRec,
	coalesce(e.RevAdjTotal,0) as RevAdjTotal,
	ab.BillableHours as ProjectBillableHours,
	coalesce(ab.PotentialFees,0) as ProjectPotentialFees,
	ab.RevenueRecognized as ProjectRevenueRecognized,
	-coalesce(ab.ActualCost,0) as ProjectActualCost,
	coalesce(ab.Adjustments,0) as Adjustments,
	ab.WriteUpWriteOff as WriteUpWriteOff,
	coalesce(f.ForecastHours,0) as ForecastHours,
	coalesce(f.ForecastRevenue,0) as ForecastRevenue,
	-coalesce(f.ForecastCost,0) as ForecastCost,
	e.RevRecDate,
	coalesce(e.ContractAmount,0)-coalesce(e.RevRec,0)-coalesce(e.RevAdjTotal,0) as RemainingContractAmount,
	bt.Description as BillingType,
	pt.Description as PaymentTerms,
	e.OtherBillingInformation,
	ebt.Description as ExpenseBillingType,
	fv.POContractAmountCalculated,
      fv.ServicesAmount,
      coalesce(fv.ExpenseAmount,0) as ExpenseAmount,
      fv.FixedFeeContractorPassThroughAmount,
      fv.FixedFeeSubContractorMargin,
      fv.EstimationCost,
      fv.EstimationSell,
      fv.PlannedMarginPercent,
      fv.PlannedCostBudget,
      fv.PlannedProfitability,
      fv.[Risk$],
      fv.[Risk%],
      fv.NumberOfProjects,
      fv.MultipleProjects,
      fv.POContractAmountDifference,
      fv.POContractAmountMatches,
      fv.MultipleProjectsDisplay,
	  (select sum(ExpectedInternalCost) from [BG_EAC_Summary_CG] eac where eac.EngagementId=e.EngagementId) as ExpectedInternalCost,
	  ajt.[Adjustment to Close a Project],
	  ajt.[Contractor Margin Adjustment],
	  ajt.[Contractor Pass-through Adjustment],
	  ajt.[Expense Recognition Adjustment],
	  ajt.[Other Adjustment],
	  coalesce(ue.TotalExpense,0) as UnapprovedExpenses,
	  coalesce(ae.TotalExpense,0) as ApprovedExpenses
from
	dbo.Engagement e with (nolock)
		join
	BG_ProjectDashboard_FinancialValues_CG fv with (nolock) on e.EngagementId=fv.EngagementId
		join
	dbo.BillingType bt with (nolock) on e.BillingType=bt.Code
		join
	dbo.PaymentTerms pt with (nolock) on e.PaymentTerms=pt.Code
		join
	dbo.Project p with (nolock) on e.EngagementId=p.EngagementId
		join
	ExpenseBillingType ebt with (nolock) on e.ExpenseBillingType=ebt.Code
		left outer join
	BG_ProjectDashboard_ForecastSummary_CG f with (nolock) on e.EngagementId=f.EngagementId and p.ProjectId=f.ProjectId
		left outer join
	UDFText u with (nolock) on u.EntityId=e.EngagementId and u.ItemName='EngagementText7'
		left outer join
	BG_ProjectDashboard_ActualTotals_byEngagement_CG ab with (nolock) on e.EngagementId=ab.EngagementId
		left outer join
	BG_ProjectDashboard_AdjustmentsByType_byEngagement_CG ajt with (nolock) on e.EngagementId=ajt.EngagementId
		left outer join
	BG_ProjectDashboard_UnapprovedExpensesSummary_CG ue with (nolock) on e.EngagementId=ue.EngagementId and p.ProjectId=ue.ProjectId
		left outer join
	[BG_ProjectDashboard_ApprovedExpensesSummary_CG] ae with (nolock) on e.EngagementId=ae.EngagementId and p.ProjectId=ae.ProjectId
--where e.Name='Wake Forest Baptist Health - Access Center Refresh'
)
select
	Engagement,
	EngagementId,
	BillingType,
	PaymentTerms,
	OtherBillingInformation,
	ExpenseBillingType,
	EngagementStatus,
	Project,
	ProjectId,
	LaborBudget,
	ExpenseBudget,
	OtherExpenseBudget,
	BaselineHours,
	ActualHours,
	PlannedHours,
	ForecastHours,
	ContingencyAmount,
	ContractNumber,
	ContractAmount,
	RevRec,
	Adjustments as RevAdjTotal,
	ProjectBillableHours,
	ProjectPotentialFees,
	ProjectRevenueRecognized,
	0 as EngagementBillableHours,
	0 as EngagementPotentialFees,
	0 as EngagementRevenueRecognized,
	ForecastRevenue,
	RevRecDate,
	RemainingContractAmount as RemainingContractAmount1,
	ContractAmount-ProjectPotentialFees+Adjustments as RemainingContractAmount,
	WriteUpWriteOff as ForecastRemainingContractAmount,
	LaborBudget-ProjectPotentialFees as ProjectRemainingAmount,
	LaborBudget-ProjectPotentialFees-ForecastRevenue ProjectPlannedRemainingAmount,
	0 as EngagementWriteUpWriteOff,--ContractAmount-EngagementPotentialFees+Adjustments-ForecastRevenue as EngagementWriteUpWriteOff,
	WriteUpWriteOff as TheRealWriteUpWriteOff,
	LaborBudget-ProjectRevenueRecognized-ForecastRevenue as NewWriteUpWriteOff,  --ProjectWriteUpWriteOff Amount
	--case when ActualHours=0 
	--	 then 0 
	--	 else (case when EngagementRevenueRecognized=0 then coalesce(RevRec,0)+coalesce(RevAdjTotal,0) else EngagementRevenueRecognized end )/ActualHours 
	--end as EngagementRealizationRate,
	0 as EngagementRealizationRate,
	case when ActualHours=0 
		 then 0 
		 else (coalesce(ProjectRevenueRecognized,0)+coalesce(ForecastRevenue,0))/(ActualHours+ForecastHours) 
	end as ProjectRealizationRate,
	POContractAmountCalculated,
	ServicesAmount,
      ExpenseAmount,
      FixedFeeContractorPassThroughAmount,
      FixedFeeSubContractorMargin,
      EstimationCost,
      EstimationSell,
      PlannedMarginPercent,
      PlannedCostBudget,
      PlannedProfitability,
      [Risk$],
      [Risk%],
      NumberOfProjects,
      MultipleProjects,
      POContractAmountDifference,
      POContractAmountMatches,
      MultipleProjectsDisplay,
	  ExpectedInternalCost,
	  case when ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 )=0 then 0 else ( ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 ) - ExpectedInternalCost ) / ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 ) end as CPInputMargin,--'ActualBillingMargin%',
	  case when LaborBudget=0 then 0 else (LaborBudget-ProjectPotentialFees-ForecastRevenue)/LaborBudget end as ServicesDifference,
	  case when BillingType='Hourly' and ExpenseBillingType='No expenses' 
		   then 'INVALID Expense Configuration'
		   when BillingType='Fixed Fee' and ExpenseBillingType='No expenses' and ExpenseBudget=0 
		   then 'FF Expense Configured but no Budget defined!'--'No Expense Budget Defined'
		   else 'OK'
	  end as BillingTypeErrorCheck,
	  case when BillingType='Hourly' and (LaborBudget+ExpenseBudget)=ContractAmount 
		   then 'Customer PO amount includes expenses'
		   when BillingType='Hourly' and LaborBudget=ContractAmount
		   then 'Customer PO only includes services'
		   else 'Other'
	  end as ContractAmountIncludesErrorCheck
	  --,
	  --AllowTaskExpenses,
	  --ProjectActualCost,
	  --ForecastCost,
	  --[Adjustment to Close a Project],
	  --[Contractor Margin Adjustment],
	  --[Contractor Pass-through Adjustment],
	  --[Expense Recognition Adjustment],
	  --[Other Adjustment],
	  --case when [EstimationCost]<>0 and [EstimationSell]<>0 then 'OK' else 'NO' end as NewFieldsConfigured,
	  --case when MultipleProjects='NO' then 'OK' else 'Multiple Projects in this Engagement' end as EngagementWarning,
	  --case when [ContractAmount]=[POContractAmountCalculated] then 'OK' else 'NO' end as FinancialConfigCheck,
	  --case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end as FixedFeeExpenseBudget,
	  --case when ExpenseBillingType='All Expenses' then 0 else [Expense Recognition Adjustment] end as FixedFeeExpenseActual,
	  --(case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin) as TotalBudget,
	  --Adjustments+FixedFeeContractorPassThroughAmount as TotalActualBudget,
	  ---UnapprovedExpenses as UnapprovedExpenses,
	  ---ApprovedExpenses as ApprovedExpenses,
	  ---(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment]) as ForecastFFContractorPassThrough,
	  ---(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]) as ForecastContractorMargin,
	  --(LaborBudget-ProjectPotentialFees-ForecastRevenue)+(((case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin))-(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]))+(Adjustments)) as WUWO,
	  ---(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment])) as TotalForecastAmount,
	  --((case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin))-(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]))+(Adjustments) as EACTotalRemaining,
	  --case when ExpenseBillingType='No expenses' then 0 else ExpenseAmount end as FixedFeeBAAExpenseBudget,
	  --case when ExpenseBillingType='No expenses' then 0 else (ExpenseAmount - ApprovedExpenses) end as FFBAAExpenseRemaining,
	  --case when ExpenseBillingType='No expenses' or (ExpenseBillingType<>'No expenses' and ExpenseAmount=0) then 0 else ((ExpenseAmount - ApprovedExpenses))/ExpenseAmount end as FFBAAExpenseRemainDiff,
	  --EstimationCost+ProjectActualCost+ForecastCost as EstimationCostRemaining,
	  --case when EstimationCost=0 then 0 else (EstimationCost+ProjectActualCost+ForecastCost)/EstimationCost end as EstimationCostRemainDiff,
	  --PlannedCostBudget+ProjectActualCost+ForecastCost as PlannedCostRemaining,
	  --case when PlannedCostBudget=0 then 0 else (PlannedCostBudget+ProjectActualCost+ForecastCost)/PlannedCostBudget end as PlannedCostRemainDiff,
	  --case when (ProjectPotentialFees+ForecastRevenue)=0 then 0 else ((ForecastCost)-((ProjectPotentialFees+ForecastRevenue)*-1))/(ProjectPotentialFees+ForecastRevenue) end as 'Margin%Forecast',
	  --(ProjectPotentialFees+ForecastRevenue)+ForecastCost as 'Margin$Forecast',
	  --(LaborBudget+ForecastCost)+(((case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin))-(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]))+(Adjustments)) as 'Margin$EAC',
	  --case when LaborBudget=0 then 0 else ((LaborBudget+ForecastCost)+(((case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin))-(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]))+(Adjustments)))/(LaborBudget) end as 'Margin%EAC',
	  --(case when LaborBudget=0 then 0 else ((LaborBudget+ForecastCost)+(((case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin))-(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]))+(Adjustments)))/(LaborBudget) end)-(PlannedMarginPercent) as 'Margin%Diff',
	  --((LaborBudget+ForecastCost)+(((case when ExpenseBillingType='All Expenses' then 0 else ExpenseAmount end)+(FixedFeeContractorPassThroughAmount)+(FixedFeeSubContractorMargin))-(ForecastRevenue+UnapprovedExpenses+(FixedFeeContractorPassThroughAmount+[Contractor Pass-through Adjustment])+(FixedFeeSubContractorMargin+[Contractor Margin Adjustment]))+(Adjustments)))-(PlannedProfitability) as 'Margin$Diff',
	  --(case when ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 )=0 then 0 else ( ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 ) - ExpectedInternalCost ) / ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 ) end)-PlannedMarginPercent as 'ActualBillingMargin%Check'
from
	en

	--reportid 'incidents'

----drop table BG_ProjectDashboard_Engagement_Table_CG

----truncate table BG_ProjectDashboard_Engagement_Table_CG insert into BG_ProjectDashboard_Engagement_Table_CG select * from [BG_ProjectDashboard_Engagement_CG] where FixedFeeBAAExpenseBudget>0 and EngagementStatus='W'

----select * into BG_ProjectDashboard_Engagement_Table_CG from [BG_ProjectDashboard_Engagement_CG] where FixedFeeBAAExpenseBudget>0 and EngagementStatus='W'

----select * from BG_ProjectDashboard_Engagement_Table_CG order by Project

--select * into BG_ProjectDashboard_Engagement_Table_CG from BG_ProjectDashboard_Engagement_CG where EngagementStatus='W' and FixedFeeExpenseBudget>0 and ExpenseBillingType<>'All expenses' and UnapprovedExpenses<>0










GO
