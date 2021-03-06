USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ResourceQualifications_CG]    Script Date: 10/17/2019 3:05:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO










--select count(*) from [BG_ResourceQualifications_CG]



CREATE VIEW [dbo].[BG_ResourceQualifications_CG] AS


with a as (
select  
	r.Name as Resource,
	r.ResourceId,
	w.Region,
	w.Practice as Practice,
	w.Workgroup as Workgroup,
	sca.Name as Area,
	case when sca.Name='Cloud & Automation' then 1
		 when sca.Name='Communications & Collaboration' then 2
		 when sca.Name='Data Analytics' then 3
		 when sca.Name='PMO' then 4
		 when sca.Name='Security' then 5
	end as AreaSort,
	sk.Name as Category,
	sco.Name as Skill,
	case when coalesce(rc.YearsExperience,'0')=' ' then '0' else coalesce(convert(decimal(3,0), rc.YearsExperience),'0') end as Rating,
	rc.LastUsed as Updated

from 
	Resources r with (nolock)
		cross join
	SkillCategory sca
		join
	Skill sk on sca.Code=sk.SkillCategoryCode
		join
	SkillCompetency sco on sk.SkillCode=sco.SkillCode
		left outer join
	[BG_ResourceCurrentWorkgroup_with_Terms_and_Contractors_CG] w on r.ResourceId=w.ResourceId
	--BG_ResourceCurrentWorkgroup_CG w on r.ResourceId=w.ResourceId
	--	join
	--WorkgroupMember wm with (nolock) on r.ResourceId=wm.ResourceId and wm.Historical=0
	--	join
	--Workgroup w with (nolock) on wm.WorkgroupId=w.WorkgroupId
	--	join
	--CostCenters cc with (nolock) on r.CostCenterId=cc.CostCenter
		left outer join
	ResourceCompetency rc with (nolock) on r.ResourceId=rc.ResourceId and rc.SkillCategoryCode=sco.SkillCategoryCode and rc.SkillCode=sco.SkillCode and rc.CompetencyCode=sco.Code
where
	sca.Name in ('Cloud & Automation', 'Communications & Collaboration', 'Data Analytics', 'Security', 'PMO')
	and r.EmployeeType<>'CO'
	and r.Name not like '*%'
	and r.TerminationDate is null
	and r.Name<>'Account, CRM'
	--and r.Name='Czochara, Kenneth'
	--and w.TerminationDate is null
	--and case when coalesce(rc.YearsExperience,'0')=' ' then '0' else coalesce(convert(decimal(3,0), rc.YearsExperience),'0') end <> 0 
)

select
	*,
	(select sum(Rating) from a where a.Resource=a1.Resource) as TotalRating
from
	a as a1

	--order by Resource





GO
