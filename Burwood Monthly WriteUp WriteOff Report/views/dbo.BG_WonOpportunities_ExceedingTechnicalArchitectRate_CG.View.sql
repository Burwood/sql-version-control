USE [BurwoodGroupInc_MSCRM]
GO
/****** Object:  View [dbo].[BG_WonOpportunities_ExceedingTechnicalArchitectRate_CG]    Script Date: 10/11/2019 3:01:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[BG_WonOpportunities_ExceedingTechnicalArchitectRate_CG] as 
with a as (

SELECT 
	[Opportunity Name] as Opportunity,
	o1.EstimatedValue as TotalGP,
	[PreSalesRate]+[PreSalesRate2]+[PreSalesRate3] as TotalPreSalesRate,
	[Owner],
	[Owner email],
	[PreSalesResource],
	u.InternalEMailAddress as PreSalesEmail,
	m.FullName as PreSalesManager,
	m.InternalEmailAddress as PreSalesManagerEmail,
	case when coalesce(u.new_SolutionExpertCommissionPaid,0)=1 then 'Yes' else 'No' end as TechnicalArchitect, 
	[PreSalesIdQualify],
	[PreSalesScope],
	[PreSalesSOWBOMBOM],
	[PreSalesClose],
	[PreSalesRate],
	[PreSalesResource2],
	u2.InternalEMailAddress as PreSalesEmail2,
	m2.FullName as PreSalesManager2,
	m2.InternalEmailAddress as PreSalesManagerEmail2,
	case when coalesce(u2.new_SolutionExpertCommissionPaid,0)=1 then 'Yes' else 'No' end as TechnicalArchitect2,
	[PreSalesIdQualify2],
	[PreSalesScope2],
	[PreSalesSOWBOM2],
	[PreSalesClose2],
	[PreSalesRate2],
	[PreSalesResource3],
	u3.InternalEMailAddress as PreSalesEmail3,
	m3.FullName as PreSalesManager3,
	m3.InternalEmailAddress as PreSalesManagerEmail3,
	case when coalesce(u3.new_SolutionExpertCommissionPaid,0)=1 then 'Yes' else 'No' end as TechnicalArchitect3,
	[PreSalesIdQualify3],
	[PreSalesScope3],
	[PreSalesSOWBOM3],
	[PreSalesClose3],
	[PreSalesRate3],
	[SalesResource1],
	[SalesIdQualify1],
	[SalesScope1],
	[SalesSOW1],
	[SalesClose1],
	[SalesRate1],
	[SalesResource2],
	[SalesIdQualify2],
	[SalesScope2],
	[SalesSOW2],
	[SalesClose2],
	[SalesRate2],
	[SalesResource3],
	[SalesIdQualify3],
	[SalesScope3],
	[SalesSOW3],
	[SalesClose3],
	[SalesRate3],
	[SalesResource4],
	[SalesIdQualify4],
	[SalesScope4],
	[SalesSOW4],
	[SalesClose4],
	[SalesRate4],
	[Overlay],
	[Overlay email],
	[Overlay2],
	[Overlay2 email],
	o.[OpportunityId],
	[WonDate],
	[Owner email]+', '+case when u.InternalEMailAddress is null then '' else u.InternalEMailAddress+', ' end+case when u2.InternalEMailAddress is null then '' else u2.InternalEMailAddress+', '  end+case when u3.InternalEMailAddress is null then '' else u3.InternalEMailAddress+', '  end +'rgibson@burwood.com, tshepherd@burwood.com' as Burst,
	'tshepherd@burwood.com' as TestBurst
FROM 
	OpportunityBase o1 with (nolock)
		join
	BG_Opportunity_Resources_CG o with (nolock) on o1.OpportunityId=o.OpportunityId
		left outer join
	SystemUserBase u with (nolock) on o.PreSalesSystemUserId=u.SystemUserId 
		left outer join
	SystemUserBase m with (nolock) on u.ParentSystemUserId=m.SystemUserId
		left outer join
	SystemUserBase u2 with (nolock) on o.PreSalesSystemUserId2=u2.SystemUserId 
		left outer join
	SystemUserBase m2 with (nolock) on u2.ParentSystemUserId=m2.SystemUserId
		left outer join
	SystemUserBase u3 with (nolock) on o.PreSalesSystemUserId3=u3.SystemUserId
		left outer join
	SystemUserBase m3 with (nolock) on u3.ParentSystemUserId=m3.SystemUserId
where
	WonDate>='20180101'
	and ([PreSalesRate]+[PreSalesRate2]+[PreSalesRate3])>1
)

select
	b.*,
	'https://chil-crm-04.burwood.com/BurwoodGroupInc/main.aspx?etc=3&id='+convert(varchar(1048), a.OpportunityId)+'&pagetype=entityrecord' as 'OppURL',
	a.TotalGP,
	a.Burst,
	a.TestBurst
from
	a
		join
	[BG_WonOpportunities_TechnicalPreSales_CG] b with (nolock) on a.OpportunityId=b.OpportunityId


GO
