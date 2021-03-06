USE [Changepoint]
GO
/****** Object:  View [dbo].[ResourceBoundaries]    Script Date: 10/14/2019 2:17:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ResourceBoundaries]
  
AS 
	
	SELECT r.ResourceId, wm.MinDate, 
	ISNULL(DATEADD(dd,-1, DATEADD(dd,0, DATEDIFF(dd,0,wm2.UnAssignedDate))),wm.MaxDate) MaxDate
	FROM Resources r WITH (NOLOCK) 
	CROSS APPLY 	
	(	SELECT 
		MIN( DATEADD(dd,0, DATEDIFF(dd,0,wm.EffectiveDate)) ) MinDate, 
		MAX(ISNULL(DATEADD(dd,-1, DATEADD(dd,0, DATEDIFF(dd,0,wm.EndDate))),wd.MAXWorkingDate)) MaxDate, 
		MAX(wm.EffectiveDate) MaxEffectiveDate
		FROM WorkgroupHistoryMember  wm  WITH (NOLOCK)
		CROSS APPLY
		( SELECT MAX(WorkingDate) MAXWorkingDate  FROM    WorkingDays wd WITH (NOLOCK) 
		)  wd
		WHERE wm.WorkGroupHistoryMemberType  NOT IN ('uns','del')  and  wm.ResourceId=r.ResourceId  AND 
		(wm.Updated=0x1 OR DATEADD(dd,0, DATEDIFF(dd,0,wm.EffectiveDate)) >  DATEADD(dd,0, DATEDIFF(dd,0,GETDATE())))
		GROUP BY  wm.ResourceId
	) wm
	OUTER APPLY 
	(
		
		SELECT MIN (wm2.EffectiveDate) UnAssignedDate FROM WorkgroupHistoryMember wm2 WITH (NOLOCK) WHERE wm2.WorkGroupHistoryMemberType ='uns'
		AND wm2.ResourceId=r.ResourceId AND wm2.EffectiveDate > wm.MaxEffectiveDate AND (wm2.Updated=0x1 OR DATEADD(dd,0, DATEDIFF(dd,0,wm2.EffectiveDate)) >  DATEADD(dd,0, DATEDIFF(dd,0,GETDATE())))
		GROUP BY wm2.ResourceId
	)wm2
	WHERE r.Deleted=0x0
	

GO
