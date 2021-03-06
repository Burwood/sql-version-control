USE [BurwoodGroupInc_MSCRM]
GO
/****** Object:  View [dbo].[BG_WonOpportunities_ExceedingSalesQuotaShareRate_CG]    Script Date: 10/11/2019 3:01:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[BG_WonOpportunities_ExceedingSalesQuotaShareRate_CG] as 
with a as (

SELECT 
	[Account Name] as Account,
	[Opportunity Name] as Opportunity,
	[SalesRate1]+[SalesRate2]+[SalesRate3]+[SalesRate4] as TotalSalesRate,
	[Owner],
	[Owner email],
	[SalesResource1],
	u.InternalEMailAddress as SalesEmail1,
	m.FullName as SalesManager1,
	m.InternalEmailAddress as SalesManagerEmail1,
	[SalesIdQualify1],
	[SalesScope1],
	[SalesSOW1],
	[SalesClose1],
	[SalesRate1],
	[SalesResource2],
	u2.InternalEMailAddress as SalesEmail2,
	m2.FullName as SalesManager2,
	m2.InternalEmailAddress as SalesManagerEmail2,
	[SalesIdQualify2],
	[SalesScope2],
	SalesSOW2,
	[SalesClose2],
	[SalesRate2],
	[SalesResource3],
	u3.InternalEMailAddress as SalesEmail3,
	m3.FullName as SalesManager3,
	m3.InternalEmailAddress as SalesManagerEmail3,
	[SalesIdQualify3],
	[SalesScope3],
	[SalesSOW3],
	[SalesClose3],
	[SalesRate3],
	[SalesResource4],
	u4.InternalEMailAddress as SalesEmail4,
	m4.FullName as SalesManager4,
	m4.InternalEmailAddress as SalesManagerEmail4,
	[SalesIdQualify4],
	[SalesScope4],
	[SalesSOW4],
	[SalesClose4],
	[SalesRate4],
	[Overlay],
	[Overlay email],
	[Overlay2],
	[Overlay2 email],
	[OpportunityId],
	[WonDate],
	[Owner email]+', '+case when u.InternalEMailAddress is null then '' else u.InternalEMailAddress+', ' end+case when u2.InternalEMailAddress is null then '' else u2.InternalEMailAddress+', '  end+case when u3.InternalEMailAddress is null then '' else u3.InternalEMailAddress+', '  end +'rgibson@burwood.com, tshepherd@burwood.com' as Burst,
	'tshepherd@burwood.com' as TestBurst
FROM 
	BG_Opportunity_Resources_CG o with (nolock)
		left outer join
	SystemUserBase u with (nolock) on o.SalesResource1=u.FullName 
		left outer join
	SystemUserBase m with (nolock) on u.ParentSystemUserId=m.SystemUserId
		left outer join
	SystemUserBase u2 with (nolock) on o.SalesResource2=u2.FullName 
		left outer join
	SystemUserBase m2 with (nolock) on u2.ParentSystemUserId=m2.SystemUserId
		left outer join
	SystemUserBase u3 with (nolock) on o.SalesResource3=u3.FullName
		left outer join
	SystemUserBase m3 with (nolock) on u3.ParentSystemUserId=m3.SystemUserId
		left outer join
	SystemUserBase u4 with (nolock) on o.SalesResource4=u4.FullName
		left outer join
	SystemUserBase m4 with (nolock) on u4.ParentSystemUserId=m4.SystemUserId
		left outer join
	BG_ExecutiveDirectorQuotaGoals_CG ed with (nolock) on ed.SystemUserId=u2.SystemUserId or ed.SystemUserId=u3.SystemUserId or ed.SystemUserId=u4.SystemUserId

where
	(year(WonDate)>=2018
	or o.OpportunityId in (select distinct OpportunityId from [fpdc-sql-01].[BGINC].dbo.BG_New_Commissions_Accelerators_Detail2018V2_Table_CG where Resource=Owner))
	and ([SalesRate1]+[SalesRate2]+[SalesRate3]+SalesRate4)>1
	and o.OpportunityId not in (select OpportunityId from BG_ExecutiveDirectorDoubleCreditOpportunities_CG)
)

select
	a.*,
	'https://chil-crm-04.burwood.com/BurwoodGroupInc/main.aspx?etc=3&id='+convert(varchar(1048), a.OpportunityId)+'&pagetype=entityrecord' as 'OppURL'
from
	a
	--	join
	--BG_WonOpportunities_SalesQuotaShared_CG b with (nolock) on a.OpportunityId=b.OpportunityId




GO
