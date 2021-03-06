USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectTypeUDF_CG]    Script Date: 9/30/2019 5:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[BG_ProjectTypeUDF_CG] as
select
	p.EngagementId,
	p.ProjectId,
	p.Name as Project,
	cd.Description as ProjectType
from
	Project p with (nolock)
		join
	UDFCode u with (Nolock) on p.ProjectId=u.EntityId and u.ItemName='ProjectCode3'
		join
	CodeDetail cd with (nolock) on u.UDFCode=cd.CodeDetail


GO
