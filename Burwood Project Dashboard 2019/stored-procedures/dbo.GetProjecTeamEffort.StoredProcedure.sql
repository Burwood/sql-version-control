USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[GetProjecTeamEffort]    Script Date: 10/10/2019 2:41:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetProjecTeamEffort]
(
	@RequestId 			UNIQUEIDENTIFIER , 
	@sDate				DATETIME, 
	@eDate				DATETIME, 
	@ReportType			CHAR(1)='', 
	@ViewType			VARCHAR(3)='', 
	@GroupByCommit		BIT=0,
	@TransactionXML		XML=NULL
)
 AS
BEGIN
	SET NOCOUNT ON 
	
	DEClARE @PM_StartLogTime	DATETIME
	IF NOT @TransactionXML IS NULL SET @PM_StartLogTime=GETUTCDATE()
	DECLARE @NUllId UNIQUEIDENTIFIER,  @FloorConverter INT
	SET @NullId = '{00000000-0000-0000-0000-000000000000}'
	SET @FloorConverter=100000
	DECLARE @ADjustEffort TABLE
	(
		ProjectTeamId		UNIQUEIDENTIFIER,
		ProjectId		UNIQUEIDENTIFIER,
		ResourceId		UNIQUEIDENTIFIER,
		Effort			NUMERIC(12,5),
		CreatedoN		DATETIME
	)
	
	DECLARE @AssignTotal	Table
	(
		ProjectId		UNIQUEIDENTIFIER,
		ResourceId		UNIQUEIDENTIFIER,
		AssignmentTotal		NUMERIC(14,5),
		ProjectTeamTotal	NUMERIC(14,5),
		LastDate		DATETIME
	)
	CREATE TABLE #ProjectTeam
	(
		ProjectId		UNIQUEIDENTIFIER,
	 	ProjectTeamId  		UNIQUEIDENTIFIER,
		ResourceId		UNIQUEIDENTIFIER,
	 	WorkgroupId    		UNIQUEIDENTIFIER,
		FunctionId		UNIQUEIDENTIFIER,
	 	WorkingDays   		INT, 
	 	PlannedHours   		NUMERIC (12,5), 
	 	PStart    		DATETIME,
	 	PEnd    		DATETIME, 
	 	LastDate   		DATETIME,
	 	LastDateValue   	NUMERIC (12,5) DEFAULT 0,
	 	RegularDateValue  	NUMERIC (12,5) DEFAULT 0,
		[Committed]		BIT DEFAULT 0,
		IsDailyEffort		BIT	
	)
	
	CREATE INDEX tx_ProjectTeam ON #ProjectTeam (ProjectTeamId, WorkgroupId, WorkingDays,  PlannedHours, PStart, PEnd)
	CREATE TABLE #NonWorkingDays
	(
		EntityId uniqueidentifier,
		WorkingDate datetime
	)
	
	CREATE INDEX tx_NonWorkingDays ON #NonWorkingDays  (EntityId, WorkingDate)
	set @ViewType =upper(@ViewType )
	set @ReportType =upper(@ReportType )
	IF ((@sDate IS NULL)  OR (@eDate IS NULL ))
		BEGIN
			SELECT @sDate=MIN(ISNULL(pt.StartDate,GETDATE())), @eDate=MAX(ISNULL(pt.FinishDate,GETDATE()))
			FROM DemandItemRequest   dr  WITH (NOLOCK) 
			INNER JOIN ProjectTeam pt  WITH (NOLOCK)  ON dr.ItemId=pt.ProjectTeamId  AND dr.RequestId=@RequestId
		END 
	
	DECLARE @MinStart DATETIME, @MaxFinish DATETIME
	SELECT ItemID, StartDate, EndDate
	INTO #RMV_Dates
	FROM
	(
		SELECT dr.WorkgroupId as ItemID, MIN(StartDate) as StartDate, MAX(FinishDate) as EndDate
		FROM   DemandItemRequest dr  WITH (NOLOCK) 
		INNER JOIN ProjectTeam pt  WITH (NOLOCK)  ON dr.ItemId = pt.ProjectTeamId AND ISNULL(pt.ResourceId,@NUllId)=@NUllId			
		WHERE  dr.RequestId = @RequestId 
		GROUP BY dr.WorkgroupId
		UNION 
		SELECT pt.ResourceId as ItemID, MIN(StartDate), MAX(FinishDate)
		FROM   DemandItemRequest dr  WITH (NOLOCK) 
		INNER JOIN ProjectTeam pt  WITH (NOLOCK)  ON dr.ItemId = pt.ProjectTeamId  AND ISNULL(pt.ResourceId,@NUllId)!=@NUllId
		WHERE dr.RequestId=@RequestId 
		GROUP BY pt.ResourceId
	) a
	SELECT @MinStart= MIN(StartDate), @MaxFinish=MAX(EndDate) FROM #RMV_Dates
	IF (@eDate<@MinStart)
		SET @MinStart=@eDate
	IF (@sDate<@MinStart)
		SET @MinStart=@sDate
	IF (@sDate>@MaxFinish)
		SET @MaxFinish=@sDate
	IF (@eDate>@MaxFinish)
		SET @MaxFinish=@eDate
	SELECT	WorkingDate
	INTO #RMVWorkingDays
	FROM	WorkingDays   WITH (NOLOCK) 
	WHERE	WorkingDate BETWEEN @MinStart AND @MaxFinish
	INSERT INTO #NonWorkingDays	(EntityId, WorkingDate)
	SELECT	nwd.WorkgroupId, nwd.NonWorkingDate
	FROM	WorkgroupNonWorkingDay nwd  WITH (NOLOCK) 
	INNER JOIN #RMV_Dates d ON d.ItemId=nwd.WorkgroupId AND nwd.NonWorkingDate BETWEEN @MinStart AND @MaxFinish
	
	SELECT	nwd.ResourceId, nwd.NonWorkingDate
	INTO  #RMV_ResourceNonWorkingDays
	FROM	#RMV_Dates d
	INNER JOIN ResourceNonWorkingDays nwd  WITH (NOLOCK)  ON d.ItemId=nwd.ResourceId AND nwd.NonWorkingDate BETWEEN @MinStart AND @MaxFinish
	
		
	INSERT INTO #ProjectTeam
			   (ProjectId,
				ProjectTeamId,
				ResourceId,
				WorkgroupId,
				FunctionId,
				WorkingDays,
				PlannedHours,
				PStart,
				PEnd,
				LastDate,
				[Committed],
				IsDailyEffort)
	SELECT DISTINCT pt.ProjectId,
		   pt.ProjectTeamId,
		   ISNULL(pt.ResourceId,@NULLID),
		   dr.WorkgroupId,
		   dr.FunctionId, 
		   CASE WHEN isNull(pt.ResourceId,@NULLID) = @NULLID THEN tt2.Wcount ELSE tt.Wcount END,	
		   CASE WHEN @ViewType ='PTL' THEN pt.EstimatedHours ELSE pt.DemandHours END,
		   pt.StartDate,
		   pt.FinishDate,
		   CASE WHEN isNull(pt.ResourceId,@NULLID) = @NULLID THEN tt2.MaxWorkingDate ELSE tt.MaxWorkingDate END,
		   dr.[Committed],
		   CASE WHEN (dl.ProjectTeamId IS NULL) THEN 0 ELSE 1 END IsDailyEffort	
	FROM   DemandItemRequest dr  WITH (NOLOCK) 
		   INNER JOIN ProjectTeam pt  WITH (NOLOCK) 
			 ON dr.ItemId = pt.ProjectTeamId
				AND dr.RequestId = @RequestId
				AND ( (@ViewType ='PTL') OR  (ISNULL(pt.DemandHours,0) > 0) )
		   INNER JOIN Project p  WITH (NOLOCK) 
			 ON pt.projectId = p.ProjectId
				AND p.Deleted = 0
		   INNER JOIN Engagement e  WITH (NOLOCK) 
			 ON e.EngagementId = p.EngagementId
				AND e.AllowPRjResourceRequest = 1
			CROSS APPLY 
			(
				 SELECT	MAX(wd.WorkingDate) MaxWorkingDate, COUNT (1) Wcount FROM	WorkingDays wd  WITH (NOLOCK) 
				 WHERE	ISNULL(pt.ResourceId,@NUllId) = @NULlID AND   ISNULL(dr.WorkgroupId,@NUllId) <> @NULlID  AND  wd.WorkingDate   BETWEEN  pt.StartDate  AND pt.FinishDate  
				 AND  NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays rn WITH (NOLOCK) WHERE rn.EntityId=dr.WorkgroupId AND wd.WorkingDate=rn.WorkingDate)		
			) tt2
			CROSS APPLY 
			(
				 SELECT	MAX(wd.WorkingDate) MaxWorkingDate, COUNT (1) Wcount FROM WorkingDays wd  WITH (NOLOCK) 
				 WHERE	 (ISNULL(pt.ResourceId,@NUllId) <> @NULlID  OR  ISNULL(dr.WorkgroupId,@NUllId) = @NULlID)   AND wd.WorkingDate   BETWEEN  pt.StartDate  AND pt.FinishDate     
				 AND  NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays rn WITH (NOLOCK) WHERE rn.ResourceId=pt.ResourceId AND wd.WorkingDate=rn.NonWorkingDate)
			) tt
		   LEFT JOIN ProjectTeamDailyAllocation dl  WITH (NOLOCK)  ON pt.ProjectTeamId=dl.ProjectTeamId 
	
	UPDATE #ProjectTeam SET RegularDateValue=FLOOR((PlannedHours/WorkingDays)*@FloorConverter)/@FloorConverter,
	LastDateValue=PlannedHours - ((FLOOR((PlannedHours/WorkingDays)*@FloorConverter)/@FloorConverter) * WorkingDays)
	WHERE   WorkingDays> 0   AND PlannedHours> 0 AND (IsDailyEffort = 0 OR @ViewType = 'PTL')	
	
	
	IF (@ViewType)='RS'
		BEGIN
				INSERT INTO #ResourceDemandEffort (ItemId, Effort)
				SELECT tt.ResourceId, SUM(tt.Effort) FROM
				(
					SELECT  pt.ResourceId ResourceId, 
							CASE WHEN wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END Effort
					FROM	#ProjectTeam pt
					INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
					AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
					AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )
					WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
					UNION ALL	
					SELECT	
							pt.ResourceId ResourceId,  
							dl.Effort Effort
					FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
							INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
								AND dl.StartDate = dl.EndDate
					WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
							AND pt.IsDailyEffort = 1  
				)tt
				GROUP BY tt.ResourceId 
		END 
	IF (@ViewType)='PTL'
		BEGIN
				INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate, EstimatedHours )
				SELECT  @RequestId, 'PRT', pt.ProjectId, pt.ResourceId, pt.ProjectTeamId, wd.WorkingDate, CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue)ELSE pt.RegularDateValue END  Effot
				FROM #ProjectTeam pt
				INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
				AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
				AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )
				WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0
		END 
	
	IF (@ViewType)=''
		BEGIN
				INSERT INTO #ResourceDemandEffort (Type, ItemId, ResDemandDate, Effort)
				SELECT  'PRJ', 
						pt.ProjectTeamId, 
						wd.WorkingDate, 
						CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END  Effort
				FROM	#ProjectTeam pt
						INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
						AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
						AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
				WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
				UNION ALL 
				SELECT	'PRJ', 
						pt.ProjectTeamId, 
						dl.StartDate, 
						dl.Effort Effort
				FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
						INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
							AND dl.StartDate = dl.EndDate
				WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
						AND pt.IsDailyEffort = 1  														
		END 
	
	IF (@ViewType)='VI'
	
		BEGIN
			IF @ReportType='G'
				BEGIN
							
					INSERT INTO #ResourceDemandEffort (Type, ItemId, ResDemandDate, Effort)
					SELECT  'PRJ', tt.ProjectId, tt.WorkingDate, SUM(tt.Effort) FROM
					(
						SELECT  pt.ProjectId ProjectId, 
								wd.WorkingDate WorkingDate, 
								CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END  Effort
						FROM	#ProjectTeam pt
						INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
						AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
						AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
						WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
						UNION ALL	
						SELECT	pt.ProjectId ProjectId, 
								dl.StartDate WorkingDate, 
								dl.Effort Effort
						FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
								INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
									AND dl.StartDate = dl.EndDate
						WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
								AND pt.IsDailyEffort = 1  													
					)tt	
					GROUP BY  tt.ProjectId, tt.WorkingDate		
				END 
			ELSE
				BEGIN
	
					If @GroupByCommit=0 
						BEGIN 
							INSERT INTO #ResourceDemandEffort (ResDemandDate, Effort)
							SELECT tt.WorkingDate, SUM(tt.Effort) FROM
							(
								SELECT  wd.WorkingDate WorkingDate, 
										CASE WHEN wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END Effort
								FROM	#ProjectTeam pt
								INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
								AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
								AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
								WHERE   pt.PlannedHours> 0 AND pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
								UNION ALL	
								SELECT	dl.StartDate WorkingDate, 
										dl.Effort Effort
								FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
										INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
											AND dl.StartDate = dl.EndDate
								WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
										AND pt.IsDailyEffort = 1  													
							) tt
							GROUP BY  tt.WorkingDate
						END 								
					ELSE
						BEGIN
							INSERT INTO #ResourceDemandEffort (ResDemandDate, [Committed],Effort)
							SELECT  tt.WorkingDate, tt.Committed, SUM(tt.Effort) FROM
							(
								SELECT  wd.WorkingDate WorkingDate, 
										pt.[Committed] Committed, 
										CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END Effort
								FROM	#ProjectTeam pt
								INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
								AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
								AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
								WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
								UNION ALL	
								SELECT	dl.StartDate WorkingDate, 
										pt.[Committed] Committed,
										dl.Effort Effort
								FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
										INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
											AND dl.StartDate = dl.EndDate
								WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
										AND pt.IsDailyEffort = 1  												
							) tt
							GROUP BY  tt.WorkingDate, tt.Committed
						END 		
			END 		
	END 
	IF @ViewType='VW'
		BEGIN
			INSERT INTO #ResourceDemandEffort (ItemId, ResDemandDate,Effort)
			SELECT  tt.WorkgroupId, tt.WorkingDate, SUM(tt.Effort) FROM
			(
				SELECT  pt.WorkgroupId WorkgroupId, 
						wd.WorkingDate WorkingDate, 
						CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END Effort
				FROM	#ProjectTeam pt
				INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
				AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
				AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
				WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
				UNION ALL	
				SELECT	pt.WorkgroupId WorkgroupId, 
						dl.StartDate WorkingDate,
						dl.Effort Effort
				FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
						INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
							AND dl.StartDate = dl.EndDate
				WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
						AND pt.IsDailyEffort = 1  													
			) tt
			GROUP BY tt.WorkgroupId, tt.WorkingDate	
		END 
	IF (@ViewType)='VF'
		BEGIN
			INSERT INTO #ResourceDemandEffort (ItemId, ResDemandDate,Effort)
			SELECT  tt.FunctionId, tt.WorkingDate, SUM(tt.Effort) FROM
			(
				SELECT  pt.FunctionId FunctionId, 
						wd.WorkingDate WorkingDate, 
						CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END Effort
				FROM	#ProjectTeam pt
				INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
				AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
				AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
				WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
				UNION ALL 	
				SELECT	pt.FunctionId FunctionId, 
						dl.StartDate WorkingDate,
						dl.Effort Effort
				FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
						INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
							AND dl.StartDate = dl.EndDate
				WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
						AND pt.IsDailyEffort = 1  													
			) tt
			GROUP BY tt.FunctionId, tt.WorkingDate
		END 
	IF @ViewType IN ('VRW', 'VRF')		
		BEGIN
			INSERT INTO #ResourceDemandEffort (ItemId, ResDemandDate,Effort)
			SELECT  tt.ResourceId, tt.WorkingDate, SUM(tt.Effort) FROM  
			(
				SELECT  pt.ResourceId ResourceId, 
						wd.WorkingDate WorkingDate, 
						CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue)ELSE pt.RegularDateValue END Effort
				FROM	#ProjectTeam pt
				INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
				AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
				AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
				WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0 AND pt.IsDailyEffort = 0
				UNION ALL	
				SELECT	pt.ResourceId ResourceId, 
						dl.StartDate WorkingDate,
						dl.Effort Effort
				FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
						INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
							AND dl.StartDate = dl.EndDate
				WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
						AND pt.IsDailyEffort = 1  														
			) tt
			GROUP BY tt.ResourceId, tt.WorkingDate
		END 
	IF @ViewType='VRD'
		BEGIN
			INSERT INTO #ResourceDemandEffort (Type, ResDemandDate,Effort)
			SELECT  'PRJ', tt.WorkingDate, SUM(tt.Effort) FROM  
			(
				SELECT  wd.WorkingDate WorkingDate, 
						CASE WHEN  wd.WorkingDate =pt.LastDate THEN (pt.RegularDateValue+pt.LastDateValue) ELSE pt.RegularDateValue END Effort
				FROM	#ProjectTeam pt
				INNER JOIN #RMVWorkingDays wd  WITH (NOLOCK)  ON pt.PStart - 1 < wd.WorkingDate AND pt.PEnd + 1 > wd.WorkingDate AND @sDate -1 < wd.WorkingDate AND @eDate+1 > wd.WorkingDate
				AND NOT EXISTS(SELECT TOP 1 1 FROM #RMV_ResourceNonWorkingDays nwd WHERE nwd.ResourceId = pt.ResourceId AND nwd.NonWorkingDate = wd.WorkingDate) 
				AND NOT EXISTS(SELECT TOP 1 1 FROM #NonWorkingDays nwd WHERE nwd.EntityId = pt.WorkgroupId AND nwd.WorkingDate = wd.WorkingDate AND ISNULL(pt.ResourceId,@NUllId) = @NULlID )														
				WHERE   pt.PlannedHours> 0 AND  pt.WorkingDays> 0
				UNION ALL	
				SELECT	dl.StartDate WorkingDate,
						dl.Effort Effort
				FROM	ProjectTeamDailyAllocation dl  WITH (NOLOCK) 
						INNER JOIN #ProjectTeam pt ON dl.ProjectTeamId = pt.ProjectTeamId
							AND dl.StartDate = dl.EndDate
				WHERE	@sDate -1 < dl.StartDate AND  @eDate +1 > dl.StartDate 
						AND pt.IsDailyEffort = 1  													
			) tt
			GROUP BY tt.WorkingDate
		END 
	DELETE DemandItemRequest WHERE  RequestId=@RequestId
	IF NOT @TransactionXML IS NULL 
		EXEC SaveTransactionLog @@PROCID, @PM_StartLogTime, @TransactionXML
	
SET NOCOUNT OFF
END

GO
