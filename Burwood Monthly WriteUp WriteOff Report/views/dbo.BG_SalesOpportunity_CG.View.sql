USE [BurwoodGroupInc_MSCRM]
GO
/****** Object:  View [dbo].[BG_SalesOpportunity_CG]    Script Date: 10/11/2019 3:01:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--select * from BG_SalesOpportunity_CG



CREATE VIEW [dbo].[BG_SalesOpportunity_CG] 
(
	[name],
    [customeridname],
    [estimatedvalue],
    [new_cpestimatedservicemargin],
	[new_productprofit],
	[new_commit],
    [Practice],
    [Opportunityscope],
	[StrategicArchitecture],
    [new_revisedclosedate],
	EstimatedCloseDate,
	[new_technologytype],
    [new_wondate],
    [opportunityid],
    [owneridname],
    [statecode],
    [statuscode],
	[createdOn],
	[probability],
	[new_risk],
	[new_SecondarySalesLeadIdName],
	[New_TertiarySalesLeadIdName],
	[New_BurwoodSourceIdName],
	[new_solutionsexpertName],
	[New_ManufacturerIdName],
	[description],
	[New_AnnualRenewalSubscription],
	[NoteText],
	[Owner],
	[Owner email], 
	[OwnerManager],
	[Owner Manager email],
	[eMailBurst]

	) with view_metadata as
select 
		[Opportunity].name,
		[Opportunity].CustomerIdName,
		[Opportunity].EstimatedValue,		
		[Opportunity].New_cpEstimatedServiceMargin,
		[Opportunity].New_ProductProfit,
		[Opportunity].New_Commit,
		s.Value,
		sc.Value,
		st.Value,
		cast([Opportunity].New_RevisedCloseDate as date),
		cast(EstimatedCloseDate as date),
		[Opportunity].New_TechnologyType,
		[Opportunity].New_WonDate,
		[Opportunity].OpportunityId,
		[Opportunity].OwnerIdName,
		[Opportunity].StateCode,
		[Opportunity].StatusCode,
		[Opportunity].CreatedOn,
		[Opportunity].CloseProbability,
		[Opportunity].OpportunityRatingCode,
		[Opportunity].new_SecondarySalesLeadIdName,
		[Opportunity].New_TertiarySalesLeadIdName,
		[Opportunity].New_BurwoodSourceIdName,
		[Opportunity].new_solutionsexpertName,
		[Opportunity].New_ManufacturerIdName,
		cast([Opportunity].Description as nvarchar(200)) as 'Opportunity Description',
		[Opportunity].New_AnnualRenewalSubscription,
		cast([AnnotationBase].NoteText as nvarchar(200)) as Notes,
		r.[Owner],
		r.[Owner email], 
		r.[OwnerManager],
		r.[Owner Manager email],
		case when r.[Owner email] IS NULL then 'tshepherd@burwood.com' 
			 when r.[Owner email] IS NULL and r.[Owner Manager email] IS NULL then 'tshepherd@burwood.com'
			 when r.[Owner email] IS NOT NULL and r.[Owner Manager email] IS NULL then ltrim(r.[Owner email])+',dlockett@burwood.com,mstogsdill@Burwood.com,tshepherd@burwood.com'
			 else ltrim(r.[Owner email])+','+ltrim(r.[Owner Manager email])+',dlockett@burwood.com,mstogsdill@Burwood.com,tshepherd@burwood.com'
		end as eMailBurst
		From Opportunity 
		left outer join AnnotationBase with (nolock) on [Opportunity].OpportunityId=[AnnotationBase].ObjectId
		left outer join BG_Opportunity_Resources_CG r with (nolock) on [Opportunity].OpportunityId=r.OpportunityId
		left outer join StringMap s with (nolock) on Opportunity.new_PracticeArea=s.AttributeValue and s.AttributeName='new_PracticeArea'
		left outer join StringMap sc with (nolock) on Opportunity.New_OpportunityScope=s.AttributeValue and s.AttributeName='new_opportunityscope'
		left outer join StringMap st with (nolock) on Opportunity.new_strategicArchitecture=st.AttributeValue and st.AttributeName='new_strategicarchitecture'
		--where YEAR([Opportunity].New_RevisedCloseDate) >= YEAR(SYSDATETIME())















GO
