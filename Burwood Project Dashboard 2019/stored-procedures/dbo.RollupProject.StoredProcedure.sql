USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[RollupProject]    Script Date: 10/10/2019 2:41:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[RollupProject]  @sProjectId  VARCHAR (38), @BillingOfficeId UNIQUEIDENTIFIER=NULL, @SChed  BIT=0x0
    AS 
  
SET ANSI_WARNINGS ON
SET NOCOUNT ON
SET XACT_ABORT ON
DECLARE
@MaxDate 		DATETIME,
@MinDate 		DATETIME,
@NOW			DATETIME,
@TIMECONTROL	CHAR(1),
@TODAY 			DATETIME,
@NullMinRun		DATETIME,
@SPName			Varchar(50),
@DebugLevel 	Integer,
@LogTime 		Datetime,
@StepTime		DateTime,
@StepText		VARCHAR(400),
@Rownum			Integer,
@NULLID 		UNIQUEIDENTIFIER,
@EmailId UNIQUEIDENTIFIER, @CalculateWorkingDays BIT, @SessionId UNIQUEIDENTIFIER
BEGIN TRY
SET @EmailID = '1D3BADB4-BABE-47AE-9C95-B2004021DD7E'
SET @NULLID= '{00000000-0000-0000-0000-000000000000}'
SET @CalculateWorkingDays=0x1 
IF OBJECT_ID('tempdb..#InputPrjID') IS NULL
BEGIN
	CREATE TABLE #InputPrjID
	(
		RollupProjectID UNIQUEIDENTIFIER,
		FPBillingOfficeID UNIQUEIDENTIFIER,
		SChed  BIT DEFAULT(0)
		PRIMARY KEY (RollupProjectID, FPBillingOfficeID)
	)
	INSERT #InputPrjID (RollupProjectID, FPBillingOfficeID, SChed)
	VALUES (@sProjectId, ISNULL(@BillingOfficeId,@NULLID), @SChed)
END
IF OBJECT_ID('tempdb..#Currollup') IS NOT NULL DROP TABLE #Currollup
CREATE TABLE #Currollup
		(
				ID 				UNIQUEIDENTIFIER, 
				obs 			VARCHAR(900),
				WBS 			NVARCHAR(255), 
				type 			CHAR(1),
				ProjectID 		UNIQUEIDENTIFIER,
				
				primary key (ID, projectID)
		)
IF OBJECT_ID('tempdb..#TEMPENTITY') IS NOT NULL DROP TABLE #TEMPENTITY
CREATE TABLE #TEMPENTITY
		 (
				FPBillingOfficeID	UNIQUEIDENTIFIER,
				FiscalPeriodID		UNIQUEIDENTIFIER,
				EntityID			UNIQUEIDENTIFIER,
				PlannedHours		NUMERIC(12,5),
				ActualHours			NUMERIC(12,5),
				RemainingHours		NUMERIC(12,5), 
				ForecastHours		NUMERIC(12,5),
				PlannedDays			NUMERIC(12,5),
				PlannedFTE			NUMERIC(12,5),
				ActualDays			NUMERIC(12,5), 
				ActualFTE			NUMERIC(12,5), 
				RemainingDays		NUMERIC(12,5),
				RemainingFTE		NUMERIC(12,5),
				PRIMARY KEY (FiscalPeriodID, EntityID)
		)
IF OBJECT_ID('tempdb..#TEMPENTITY1') IS NOT NULL DROP TABLE #TEMPENTITY1
CREATE TABLE #TEMPENTITY1
		 (
				FPBillingOfficeID	UNIQUEIDENTIFIER,
				FiscalPeriodID		UNIQUEIDENTIFIER,
				EntityID			UNIQUEIDENTIFIER,
				PlannedHours		NUMERIC(12,5),
				ActualHours			NUMERIC(12,5),
				RemainingHours		NUMERIC(12,5),
				ForecastHours		NUMERIC(12,5),
				PlannedDays			NUMERIC(12,5),
				PlannedFTE			NUMERIC(12,5),
				ActualDays			NUMERIC(12,5), 
				ActualFTE			NUMERIC(12,5), 
				RemainingDays		NUMERIC(12,5),
				RemainingFTE		NUMERIC(12,5)
		)
		
IF OBJECT_ID('tempdb..#PHASE') IS NOT NULL DROP TABLE #PHASE
CREATE TABLE #PHASE
		(
				ProjectID		UNIQUEIDENTIFIER,
				PHASEID			UNIQUEIDENTIFIER,
				WBS			VARCHAR(255)
		)
	 
	SET @NOW = GETDATE()
	SET @SPName = 'RollupProject'
	SET @DebugLevel = (SELECT TOP  1 ISNULL(DebugLevel,0) FROM SPControl WITH (NOLOCK)  WHERE SPName = @SPName)
	SET @LogTime = @NOW
	SET @TODAY=dbo.F_DropTime(@NOW)
	SET @MaxDate=DATEADD(yy,100, @NOW) 
	SET @MinDate=DATEADD(yy,-100, @NOW)
IF OBJECT_ID('tempdb..#TEMPFISCAL') IS NOT NULL DROP TABLE #TEMPFISCAL
CREATE TABLE #TEMPFISCAL
		(
				RollupProjectID		UNIQUEIDENTIFIER,
				fpID 			UNIQUEIDENTIFIER,
				FPBillingOfficeID 	UNIQUEIDENTIFIER
				PRIMARY KEY (RollupProjectID, fpID)
		)
IF OBJECT_ID('tempdb..#Assignment') IS NOT NULL DROP TABLE #Assignment	
CREATE TABLE #Assignment
		(
				TaskAssignmentID		UNIQUEIDENTIFIER ,
				ProjectId				UNIQUEIDENTIFIER, 
				ResourceId				UNIQUEIDENTIFIER,
				TaskId					UNIQUEIDENTIFIER,
				ID						BIGINT	DEFAULT -1, 
				PlannedStart			DATE, 
				PlannedFinish			DATE,
				RemainingHours			NUMERIC(12,5),
				DailyStartDate			DATE, 
				DailyEndDate			DATE, 
				ForecastStart			DATE, 
				ForecastFinish			DATE,  
				ActualStart				DATE, 
				ActualFinish			DATE,
				EarliestStart			DATE, 
				LatestFinish			DATE,
				ConversionToDay			NUMERIC (5,3) DEFAULT 0, 
				LoadingMethod			TINYINT,
				ProjectTeamRestriction	BIT DEFAULT 0, 
				TaskRestriction			BIT	DEFAULT 0,
				PRIMARY KEY(TaskAssignmentID)
		)
IF OBJECT_ID('tempdb..#FISCASSIGNMENT') IS NOT NULL DROP TABLE #FISCASSIGNMENT
CREATE TABLE #FISCASSIGNMENT 
		(		FiscalOfficeID			UNIQUEIDENTIFIER,
				FiscalYearID			UNIQUEIDENTIFIER,
				FiscalPeriodID			UNIQUEIDENTIFIER,
				ProjectID				UNIQUEIDENTIFIER,
				TaskID					UNIQUEIDENTIFIER,
				AssignmentID 			UNIQUEIDENTIFIER,
				ResourceId				UNIQUEIDENTIFIER,
				PlannedHours			NUMERIC(12,5) DEFAULT 0,
				ActualHours				NUMERIC(12,5) DEFAULT 0,
				RemainingHours			NUMERIC(12,5) DEFAULT 0,
				ForecastHours			NUMERIC(12,5) DEFAULT 0,
				StartDate				DATETIME,
				EndDate					DATETIME,
				WorkingDays				INT,	
				Inside					BIT		DEFAULT 0, 
				ProjectTeamRestriction	BIT DEFAULT 0, 
				TaskRestriction			BIT	DEFAULT 0,
				
				PRIMARY KEY (AssignmentID, FiscalOfficeID, FiscalPeriodID)
		)
			
IF OBJECT_ID('tempdb..#FISCALPROJECT') IS NOT NULL DROP TABLE #FISCALPROJECT
CREATE TABLE #FISCALPROJECT 
		(
				RollupProjectID			UNIQUEIDENTIFIER,
				FPBillingOfficeID		UNIQUEIDENTIFIER,
				SChed					BIT,
				fPeriodCount			INT DEFAULT(0),
				ProjectID				UNIQUEIDENTIFIER,
				MinDate					DATETIME,
				TasksExists				BIT DEFAULT 1,
				PastPeriodUpdated		BIT,
				PRIMARY KEY (RollupProjectID, ProjectID, FPBillingOfficeID)
		)
				
IF OBJECT_ID('tempdb..#UpdateTask') IS NOT NULL DROP TABLE #UpdateTask
CREATE TABLE #UpdateTask 
		(	
				ProjectID				UNIQUEIDENTIFIER ,
				TaskID 					UNIQUEIDENTIFIER ,
				Type					CHAR(1),
				Name					VARCHAR(255),
				ActualStart 			DATETIME,
				ActualFinish 			DATETIME,
				ActualHours 			NUMERIC (12,5) DEFAULT 0,
				ActualFTE				NUMERIC (12,5) DEFAULT 0,
				ActualDays				NUMERIC (12,5) DEfAULT 0,
				ForecastStart 			DATETIME,
				ForecastFinish 			DATETIME,
				RemainingHours 			NUMERIC (12,5) DEFAULT 0,
				RemainingDays			NUMERIC (12,5) DEFAULT 0,
				RemainingFTE			NUMERIC (12,5) DEFAULT 0,
				PlannedHours 			NUMERIC (12,5) DEFAULT 0, 
				PlannedDays				NUMERIC (12,5) DEFAULT 0, 
				PlannedFTE				NUMERIC (12,5) DEFAULT 0, 
				PlannedStart			DATETIME,
				PlannedFinish			DATETIME,
				OBS						VARCHAR(900),
				WBS						VARCHAR(255),
				UPDATED					BIT DEFAULT 0, 
				PlannedRemainingHours	NUMERIC (12,5) DEFAULT 0,
				PlannedRemainingDays	NUMERIC (12,5) DEFAULT 0,
				PlannedRemainingFTE		NUMERIC (12,5) DEFAULT 0, 
				MSP						BIT DEFAULT 0x0
				
 				PRIMARY KEY (ProjectID, TaskID) 		
		)
				
IF OBJECT_ID('tempdb..#TOTALASSIGNMENT') IS NOT NULL DROP TABLE #TOTALASSIGNMENT
CREATE TABLE #TOTALASSIGNMENT
		(
				FiscalOfficeID 		UNIQUEIDENTIFIER,
				AssignmentID		UNIQUEIDENTIFIER,
				RemainingHours		NUMERIC(12,5),
				WorkingDays			INT,
				PRIMARY KEY (FiscalOfficeID, AssignmentID)
		)
		
IF OBJECT_ID('tempdb..#ParentProject') IS NOT NULL DROP TABLE #ParentProject	
CREATE TABLE #ParentProject
		(
				RollupProjectID		UNIQUEIDENTIFIER,
				ProjectID		UNIQUEIDENTIFIER, 
				FPBillingOfficeID	UNIQUEIDENTIFIER
				PRIMARY KEY (RollupProjectID, ProjectID, FPBillingOfficeID)
		)
		
IF OBJECT_ID('tempdb..#Tasks') IS NOT NULL DROP TABLE #Tasks
CREATE TABLE #Tasks
		(
				TaskID 			UNIQUEIDENTIFIER,
				OBS 			VARCHAR(900),
				HasFPData		BIT DEFAULT(1)
				PRIMARY KEY (TaskID, HasFPData)
		)
		
IF OBJECT_ID('tempdb..#PlannedHours') IS NOT NULL DROP TABLE #PlannedHours	
CREATE TABLE #PlannedHours
		(
				FPHOURS				NUMERIC (12,5),
				FiscalOfficeID		UNIQUEIDENTIFIER,
				AssignmentID		UNIQUEIDENTIFIER,
				FPID				UNIQUEIDENTIFIER
		)
IF OBJECT_ID('tempdb..#FiscalTasks') IS NOT NULL DROP TABLE #FiscalTasks	
CREATE TABLE #FiscalTasks 
	(		
		FPBillingOfficeID		UNIQUEIDENTIFIER,
		FiscalPeriodId			UNIQUEIDENTIFIER,
		ProjectId				UNIQUEIDENTIFIER,
		TaskId					UNIQUEIDENTIFIER,
		PlannedHours			NUMERIC(12,5) DEFAULT 0,
		WorkingDays				INT DEFAULT 0,
		PlannedWorkingDaysCalc  BIT DEFAULT 0x0, 
		StartDate				DATETIME,
		EndDate					DATETIME, 
		AssociatedWorkgroup		UNIQUEIDENTIFIER
	)
 
IF OBJECT_ID('tempdb..#TOTALTask') IS NOT NULL DROP TABLE #TOTALTask	
CREATE TABLE #TOTALTask 
	(
		TaskId				UNIQUEIDENTIFIER,
		PlannedHours		NUMERIC(12,5) DEFAULT 0,
		WorkingDays			INT
	)
IF OBJECT_ID('tempdb..#ASSIGNMENTREMAINING') IS NOT NULL DROP TABLE #ASSIGNMENTREMAINING	
CREATE TABLE #ASSIGNMENTREMAINING 
	(
			ProjectId			UNIQUEIDENTIFIER,
			AssignmentId		UNIQUEIDENTIFIER,
			RemainingHours		NUMERIC(12,5),
			percentcomplete		NUMERIC(5,2)
	)
IF OBJECT_ID('tempdb..#PND_WorkingDaysConversionDay') IS NOT NULL DROP TABLE #PND_WorkingDaysConversionDay
CREATE TABLE #PND_WorkingDaysConversionDay 
	(
		LevelType			CHAR(1) NOT NULL,
		LevelTypeId			UNIQUEIDENTIFIER  NOT NULL,
		EntityId			UNIQUEIDENTIFIER  NOT NULL,
		FiscalPeriodId		UNIQUEIDENTIFIER,
		StartPeriod			DATETIME,
		EndPeriod			DATETIME,
		WorkingDays			INT DEFAULT 0,
		ConversionToDay		NUMERIC (5,3) DEfAULT 0, 
		ResourceId			UNIQUEIDENTIFIER
	)
	IF OBJECT_ID('tempdb..#CriticalPathProjects') IS NOT NULL DROP TABLE #CriticalPathProjects
	BEGIN
			
			
			CREATE TABLE #CriticalPathProjects
			(
				CriticalPathProjectId		UNIQUEIDENTIFIER, 
				PlannedStart				DATETIME	NULL, 
				MaxPlannedFinish			DATETIME NULL,
				AssociatedWorkgroup			UNIQUEIDENTIFIER,
				MAXWorkDate					DATETIME, 
				MAXID						INT DEFAULT 0
			)
		IF (@sProjectId IS NULL)
		BEGIN
			
			INSERT INTO #CriticalPathProjects(CriticalPathProjectId)
			SELECT i.RollupProjectID
			FROM #InputPrjID i 
			INNER JOIN Project p WITH(NOLOCK) ON i.RollupProjectID=p.ProjectId AND p.CriticalPath=0x1 AND p.RecalcCriticalPath=0x1
			WHERE NOT EXISTS(SELECT TOP 1 1 FROM ProjectFiscalRollup pf WITH (NOLOCK) WHERE pf.ProjectId = i.RollupProjectID AND pf.FPBillingOfficeId = i.FPBillingOfficeID AND pf.CPRollup=0x1)
			
			
			DELETE #InputPrjID
			FROM #InputPrjID
			INNER JOIN #CriticalPathProjects c ON c.CriticalPathProjectId=RollupProjectID	
		END	
	END
	
	
	IF OBJECT_ID('tempdb..#Task_Duration') IS NOT NULL DROP TABLE #Task_Duration 
	CREATE TABLE #Task_Duration 
	(
		ProjectId	UNIQUEIDENTIFIER,
		TaskId		UNIQUEIDENTIFIER, 
		WBS			VARCHAR(510),
		ChildCount	INT DEFAULT 0,
		Duration	SMALLINT DEFAULT 0
			
	)
	
	DELETE #InputPrjID
	FROM #InputPrjID ip
	INNER JOIN Project p WITH (NOLOCK)  ON p.ProjectId=ip.RollupProjectID AND p.RollupInProgress=0x1
		
	
	
	INSERT #FISCALPROJECT(RollupProjectID, FPBillingOfficeID, SChed, ProjectID)
	SELECT i.RollupProjectID, i.FPBillingOfficeID, i.SChed, i.RollupProjectID
	FROM #InputPrjID i
	UNION
	
	SELECT i.RollupProjectID, i.FPBillingOfficeID, i.SChed, p.ProjectID 
	FROM #InputPrjID i 
	INNER JOIN Project p WITH (NOLOCK) ON p.Deleted=0x0 AND p.RollupInProgress=0x0 AND LEN(p.OBS)>76 AND CHARINDEX(CONVERT(VARCHAR(38), i.RollupProjectID), p.OBS)>0 
			
	
	
	UPDATE Project SET RollupInProgress=0x1
	FROM Project p WITH (NOLOCK) 
	INNER JOIN 
	(SELECT DISTINCT Projectid FROM  #FISCALPROJECT) t ON t.ProjectID=p.ProjectId 
	
	
	INSERT	INTO #ASSIGNMENTREMAINING(ProjectId, AssignmentId)
	SELECT	DISTINCT ta.ProjectId, ta.TaskAssignmentId 
	FROM	TaskAssignment ta WITH (NOLOCK)
	INNER JOIN #FISCALPROJECT p ON p.ProjectId = ta.ProjectId AND ta.Deleted = 0
	AND ta.statusnotrequired = 1 and ISNULL(ta.percentcomplete, 0) < 100 
	UPDATE	#ASSIGNMENTREMAINING
	SET 
		remaininghours = case when isnull(ta.actualhours, 0) >= ta.plannedhours then 1.00 else ta.plannedhours - isnull(ta.actualhours, 0) end, 
		percentcomplete = 100 *
			case 
				when 
					(isnull(ta.actualhours,0)+case when isnull(ta.actualhours,0)>=ta.plannedhours then 1 else ta.plannedhours-isnull(ta.actualhours,0) end) = 0 
				then 
					null
				else 
					isnull(ta.actualhours,0)/(isnull(ta.actualhours,0)+case when isnull(ta.actualhours,0)>=ta.plannedhours then 1 else ta.plannedhours-isnull(ta.actualhours,0) end)
			end 
	FROM	#ASSIGNMENTREMAINING fa INNER JOIN TaskAssignment TA WITH (NOLOCK) ON ta.TaskAssignmentId = fa.AssignmentId 
	
	UPDATE	TaskAssignment 
	SET	
		
		
	UpdatedOn = @NOW, 
	ActualHours=ta.ActualHours
	FROM	TaskAssignment ta 
	INNER JOIN #ASSIGNMENTREMAINING fa on ta.ProjectId = fa.ProjectId and ta.TaskAssignmentId = fa.AssignmentId
	AND (ISNULL(fa.remaininghours, 0) <> ISNULL(ta.remaininghours, 0) OR ISNULL(fa.percentcomplete, 0) <> ISNULL(ta.percentcomplete, 0))
	UPDATE #FISCALPROJECT SET TasksExists=0
	FROM #FISCALPROJECT fp WHERE NOT EXISTS(SELECT 1 FROM Tasks t WITH (NOLOCK)  WHERE ProjectID =fp.ProjectID And Deleted = CAST(0 AS BIT))
	UPDATE Project  SET
	PlannedHours=0,  PlannedDays=0, PlannedFTE=0, 
	ActualStart=NULL,
	ActualFinish=NULL ,
	ActualHours=0, ActualDays=0, ActualFTE=0, 
	RollupForecastStart=NULL,
	RollupForecastFinish=NULL,
	RollupRemainingHours=0,RollupRemainingDays=0,  RollupRemainingFTE=0,
	PlannedRemainingHours=0, PlannedRemainingDays=0, PlannedRemainingFTE=0,
	Phase=NULL,
	RollupLastDate=@NOW,
	UpdatedOn = @NOW
	FROM Project p WITH (NOLOCK)  
	INNER JOIN #FISCALPROJECT fp ON p.ProjectID=fp.ProjectID AND fp.TasksExists=0
	
	DELETE AssignmentFiscalRollup
	FROM AssignmentFiscalRollup afr WITH (NOLOCK)
	INNER JOIN #FISCALPROJECT fp ON afr.FPBillingOfficeId = fp.FPBillingOfficeID AND afr.ProjectId = fp.ProjectID AND fp.TasksExists=0
	DELETE TaskFiscalRollup
	FROM TaskFiscalRollup tfr WITH (NOLOCK)
	INNER JOIN #FISCALPROJECT fp ON tfr.FPBillingOfficeId = fp.FPBillingOfficeID AND tfr.ProjectId = fp.ProjectID AND fp.TasksExists=0
	
	DELETE ProjectFiscalRollup
	FROM ProjectFiscalRollup pfr WITH (NOLOCK)
	INNER JOIN #FISCALPROJECT fp ON pfr.FPBillingOfficeId = fp.FPBillingOfficeID AND pfr.ProjectId = fp.ProjectID AND fp.TasksExists=0
	
IF  EXISTS( SELECT TOP 1 1 FROM  #FISCALPROJECT WHERE FPBillingOfficeID <>@NULLID)
BEGIN
			
			
			INSERT INTO #TEMPFISCAL (RollupProjectID, FPBillingOfficeID, fpID)
			SELECT DISTINCT p.RollupProjectID, p.FPBillingOfficeID ,pf.FiscalPeriodID   
			FROM ProjectFiscalRollup pf WITH (NOLOCK) 
			INNER JOIN #FISCALPROJECT p ON p.ProjectID = pf.ProjectID AND pf.FPBillingOfficeID=p.FPBillingOfficeID
			WHERE pf.CpRollup=CAST(1 AS  BIT) AND p.FPBillingOfficeID != @NULLID
		
			
				UPDATE p
				SET PastPeriodUpdated = 0x1
				FROM ProjectFiscalRollup pr WITH (NOLOCK) 
				INNER JOIN FiscalPeriod  fp WITH (NOLOCK) ON pr.FPBillingOfficeID=fp.BillingOfficeID AND fp.FiscalPeriodID=pr.FiscalPeriodID 
				INNER JOIN ProjectFiscalOffice po WITH (NOLOCK) ON po.FPBillingOfficeID=pr.FPBillingOfficeID AND pr.ProjectID=po.ProjectID
				INNER JOIN #FISCALPROJECT p ON p.FPBillingOfficeID = pr.FPBillingOfficeID AND pr.ProjectID=p.ProjectID AND po.ProjectID=p.ProjectID
				WHERE  fp.EndDate< @NOW AND pr.PastPeriodUpdated=0x0
				AND p.FPBillingOfficeID != @NULLID AND p.SChed = 0x1
					
					BEGIN
						INSERT INTO #TEMPFISCAL (RollupProjectID,fpID,FPBillingOfficeID)
						SELECT DISTINCT p.RollupProjectID, pr.FiscalPeriodID, p.FPBillingOfficeID 
						FROM ProjectFiscalRollup pr WITH (NOLOCK) 
						INNER JOIN FiscalPeriod  fp WITH (NOLOCK) ON fp.FiscalPeriodID=pr.FiscalPeriodID AND fp.BillingOfficeID=pr.FPBillingOfficeID
						INNER JOIN #FISCALPROJECT p ON p.ProjectID=pr.ProjectID AND pr.FPBillingOfficeID=p.FPBillingOfficeID AND p.PastPeriodUpdated = 0x1
						WHERE fp.EndDate< @NOW AND pr.PastPeriodUpdated=0x0 
						AND NOT EXISTS(SELECT TOP 1 * FROM #TEMPFISCAL tf  WHERE tf.fpID=pr.FiscalPeriodID AND tf.RollupProjectID = p.RollupProjectID)
						AND p.FPBillingOfficeID != @NULLID
						INSERT INTO PortfolioPeriodRecalc  (EntityID, EntityType, RefDate, PortfolioRecalcID)  
						SELECT DISTINCT fpr.ProjectID, 'PRJ', fp.StartDate, NEWID() 
						FROM ProjectFiscalRollup pr WITH (NOLOCK) 
						INNER JOIN FiscalPeriod  fp WITH (NOLOCK) ON fp.FiscalPeriodID=pr.FiscalPeriodID AND fp.BillingOfficeID=pr.FPBillingOfficeID
						INNER JOIN ProjectFiscalOffice po WITH (NOLOCK) ON po.FPBillingOfficeID=pr.FPBillingOfficeID AND po.ProjectID=pr.ProjectID
						INNER JOIN #FISCALPROJECT fpr ON pr.FPBillingOfficeID=fpr.FPBillingOfficeID  AND pr.ProjectID=fpr.ProjectID AND fpr.PastPeriodUpdated =0x1
						WHERE  fp.EndDate< @NOW AND pr.PastPeriodUpdated=0x0 AND pr.ProjectID=fpr.ProjectID
						AND NOT EXISTS(SELECT TOP 1 * FROM PortfolioPeriodRecalc ppc WHERE ppc.EntityID=fpr.ProjectID AND ppc.EntityType='PRJ' AND ppc.RefDate=fp.StartDate) 
						AND fpr.FPBillingOfficeID != @NULLID
						UNION
						SELECT DISTINCT fpr.ProjectID, 'PRJ', fp.EndDate, NEWID() 
						FROM ProjectFiscalRollup pr WITH (NOLOCK)
						INNER JOIN FiscalPeriod  fp WITH (NOLOCK) ON fp.FiscalPeriodID=pr.FiscalPeriodID AND fp.BillingOfficeID=pr.FPBillingOfficeID
						INNER JOIN ProjectFiscalOffice po WITH (NOLOCK) ON po.FPBillingOfficeID=pr.FPBillingOfficeID AND po.ProjectID=pr.ProjectID
						INNER JOIN #FISCALPROJECT fpr ON pr.FPBillingOfficeID=fpr.FPBillingOfficeID AND pr.ProjectID=fpr.ProjectID AND fpr.PastPeriodUpdated =0x1
						WHERE  fp.EndDate< @NOW AND pr.PastPeriodUpdated=0x0 AND pr.ProjectID=fpr.ProjectID
						AND NOT EXISTS(SELECT TOP 1 * FROM PortfolioPeriodRecalc ppc WHERE ppc.EntityID=fpr.ProjectID AND ppc.EntityType='PRJ' AND ppc.RefDate=fp.StartDate) 
						AND fpr.FPBillingOfficeID != @NULLID
						
					END
			
END 
	
	
	UPDATE Project SET RollupInProgress=0x0
	FROM Project p WITH (NOLOCK) 
	INNER JOIN 
	(SELECT DISTINCT Projectid FROM  #FISCALPROJECT WHERE RollupProjectID = ProjectID  AND TasksExists = 0x0) t ON t.ProjectID=p.ProjectId 
	
	DELETE #FISCALPROJECT WHERE RollupProjectID = ProjectID  AND TasksExists = 0x0
		UPDATE fp SET fPeriodCount = f.Cnt
		FROM #FISCALPROJECT fp 
		INNER JOIN (SELECT RollupProjectID, FPBillingOfficeID, COUNT(1) Cnt FROM #TEMPFISCAL GROUP BY RollupProjectID, FPBillingOfficeID) AS f
		 ON f.RollupProjectID = fp.RollupProjectID AND f.FPBillingOfficeID = fp.FPBillingOfficeID
		
		SET @NullMinRun = DATEADD(yy,100, @NOW)
		 
		
		 
		
			BEGIN
				UPDATE a 
				SET a.MinDate = b.MinDate
				FROM #FISCALPROJECT a
				INNER JOIN (SELECT fp.RollupProjectID, MinDate = MIN(ISNULL(p.RollupLastDate,DATEADD(yy,-100, @NOW))) 
							FROM #FISCALPROJECT fp
							INNER JOIN Project p WITH (NOLOCK) ON p.ProjectID=fp.ProjectID
							WHERE fp.fPeriodCount = 0 
							GROUP BY fp.RollupProjectID) b
				 ON a.RollupProjectID = b.RollupProjectID
				 WHERE a.fPeriodCount = 0 
				INSERT INTO #Tasks (TaskID, OBS, HasFPData) 
				SELECT DISTINCT t.TaskID, t.OBS, 0x0
				FROM Tasks  t WITH (NOLOCK) 
				INNER JOIN #FISCALPROJECT fp ON t.Deleted=0x0 AND t.ProjectID=fp.ProjectID 
  				WHERE ISNULL(t.UpdatedOn, @NullMinRun) > fp.MinDate
  				AND fp.fPeriodCount = 0
  				
				SELECT LEFT(t1.OBS, LEN(t1.OBS)-36) AS OBS, LEN(t1.OBS) AS OBSLength INTO #CTE_Tasks
				FROM #FISCALPROJECT fp1
				INNER JOIN Tasks t1 WITH (NOLOCK) ON t1.Deleted=0x1 AND t1.ProjectID=fp1.ProjectID AND t1.UpdatedOn>fp1.MinDate AND LEN(t1.OBS) > 36
				WHERE fp1.fPeriodCount=0x0
				
				CREATE NONCLUSTERED INDEX IX_CTE_Tasks ON #CTE_Tasks (OBS)
				
				INSERT INTO #Tasks (TaskID, OBS, HasFPData) 
				SELECT DISTINCT t.TaskID, t.OBS, 0x0
				FROM #CTE_Tasks t1 WITH (NOLOCK)  
				INNER JOIN Tasks t WITH (NOLOCK) 
					ON t.Deleted=0x0 
					AND NOT EXISTS(SELECT TOP 1 1 FROM #Tasks tt WHERE tt.TaskID=t.TaskID)
					AND EXISTS(SELECT TOP 1 1 FROM #FISCALPROJECT fp WHERE fp.fPeriodCount=0x0 AND t.ProjectID=fp.ProjectID)
					AND t1.OBSLength > LEN(t.OBS)
					AND CHARINDEX(LEFT(t.OBS, LEN(t.OBS)- 36), t1.OBS)> 0
				
				DROP TABLE #CTE_Tasks
				
				INSERT INTO #Tasks (TaskID, OBS, HasFPData) 
				SELECT DISTINCT t.TaskID, t.OBS, 0x0
				FROM Tasks  t WITH (NOLOCK)
				INNER JOIN #FISCALPROJECT fp ON t.ProjectID=fp.ProjectID
				INNER JOIN TaskAssignment ta WITH (NOLOCK) ON t.TaskID=ta.TaskID
				WHERE t.Deleted=0x0 AND ta.Deleted=0x0
  				AND ISNULL(ta.UpdatedOn, @NullMinRun) > fp.MinDate
				AND NOT EXISTS(SELECT TOP 1 * FROM #Tasks tt WHERE tt.TaskID=t.TaskID)
				AND fp.fPeriodCount = 0
				
				INSERT INTO #Tasks (TaskID, OBS, HasFPData)
				SELECT DISTINCT t.TaskID, t.OBS, 0x0
				FROM Tasks t WITH (NOLOCK) 
				INNER JOIN #Tasks tt ON tt.OBS LIKE t.OBS +'%'
				INNER JOIN #FISCALPROJECT fp ON t.ProjectID=fp.ProjectID
				WHERE t.Deleted=CAST(0 as bit) 
				AND NOT EXISTS(SELECT TOP 1 * FROM #Tasks tt WHERE tt.TaskID=t.TaskID)
				ANd fp.fPeriodCount = 0
			
				
			END 
		
		  
			IF EXISTS(SELECT TOP 1 1 FROM  #FISCALPROJECT WHERE  FPBillingOfficeID<>@NULLID)
			BEGIN 
				SELECT  @TIMECONTROL=CODE  FROM TimeControl WITH (NOLOCK)  WHERE Selected=1
		
				
				
				INSERT INTO #ParentProject (RollupProjectID, FPBillingOfficeID, ProjectID)
				SELECT DISTINCT fp.RollupProjectID, fp.FPBillingOfficeID, p1.ProjectID 
				FROM Project p1  WITH (NOLOCK)
				INNER JOIN Project p2 WITH (NOLOCK) ON CAST(p1.ProjectID AS VARCHAR(36))=RIGHT(LEFT(p2.OBS,37),36)  
				INNER JOIN #FISCALPROJECT fp ON p2.ProjectID=fp.ProjectID
				WHERE NOT EXISTS (SELECT 1 FROM #FISCALPROJECT fp2 WHERE fp.RollupProjectID = fp2.RollupProjectID AND fp2.ProjectID = p1.ProjectID AND fp2.fPeriodCount > 0)
				AND fp.fPeriodCount > 0
				UPDATE ProjectFiscalRollup SET CPRollup = 0x1 
				FROM
				#TEMPFISCAL  tf
				INNER JOIN #ParentProject p ON tf.FPBillingOfficeID = p.FPBillingOfficeID AND tf.RollupProjectID = p.RollupProjectID
				INNER JOIN ProjectFiscalRollup pr WITH (NOLOCK) ON pr.ProjectID=p.ProjectID AND pr.FiscalPeriodID=tf.FpID
				
				
				INSERT ProjectFiscalRollup (ProjectID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID , CPRollup)
				SELECT DISTINCT pr.ProjectID, fp.BillingOfficeID, fp.FiscalYearID, fp.FiscalPeriodID, 0x1
				FROM #ParentProject  pr 
				INNER JOIN  #TEMPFISCAL tf ON pr.RollupProjectID = tf.RollupProjectID AND pr.FPBillingOfficeID = tf.FPBillingOfficeID
				INNER JOIN FiscalPeriod fp WITH (NOLOCK)  ON tf.fpID=fp.FiscalPeriodID AND fp.Deleted=CAST(0 as bit)
				AND NOT EXISTS (SELECT TOP 1 * FROM ProjectFiscalRollup p WITH (NOLOCK)  WHERE p.ProjectID = pr.ProjectID AND p.FiscalPeriodID=fp.FiscalPeriodID)
			
					
				UPDATE u
				SET MinDate= x.LastRun
				FROM #FISCALPROJECT u
				INNER JOIN 
					(SELECT LastRun = MIN(pr.LastRun), fp.ProjectID, fp.FPBillingOfficeID
					FROM ProjectFiscalRollup pr WITH (NOLOCK)  
					INNER JOIN #FISCALPROJECT fp  ON pr.FPBillingOfficeID=fp.FPBillingOfficeID AND pr.ProjectID=fp.ProjectID
					WHERE fp.fPeriodCount > 0   AND NOT pr.LastRun IS NULL
					GROUP BY fp.FPBillingOfficeID, fp.ProjectID) AS x
				  ON u.FPBillingOfficeID = x.FPBillingOfficeID AND u.ProjectID = x.ProjectID
			
				
				UPDATE u
				SET MinDate= DATEADD(yy,-100, @NOW)
				FROM #FISCALPROJECT u
				WHERE  u.fPeriodCount> 0 AND MinDate IS NULL
				
				UPDATE #FISCALPROJECT  SET MInDate=tt.MInDate
				FROM #FISCALPROJECT fp
				CROSS APPLY
				(
					SELECT MIN(fp1.MInDate) MInDate, fp1.FPBillingOfficeID,fp1.RollupProjectID  FROM  #FISCALPROJECT fp1
					WHERE  fp1.FPBillingOfficeID=fp.FPBillingOfficeID  AND  fp1.RollupProjectID=fp.RollupProjectID
					GROUP BY  fp1.FPBillingOfficeID,fp1.RollupProjectID
					
				)tt 
				WHERE fp.fPeriodCount> 0
			
			
				INSERT INTO #Assignment (TaskAssignmentID, ProjectId, TaskId, ResourceId, PlannedStart, PlannedFinish, RemainingHours, ForecastStart, ForecastFinish, ActualStart, ActualFinish, 
				EarliestStart, LatestFinish, ConversionToDay, LoadingMethod)
				SELECT DISTINCT ta.TaskAssignmentID,  ta.ProjectId, ta.TaskId,  ta.ResourceId, ta.PlannedStart, ta.PlannedFinish,  ta.RemainingHours, ta.ForecastStart, ta.ForecastFinish, ta.ActualStart, ta.ActualFinish,
				CASE WHEN   ta.ForecastStart IS NOT NULL AND ta.ForecastStart < ta.PlannedStart THEN ta.ForecastStart ELSE ta.PlannedStart END, 
				CASE WHEN  ta.ForecastFinish IS NOT NULL AND ta.ForecastFinish > ta.PlannedFinish THEN  ta.ForecastFinish ELSE ta.PlannedFinish END,
				ta.ConversionToDay, ta.LoadingMethod
				FROM   #FISCALPROJECT fp 
				INNER JOIN   Tasks t WITH (NOLOCK) ON   t.ProjectID=fp.ProjectID AND fp.fPeriodCount > 0 AND t.Deleted=0x0
				INNER JOIN TaskAssignment ta WITH (NOLOCK) ON ta.Deleted=0x0 AND ta.TaskID=t.TaskID AND ISNULL( ta.UpdatedOn, @NullMinRun) > fp.MinDate
				
			
				
				INSERT INTO #Assignment (TaskAssignmentID, ProjectId, TaskId,ResourceId,  PlannedStart, PlannedFinish, RemainingHours, ForecastStart, ForecastFinish,  ActualStart, ActualFinish, 
				EarliestStart, LatestFinish,ConversionToDay, LoadingMethod)
				SELECT DISTINCT ta.TaskAssignmentID, ta.ProjectId, ta.TaskId, ta.ResourceId, ta.PlannedStart, ta.PlannedFinish, ta.RemainingHours,ta.ForecastStart, ta.ForecastFinish, ta.ActualStart, ta.ActualFinish,
				CASE WHEN   ta.ForecastStart IS NOT NULL AND ta.ForecastStart < ta.PlannedStart THEN ta.ForecastStart ELSE ta.PlannedStart END, 
				CASE WHEN  ta.ForecastFinish IS NOT NULL AND ta.ForecastFinish > ta.PlannedFinish THEN  ta.ForecastFinish ELSE ta.PlannedFinish END, 
				ta.ConversionToDay, ta.LoadingMethod
				FROM  #FISCALPROJECT fp
				INNER JOIN Tasks t WITH (NOLOCK) ON t.ProjectID=fp.ProjectID AND t.Deleted=0x0
				AND  fp.fPeriodCount > 0 AND fp.PastPeriodUpdated = 0x1
				INNER JOIN TaskAssignment ta WITH (NOLOCK) ON ta.Deleted=0x0 AND  ta.TaskID=t.TaskID
				AND NOT EXISTS(SELECT TOP 1 * FROM #Assignment a WHERE a.TaskAssignmentID=ta.TaskAssignmentID)
				UPDATE #Assignment  SET ActualStart=tt.ActualStart, ActualFinish=tt.ActualFinish
				FROM #Assignment  a 
				CROSS APPLY 
				(
					SELECT MIN (t.TimeDate) ActualStart, MAX(t.TimeDate) ActualFinish FROM Time t WITH (NOLOCK) WHERE t.TaskId=a.TaskId  
					AND t.ResourceId=a.ResourceId
				) tt
				WHERE (a.ActualStart IS NULL OR a.ActualFinish IS NULL )
				UPDATE #Assignment  SET ID=ISNULL(tt.MAXID,-1)
				FROM #Assignment a
				CROSS APPLY 
				(
					SELECT MAX(ID) MAXID FROM DemandItems  di WITH (NOLOCK) WHERE di.EntityId=a.TaskAssignmentID
				)tt
				
				UPDATE #Assignment SET EarliestStart = ActualStart WHERE ActualStart IS NOT NULL AND ActualStart < EarliestStart
				UPDATE #Assignment SET LatestFinish = ISNULL(ActualFinish,ActualStart)  WHERE ISNULL(ActualFinish,ActualStart) IS NOT NULL AND ISNULL(ActualFinish,ActualStart) > LatestFinish
				
				UPDATE  #Assignment SET DailyStartDate=tt.MINDemandDate, DailyEndDate=tt.MAXDemandDate
				FROM  #Assignment a
				CROSS APPLY
				(
						SELECT MIN(da.DemandDate)  MINDemandDate, MAX(da.DemandDate) MAXDemandDate FROM DailyDistribution da WITH (NOLOCK) WHERE da.iD=a.ID
				)tt
				WHERE a.ID > 0
			
				
				INSERT #FISCASSIGNMENT(FiscalOfficeID,FiscalYearID,FiscalPeriodID,  ProjectID, TaskID, AssignmentID, ResourceId,PlannedHours)
				SELECT DISTINCT f.BillingOfficeID, f.FiscalYearID, f.FiscalPeriodId, fp.ProjectID,a.TaskID, a.TaskAssignmentID, a.ResourceId,ISNULL(tt.SUMDemandHours,0)
				FROM  #Assignment a 
				INNER JOIN   #FISCALPROJECT fp  ON fp.ProjectId=a.ProjectId 
				INNER JOIN FiscalPeriod f WITH (NOLOCK) ON f.Deleted = 0x0 AND f.BillingOfficeId = fp.FPBillingOfficeID 
				AND ((f.StartDate BETWEEN a.DailyStartDate AND a.DailyEndDate) OR (f.EndDate BETWEEN a.DailyStartDate AND a.DailyEndDate) OR (a.DailyStartDate BETWEEN f.StartDate AND f.EndDate))
				CROSS APPLY 
				(
						SELECT SUM(da.DemandHours)  SUMDemandHours FROM DailyDistribution da WITH (NOLOCK) WHERE da.ID=a.ID AND da.DemandDate BETWEEN f.StartDate AND f.EndDate
				)tt
				WHERE a.ID > 0
			
				
				INSERT #FISCASSIGNMENT(FiscalOfficeID,FiscalYearID,FiscalPeriodID,  ProjectID, TaskID, AssignmentID, ResourceId)
				SELECT DISTINCT f.BillingOfficeID, f.FiscalYearID, f.FiscalPeriodId, fp.ProjectID,a.TaskID, a.TaskAssignmentID, a.ResourceId
				FROM  #Assignment a 
				INNER JOIN   #FISCALPROJECT fp  ON fp.ProjectId=a.ProjectId 
				INNER JOIN FiscalPeriod f WITH (NOLOCK) ON f.Deleted = 0x0 AND f.BillingOfficeId = fp.FPBillingOfficeID 
				AND ((f.StartDate BETWEEN a.EarliestStart AND a.LatestFinish) OR (f.EndDate BETWEEN a.EarliestStart AND a.LatestFinish) OR (a.EarliestStart BETWEEN f.StartDate AND f.EndDate))
				AND NOT EXISTS(SELECT TOP 1 1 FROM  #FISCASSIGNMENT fa WHERE fa.AssignmentID=a.TaskAssignmentID AND fa.FiscalPeriodID=f.FiscalPeriodId)
			
				IF UPPER(@TIMECONTROL)='A'
					BEGIN
						UPDATE #FISCASSIGNMENT SET ActualHours = tt.Actualhours
						FROM #FISCASSIGNMENT fa1 
						INNER JOIN
                           	(	SELECT fa.ProjectID, fa.TaskID,  fa.AssignmentID , fa.FiscalPeriodID,  SUM(t.RegularHours + t.OverTimeHours) AS ActualHours
								FROM  #FISCASSIGNMENT  fa
								INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON  fp.FiscalPeriodID=fa.FiscalPeriodID AND fp.Deleted=0x0
								INNER JOIN Time t WITH (NOLOCK)  ON  t.ResourceID=fa.ResourceID AND t.ProjectID=fa.ProjectID AND t.TaskID=fa.TaskID 
								AND t.ApprovalStatus='A' AND T.TimeDate BETWEEN fp.StartDate AND fp.EndDate
                  				GROUP BY fa.ProjectID, fa.TaskID,  fa.AssignmentID, fa.FiscalPeriodID
                  			) tt
                         ON tt.ProjectID= fa1.ProjectID AND tt.TaskID=fa1.TaskID AND tt.AssignmentID = fa1.AssignmentID AND tt.FiscalPeriodID = fa1.FiscalPeriodID						
					END
				 ELSE IF UPPER(@TIMECONTROL)='S'
					BEGIN
						UPDATE #FISCASSIGNMENT SET  ActualHours = tt.Actualhours
						FROM #FISCASSIGNMENT fa1 
						INNER JOIN
                            (
								SELECT fa.ProjectID, fa.TaskID,  fa.AssignmentID, fa.FiscalPeriodID,   SUM(t.RegularHours + t.OverTimeHours) AS ActualHours
								FROM  #FISCASSIGNMENT  fa
								INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON  fp.FiscalPeriodID=fa.FiscalPeriodID AND fp.Deleted=0x0
								INNER JOIN Time t WITH (NOLOCK)  ON  t.ResourceID=fa.ResourceID AND t.ProjectID=fa.ProjectID AND t.TaskID=fa.TaskID 
								AND  t.SubmittedForApproval=0x1 AND T.TimeDate BETWEEN fp.StartDate AND fp.EndDate
                  				GROUP BY fa.ProjectID, fa.TaskID,  fa.AssignmentID, fa.FiscalPeriodId
							)tt
                         ON tt.ProjectID= fa1.ProjectID AND tt.TaskID=fa1.TaskID AND tt.AssignmentID = fa1.AssignmentID AND tt.FiscalPeriodID = fa1.FiscalPeriodID		
					END
				ELSE	
					BEGIN
						UPDATE #FISCASSIGNMENT SET ActualHours = tt.Actualhours
						FROM #FISCASSIGNMENT fa1 
						INNER JOIN
                        (
							SELECT fa.ProjectID, fa.TaskID,  fa.AssignmentID, fa.FiscalPeriodID, SUM(t.RegularHours + t.OverTimeHours) AS ActualHours
							FROM  #FISCASSIGNMENT  fa
							INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON  fp.FiscalPeriodID=fa.FiscalPeriodID AND fp.Deleted=0x0
							INNER JOIN Time t WITH (NOLOCK)  ON  t.ResourceID=fa.ResourceID AND t.ProjectID=fa.ProjectID AND t.TaskID=fa.TaskID 
							AND T.TimeDate BETWEEN fp.StartDate AND fp.EndDate
              				GROUP BY fa.ProjectID, fa.TaskID,  fa.AssignmentID, fa.FiscalPeriodId
                  		) tt
						ON tt.ProjectID= fa1.ProjectID AND tt.TaskID=fa1.TaskID AND tt.AssignmentID = fa1.AssignmentID AND tt.FiscalPeriodID = fa1.FiscalPeriodID		
					END
					
				
				UPDATE #Assignment SET ProjectTeamRestriction =tt2.ProjectTeamRestriction,TaskRestriction=tt2.TaskRestriction 
				FROM #Assignment a 
				INNER JOIN Resources r WITH (NOLOCK)  ON a.ResourceId=r.ResourceId  AND r.ExemptFromResRequest=0x0 AND
				(a.PlannedStart > ISNULL(a.DailyStartDate,a.PlannedStart) OR ISNULL(a.DailyEndDate,a.PlannedFinish) > a.PlannedFinish)
				CROSS APPLY 
				(
					SELECT CASE WHEN bo.RestrictTaskAssignments =0x1 AND e.AllowPrjResourceRequest=0x1 THEN 0x1 ELSE 0x0 END ProjectTeamRestriction , 
					CASE WHEN  bo.RestrictTaskAssignments =0x1 AND e.AllowTaskResourceRequest=0x1 THEN 0x1 ELSE 0x0 END TaskRestriction
					FROM Project p WITH (NOLOCK) 
					INNER JOIN Engagement e WITH (NOLOCK) ON e.EngagementId=p.EngagementId
					INNER JOIN BillingOfficeInvoiceDefaults bo WITH (NOLOCK) ON bo.BillingOfficeId=e.BillingOfficeId
					WHERE p.ProjectId =a.ProjectId
				)tt2  
						
				
				
				
				UPDATE #FISCASSIGNMENT SET RemainingHours=fa.PlannedHours  FROM #FISCASSIGNMENT fa
				INNER JOIN FiscalPeriod fp WITH (NOLOCK)  ON fa.FiscalPeriodID=fp.FiscalPeriodID AND fp.Deleted=CAST(0 AS BIT) AND @TODAY <=fp.EndDate
				
				
				UPDATE #FISCASSIGNMENT SET WorkingDays=0, Inside =1,
				StartDate=CASE WHEN ta.ForecastStart < fp.StartDate THEN fp.StartDate ELSE ta.ForecastStart END,
				EndDate=CASE WHEN ta.ForecastFinish < fp.EndDate THEN ta.ForecastFinish ELSE fp.EndDate END
				FROM #FISCASSIGNMENT fa 
				INNER JOIN TaskAssignment ta WITH (NOLOCK) ON fa.AssignmentID=ta.TaskAssignmentID 
				INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fa.FiscalPeriodID=fp.FiscalPeriodID AND fp.Deleted=0
				UPDATE #FISCASSIGNMENT SET StartDate=fp.StartDate, EndDate=fp.EndDate, Inside =0 
				FROM #FISCASSIGNMENT fa
				INNER JOIN FiscalPeriod fp WITH (NOLOCK)  ON fa.FiscalPeriodID=fp.FiscalPeriodID AND fa.StartDate > fa.EndDate
				IF OBJECT_ID('tempdb..#cte_ResourceBoundaries', 'U') IS NOT NULL drop table #cte_ResourceBoundaries
				
				CREATE TABLE #cte_ResourceBoundaries 
				(
					ResourceId		UNIQUEIDENTIFIER, 
					StartDate		DATETIME,
					EndDate			DATETIME
				)
				IF OBJECT_ID('tempdb..#cte_NonWorkingDays', 'U') IS NOT NULL drop table #cte_NonWorkingDays
				CREATE TABLE #cte_NonWorkingDays
				(
					ResourceId uniqueidentifier,
					NonWorkingDate datetime
				)
				INSERT INTO  #cte_ResourceBoundaries (ResourceId, StartDate,EndDate	)
				SELECT ISNULL(tt.ResourceId, @NULLID), MIN(ta.PlannedStart),MAX(ta.PlannedFinish)
				FROM #FISCASSIGNMENT tt 
				INNER JOIN #Assignment ta WITH (NOLOCK) ON ta.TaskAssignmentId = tt.AssignmentID
				GROUP BY tt.ResourceId
				INSERT INTO #cte_NonWorkingDays (ResourceId, NonWorkingDate)
				SELECT  rb.ResourceId, rnw.NonWorkingDate 
				FROM #cte_ResourceBoundaries rb
				INNER JOIN ResourceNonWorkingDays rnw WITH (NOLOCK) ON rb.ResourceId=rnw.ResourceId
				AND rnw.NonWorkingDate BETWEEN rb.StartDate AND rb.EndDate
	
				CREATE  INDEX [IX_NonWorkingDays] ON #cte_NonWorkingDays 
				(
					[ResourceId] ASC,
					[NonWorkingDate] ASC
				)
				
				UPDATE #FISCASSIGNMENT SET    WorkingDays = DATEDIFF(dd, fa.StartDate, fa.EndDate) + 1 - (SELECT COUNT(1) 
				FROM #cte_NonWorkingDays NWD WITH (NOLOCK) WHERE NWD.ResourceId = ISNULL(ta.ResourceID,@NULLID) AND NWD.NonWorkingDate BETWEEN fa.StartDate AND fa.EndDate)				
				FROM   #FISCASSIGNMENT fa
				INNER JOIN #Assignment ta WITH (NOLOCK) ON ta.TaskAssignmentID = fa.AssignmentID
				INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fa.FiscalPeriodID = fp.FiscalPeriodID AND fp.Deleted = 0x0
				AND fp.EndDate >= @TODAY
				WHERE  fa.Inside=0x1
		
				TRUNCATE TABLE  #TOTALASSIGNMENT
				
				INSERT INTO  #TOTALASSIGNMENT (FiscalOfficeID, AssignmentID, RemainingHours, WorkingDays) 
				SELECT fa.FiscalOfficeID, fa.AssignmentID ,ta.RemainingHours,SUM(fa.WorkingDays) 
				FROM #FISCASSIGNMENT fa
				INNER JOIN  #Assignment ta  WITH (NOLOCK) ON 
				fa.AssignmentID=ta.TaskAssignmentID AND ISNULL(ta.RemainingHours,0) > 0
				GROUP by fa.FiscalOfficeID, fa.AssignmentID , ta.RemainingHours
				UPDATE #FISCASSIGNMENT SET ForecastHours=(ta.RemainingHours*fa.WorkingDays/ta.WorkingDays)   
				FROM #TOTALASSIGNMENT ta INNER JOIN #FISCASSIGNMENT fa ON fa.WorkingDays > 0 AND fa.AssignmentID=ta.AssignmentID 
				AND fa.FiscalOfficeID=ta.FiscalOfficeID AND ta.WorkingDays>0
				
				TRUNCATE TABLE  #PlannedHours
				INSERT INTO  #PlannedHours (FPHOURS	,FiscalOfficeID,AssignmentID,FPID)	
				SELECT SUM(fa.ForecastHours), fa.FiscalOfficeID, fa.AssignmentID, NULL 
				FROM #FISCASSIGNMENT fa
				INNER JOIN #Assignment ta WITH (NOLOCK)  ON fa.AssignmentID=ta.TaskAssignmentID 
				GROUP BY fa.FiscalOfficeID, fa.AssignmentID, ta.RemainingHours
				HAVING SUM(fa.ForecastHours) <> ta.RemainingHours
				UPDATE #PlannedHours SET FPID =fa.FiscalPeriodID FROM #FISCASSIGNMENT fa ,   #PlannedHours ph
				WHERE ph.FiscalOfficeID=fa.FiscalOfficeID AND ph.AssignmentID=fa.AssignmentID 
				AND EXISTS(SELECT 1 FROM  #FISCASSIGNMENT fa1
							INNER JOIN FiscalPeriod fp WITH (NOLOCK)  ON fa1.FiscalOfficeID=fa.FiscalOfficeID AND fa1.AssignmentID=fa.AssignmentID AND fa1.FiscalPeriodID=fp.FiscalPeriodID 
							AND fp.EndDate >= @TODAY AND fa1.ForecastHours > 0 
							INNER JOIN #FISCALPROJECT p ON p.FPBillingOfficeID = fa1.FiscalOfficeID AND fa1.ProjectID = p.ProjectID
							WHERE p.fPeriodCount > 0
							GROUP BY p.FPBillingOfficeID, p.RollupProjectID
							HAVING fa.StartDate=MAX(fa1.StartDate))
				
				UPDATE #FISCASSIGNMENT SET ForecastHours= CASE WHEN (fa.ForecastHours + (ta.RemainingHours - ph.FPHOURS)) > 0 
				THEN (fa.ForecastHours + (ta.RemainingHours - ph.FPHOURS))  ELSE 0 END
				FROM #FISCASSIGNMENT fa INNER JOIN  
				#PlannedHours  ph ON ph.FPID=fa.FiscalPeriodID  AND ph.AssignmentID=fa.AssignmentID
				INNER JOIN TaskAssignment ta WITH (NOLOCK) ON fa.AssignmentID=ta.TaskAssignmentID 
		
				UPDATE #FISCASSIGNMENT SET StartDate=NULL, EndDate=NULL, WorkingDays=0
				UPDATE #Assignment SET EarliestStart= CASE WHEN  ISNULL(DailyStartDate,PlannedStart) < PlannedStart THEN  DailyStartDate  ELSE PlannedStart END, 
				LatestFinish=  CASE  WHEN ISNULL(DailyEndDate,PlannedFinish) > PlannedFinish THEN DailyEndDate ELSE PlannedFinish END
				
				
				UPDATE #FISCASSIGNMENT SET StartDate=CASE WHEN a.EarliestStart < fp.StartDate THEN fp.StartDate ELSE a.EarliestStart END,
				EndDate= CaSE WHEN a.LatestFinish < fp.EndDate THEN a.LatestFinish ELSE fp.EndDate END
				FROM  #FISCASSIGNMENT fa 
				INNER JOIN #Assignment a ON a.TaskAssignmentID =fa.AssignmentID
				INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fa.FiscalPeriodID =fp.FiscalPeriodId  AND fp.Deleted=0x0
				AND ((fp.StartDate BETWEEN a.EarliestStart AND a.LatestFinish) OR (fp.EndDate BETWEEN a.EarliestStart AND a.LatestFinish) OR (a.EarliestStart BETWEEN fp.StartDate AND fp.EndDate))
				
				TRUNCATE TABLE  #PND_WorkingDaysConversionDay
			 
				
				INSERT  INTO #PND_WorkingDaysConversionDay (LevelType,LevelTypeId, EntityId, FiscalPeriodId, StartPeriod,EndPeriod)
				SELECT  'r',  fa.ResourceId, fa.AssignmentID, fa.FiscalPeriodID,fa.StartDate, fa.EndDate
				FROM   #FISCASSIGNMENT fa WHERE fa.StartDate IS NOT NULL AND  fa.EndDate IS NOT NULL 
				
				EXEC dbo.PND_WorkingDaysConversionDay @CalculateWorkingDays, 0x0
				
				UPDATE #FISCASSIGNMENT SET WorkingDays=CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE  pnd.WorkingDays END
				FROM  #FISCASSIGNMENT fa 
				INNER JOIN  #PND_WorkingDaysConversionDay pnd ON  pnd.EntityId=fa.AssignmentID 
				AND pnd.FiscalPeriodId= fa.FiscalPeriodID
				BEGIN TRAN AFR_TRN
			
				DELETE   AssignmentFiscalRollup  FROM  AssignmentFiscalRollup ar WITH (NOLOCK) 
				INNER JOIN #FISCASSIGNMENT fa ON ar.TaskAssignmentID=fa.AssignmentID AND ar.FPBillingOfficeID=fa.FiscalOfficeID
				
				
				INSERT INTO AssignmentFiscalRollup
				(ProjectID, TaskID, TaskAssignmenTID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID, PlannedHours, ActualHours, RemainingHours, ForecastHours, 
				PlannedDays, PlannedFTE, ActualDays,ActualFTE,RemainingDays,RemainingFTE, WorkingDays)
				SELECT fa.ProjectID, fa.TaskID, fa.AssignmentID, fa.FiscalOfficeID, fa.FiscalYearID, fa.FiscalPeriodID, fa.PlannedHours, fa.ActualHours,
				fa.RemainingHours, fa.ForecastHours, 0 PlannedDays, 0 PlannedFTE, 0 ActualDays, 0 ActualFTE, 0 RemainingDays, 0 RemainingFTE, 0 WorkingDays
				FROM #FISCASSIGNMENT fa
				INNER JOIN #Assignment a  ON fa.AssignmentID=a.TaskAssignmentID AND a.ConversionToDay<=0 
				AND ((fa.PlannedHours<>0) OR (fa.ActualHours<>0) OR (fa.RemainingHours<>0) OR (fa.ForecastHours<>0))
				UNION ALL
				SELECT fa.ProjectID, fa.TaskID, fa.AssignmentID, fa.FiscalOfficeID, fa.FiscalYearID, fa.FiscalPeriodID, fa.PlannedHours, fa.ActualHours,
					fa.RemainingHours, fa.ForecastHours, 
					(fa.PlannedHours/a.ConversionToDay),
					0, 
					(fa.ActualHours/a.ConversionToDay),
					0, 
					(fa.RemainingHours/a.ConversionToDay),
					0,fa.WorkingDays
				FROM #FISCASSIGNMENT fa 
				INNER JOIN #Assignment a  ON fa.AssignmentID=a.TaskAssignmentID AND a.ConversionToDay >0 AND fa.WorkingDays<=0 
				AND ((fa.PlannedHours<>0) OR (fa.ActualHours<>0) OR (fa.RemainingHours<>0) OR (fa.ForecastHours<>0))
				UNION ALL
				SELECT fa.ProjectID, fa.TaskID, fa.AssignmentID, fa.FiscalOfficeID, fa.FiscalYearID, fa.FiscalPeriodID, fa.PlannedHours, fa.ActualHours,
					fa.RemainingHours, fa.ForecastHours, 
					(fa.PlannedHours/a.ConversionToDay),
					fa.PlannedHours/(a.ConversionToDay * fa.WorkingDays), 
					(fa.ActualHours/a.ConversionToDay),
					fa.ActualHours/(a.ConversionToDay * fa.WorkingDays), 
					(fa.RemainingHours/a.ConversionToDay),
					fa.RemainingHours/(a.ConversionToDay * fa.WorkingDays), fa.WorkingDays
				FROM #FISCASSIGNMENT fa 
				INNER JOIN #Assignment a  ON fa.AssignmentID=a.TaskAssignmentID AND a.ConversionToDay >0 AND fa.WorkingDays >0 
				AND ((fa.PlannedHours<>0) OR (fa.ActualHours<>0) OR (fa.RemainingHours<>0) OR (fa.ForecastHours<>0))
				COMMIT TRAN AFR_TRN
				SELECT ta.TaskAssignmentId, ta.ResourceId, CASE WHEN  ta.PlannedStart > a.DailyStartDate THEN a.DailyStartDate  ELSE ta.PlannedStart END PlannedStart, 
				CASE  WHEN ta.PlannedFinish < a.DailyEndDate THEN a.DailyEndDate  ELSE ta.PlannedFinish END PlannedFinish, CAST(0 AS INT) WorkingDays
				INTO #TaskAssignment
				FROM  TaskAssignment ta WITH (NOLOCK) 
				INNER JOIN  #Assignment a ON ta.TaskAssignmentId=a.TaskAssignmentID AND a.ProjectTeamRestriction=0x0 and a.TaskRestriction=0x0
				AND (ta.PlannedStart > a.DailyStartDate OR ta.PlannedFinish < a.DailyEndDate)
				IF EXISTS(SELECT TOP 1 1 FROM #TaskAssignment) 
				BEGIN 
					TRUNCATE TABLE  #PND_WorkingDaysConversionDay
			 
					INSERT  INTO #PND_WorkingDaysConversionDay (LevelType,LevelTypeId, EntityId, StartPeriod,EndPeriod)
					SELECT  'r',  ta.ResourceId, ta.TaskAssignmentId, ta.PlannedStart, ta.PlannedFinish
					FROM   #TaskAssignment ta 
					EXEC dbo.PND_WorkingDaysConversionDay @CalculateWorkingDays, 0x0
				
					UPDATE #TaskAssignment SET WorkingDays=CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE  pnd.WorkingDays END
					FROM  #TaskAssignment ta 
					INNER JOIN  #PND_WorkingDaysConversionDay pnd ON  pnd.EntityId=ta.TaskAssignmentId 
					
					UPDATE TaskAssignment   SET  PlannedStart=a.PlannedStart, PlannedFinish=a.PlannedFinish,  WorkingDays=a.WorkingDays
					FROM  TaskAssignment ta WITH (NOLOCK) 
					INNER JOIN #TaskAssignment a ON ta.TaskAssignmentId=a.TaskAssignmentID 
					
				END 
		
				UPDATE TaskAssignment  SET PlannedRemainingHours= t.RemainingHours, PlannedRemainingDays=t.RemainingDays, 
				PlannedRemainingFTE=t.RemainingFTE, ActualHours=ta.Actualhours
				FROM TaskAssignment ta WITH (NOLOCK) 
				INNER JOIN (SELECT DISTINCT AssignmentId FROM  #FISCASSIGNMENT)tt ON ta.TaskAssignmentId=tt.AssignmentID
				CROSS APPLY 
				(
					SELECT  af.TaskAssignmentId, SUM(af.RemainingHours)  RemainingHours , SUM(af.RemainingDays)  RemainingDays , SUM(af.RemainingFTE)  RemainingFTE
					FROM AssignmentFiscalRollup af WITH (NOLOCK) 
					INNER JOIN  ProjectFiscalOffice po WITH (NOLOCK) ON af.TaskAssignmentId=ta.TaskAssignmentId AND po.ProjectId=af.ProjectId 
					AND po.FPBillingOfficeId=af.FPBillingOfficeId 
					GROUP BY  af.TaskAssignmentId
				) t 	
				
				
				UPDATE TaskAssignment 
				SET PlannedRemainingHours = 0, 
					PlannedRemainingDays  = 0, 
					PlannedRemainingFTE   = 0, 
					ActualHours=ta.Actualhours
				FROM TaskAssignment ta WITH (NOLOCK) 
				INNER JOIN 
				 (
				   SELECT DISTINCT AssignmentId 
				   FROM #FISCASSIGNMENT
				  )tt ON    ta.TaskAssignmentId = tt.AssignmentID
				        AND ta.PlannedHours     = 0
				
				INSERT #TEMPFISCAL (RollupProjectID, fpID, FPBillingOfficeID)
				SELECT DISTINCT p.RollupProjectID, fa.FiscalPeriodID, p.FPBillingOfficeID  FROM #FISCASSIGNMENT  fa 
				INNER JOIN #FISCALPROJECT p ON fa.ProjectID = p.ProjectID AND p.fPeriodCount > 0 AND fa.FiscalOfficeID = p.FPBillingOfficeID
				WHERE NOT EXISTS (SELECT TOP 1 * FROM #TEMPFISCAL tf WHERE tf.RollupProjectID= p.RollupProjectID AND tf.fpID=fa.FiscalPeriodID)
				
				INSERT INTO #Tasks(TaskID) SELECT DISTINCT fa.TaskID FROM  #FISCASSIGNMENT fa 
				
				INSERT INTO #Tasks (TaskID) SELECT DISTINCT tr.TaskID FROM TaskFiscalRollup tr WITH (NOLOCK) 
				INNER JOIN #FISCALPROJECT fp ON tr.ProjectID= fp.ProjectID 
				AND NOT EXISTS(SELECT TOP 1 1 From Tasks t WITH (NOLOCK)  WHERE t.Deleted=0x0 AND t.TaskID=tr.TaskID)
				AND NOT EXISTS (SELECT 1 FROM #Tasks tt WHERE tt.TaskID =tr.TaskID AND tt.HasFPData =0x1)
				AND fp.fPeriodCount > 0
				
				
				INSERT INTO #Tasks (TaskID) SELECT DISTINCT t.TaskID 
				FROM #FISCALPROJECT fp
				INNER JOIN Tasks t WITH (NOLOCK) ON t.ProjectID= fp.ProjectID AND t.Deleted=CAST(0 as bit) 
				AND ISNULL(t.UpdatedOn, @NullMinRun) > fp.MinDate
				AND NOT EXISTS(SELECT 1 FROM #Tasks tt WHERE tt.TaskID=t.TaskID AND tt.HasFPData =0x1)
				AND fp.fPeriodCount > 0
				
				UPDATE tt SET OBS=t.OBS FROM #Tasks tt INNER JOIN Tasks t ON tt.TaskID=t.TaskID WHERE tt.OBS IS NULL
				INSERT INTO #Tasks (TaskID, OBS)
				SELECT DISTINCT t.TaskID,  t.OBS FROM  #FISCALPROJECT fp
				INNER JOIN Tasks t WITH (NOLOCK)  ON t.ProjectID=fp.ProjectID  AND t.Deleted=CAST(0 as bit) AND fp.fPeriodCount > 0
				INNER JOIN  #Tasks tt ON tt.OBS LIKE t.OBS +'%'  AND tt.HasFPData =0x1
				AND NOT EXISTS(SELECT 1 FROM #Tasks tt WHERE tt.TaskID=t.TaskID AND tt.HasFPData =0x1)
				
				
				DELETE TaskFiscalRollup  FROM  TaskFiscalRollup tf WITH (NOLOCK) 
				INNER JOIN #Tasks tt ON  tt.TaskID=tf.TaskID  AND  tt.HasFPData =0x1 
				INNER JOIN #FISCALPROJECT fp ON tf.FPBillingOfficeID=fp.FPBillingOfficeID AND tf.ProjectID= fp.ProjectID
				
								
				
                INSERT INTO #FiscalTasks (FPBillingOfficeID, FiscalPeriodId, ProjectId, TaskId, StartDate, EndDate, AssociatedWorkgroup)
				SELECT DISTINCT p.FPBillingOfficeID, fp.FiscalPeriodId, p.ProjectId, t.TaskId, 
				CASE WHEN t.PlannedStart < fp.StartDate THEN fp.StartDate ELSE t.PlannedStart END,
				CASE WHEN t.PlannedFinish< fp.EndDate THEN t.PlannedFinish ELSE fp.EndDate END, 
				ISNULL(e.AssociatedWorkgroup, @NULLID)
				FROM #FISCALPROJECT p
				INNER JOIN Project pr WITH (NOLOCK) ON p.ProjectID=pr.ProjectId
				INNER JOIN Engagement e WITH (NOLOCK) ON pr.EngagementId=e.EngagementId
				INNER JOIN Tasks t WITH (NOLOCK) ON t.Deleted=0x0 AND t.ProjectId=p.ProjectId AND t.OpenTask=0x0
					AND NOT EXISTS(SELECT TOP 1 1 FROM taskassignment ta WITH (NOLOCK) WHERE ta.taskid=t.taskid AND ta.deleted=0x0)
					AND NOT EXISTS
						(	
							SELECT TOP 1 1
							FROM #Tasks ut
							INNER JOIN Tasks t0 WITH (NOLOCK) ON ut.taskID = t0.taskID AND t.taskid=t0.taskid
							CROSS APPLY
							(
								SELECT TOP 1 t1.TaskId FROM Tasks t1 WITH (NOLOCK) WHERE t0.ProjectID=t1.ProjectID AND t1.Deleted=0x0
									AND LEN(t1.WBS) > LEN(t0.WBS)
									AND t1.WBS LIKE t0.WBS + N'.%'
									AND t1.WBS NOT LIKE (t0.WBS + N'.%.%')
							) tt1
							WHERE 
								ut.TaskID = t.TaskId
								AND NOT EXISTS(SELECT TOP 1 1 FROM SubProject s WITH (NOLOCK) INNER JOIN Project p WITH (NOLOCK) ON s.SubProjectID=p.ProjectID AND p.Deleted=0x0 AND s.TaskID=t0.TaskID)
						)
				INNER JOIN #Tasks tt ON t.TaskId=tt.TaskId 
				INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fp.BillingOfficeId=p.FPBillingOfficeId AND fp.Deleted=0x0
 					AND (
 							fp.StartDate BETWEEN t.PlannedStart AND t.PlannedFinish
 							OR
 							fp.EndDate BETWEEN t.PlannedStart AND t.PlannedFinish
							OR
							t.PlannedStart BETWEEN fp.StartDate AND fp.EndDate
						)
								
			
				TRUNCATE TABLE  #PND_WorkingDaysConversionDay
			
				INSERT  INTO #PND_WorkingDaysConversionDay (LevelType,LevelTypeId, EntityId, FiscalPeriodId, StartPeriod,EndPeriod)
				SELECT  CASE WHEN ft.AssociatedWorkgroup=@NULLID THEN 's' ELSE 'w' END, 
				ft.AssociatedWorkgroup, ft.TaskId, ft.FiscalPeriodID,ft.StartDate, ft.EndDate
				FROM #FiscalTasks ft 
				EXEC dbo.PND_WorkingDaysConversionDay @CalculateWorkingDays, 0x0
			
				UPDATE #FiscalTasks SET WorkingDays=CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE  pnd.WorkingDays END
				FROM  #FiscalTasks ft 
				INNER JOIN  #PND_WorkingDaysConversionDay pnd ON  pnd.EntityId=ft.TaskId 
				AND pnd.FiscalPeriodId= ft.FiscalPeriodID
				
		
				UPDATE ft SET   ft.WorkingDays = DATEDIFF(dd, ft.StartDate, ft.EndDate) + 1  
				FROM #FiscalTasks  ft WHERE NOT EXISTS
				(SELECT  TOP 1 1 FROM #FiscalTasks ft2 WHERE ft2.WorkingDays >0 AND ft.TaskId=ft2.TasKid)
				
				INSERT INTO #TOTALTask (TaskId, PlannedHours, WorkingDays) 
				SELECT t.TaskId, t.PlannedHours, tt.WorkingDays
				FROM (SELECT ft.ProjectId, ft.TaskId, SUM(ft.WorkingDays) WorkingDays FROM #FiscalTasks ft GROUP BY ft.ProjectId,ft.TaskId) tt
				INNER JOIN Tasks t WITH (NOLOCK)  ON t.ProjectId=tt.ProjectId AND tt.TaskId=t.TaskId AND t.PlannedHours > 0
				
				UPDATE #FiscalTasks SET PlannedHours=(t.PlannedHours*ft.WorkingDays/t.WorkingDays)
				FROM #TOTALTask t
			    INNER JOIN #FiscalTasks ft  ON t.TaskId=ft.TaskId AND t.WorkingDays>0
				
				UPDATE #FiscalTasks SET PlannedHours =ft.PlannedHours+tt.RemainingHours
				FROM #FiscalTasks ft INNER JOIN 
				(
					SELECT tt.RemainingHours, ft.TaskId, MAX(ft.StartDate) StartDate FROM #FiscalTasks ft 
					INNER JOIN 
					(	SELECT (t.PlannedHours - SUM(ft.PlannedHours)) RemainingHours, ft.TaskId
						FROM #FiscalTasks ft
						INNER JOIN #TOTALTask t ON ft.TaskId=t.TaskId
						GROUP BY ft.TaskId , t.PlannedHours
						HAVING SUM(ft.PlannedHours) <> t.PlannedHours
					) tt  ON ft.TaskId=tt.TaskId AND ft.PlannedHours + RemainingHours > 0 
					GROUP BY ft.TaskId,  tt.RemainingHours
				) tt ON tt.TaskId=ft.TaskId AND ft.StartDate=tt.StartDate
				
 				DELETE tfr
				FROM TaskFiscalRollup tfr
				INNER JOIN #FiscalTasks ft
				ON ft.FiscalPeriodId = tfr.FiscalPeriodId AND ft.TaskId = tfr.TaskId 
				AND ft.ProjectID = tfr.ProjectID AND ft.FPBillingOfficeID = tfr.FPBillingOfficeID
				
				
				INSERT INTO TaskFiscalRollup(ProjectId, TaskId, FPBillingOfficeId, FiscalYearId, FiscalPeriodId, PlannedHours, ActualHours,
				RemainingHours, ForecastHours,  PlannedDays,PlannedFTE,ActualDays, ActualFTE,RemainingDays, RemainingFTE)
				SELECT  ft.ProjectId, ft.TaskId, fp.BillingOfficeId, fp.FiscalYearId, fp.FiscalPeriodId, ft.PlannedHours,
				0 actualHours,0 remainingHours, 0 forecastHours, 
				CASE WHEN t.ConversionToDay=0 THEN 0 ELSE (ft.PlannedHours/t.ConversionToDay) END, CASE WHEN (t.ConversionToDay=0 OR ft.WorkingDays =0) THEN 0 ELSE ft.PlannedHours/(t.ConversionToDay * ft.WorkingDays) END,
				0 ActualDays, 0 ActualFTE, 0 RemainingDays, 0 RemainingFTE
				FROM #FiscalTasks  ft 
				INNER JOIN Tasks t WITH (NOLOCK)  ON t.TaskId=ft.TaskId
				INNER  JOIN FiscalPeriod fp WITH (NOLOCK)  ON fp.FiscalPeriodId=ft.FiscalPeriodId
				WHERE ft.plannedHours!=0   
             
                TRUNCATE TABLE #FiscalTasks
				TRUNCATE TABLE #TOTALTask
				
				
				
				
			
				
				
				INSERT INTO TaskFiscalRollup
				(ProjectID, TaskID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID, PlannedHours, ActualHours,
				RemainingHours, ForecastHours, 
				PlannedDays,PlannedFTE,ActualDays, ActualFTE,RemainingDays, RemainingFTE)
				SELECT ar.ProjectID, ar.TaskID, ar.FPBillingOfficeID, ar.FiscalYearID, ar.FiscalPeriodID,
				SUM(ar.PlannedHours),  SUM(ar.ActualHours), SUM(ar.RemainingHours), SUM(ar.ForecastHours),
				SUM(ar.PlannedDays),SUM(ar.PlannedFTE), SUM(ar.ActualDays), SUM(ar.ActualFTE), 
				SUM(ar.RemainingDays), SUM(ar.RemainingFTE)
				FROM  
				(SELECT DISTINCT ProjectId,  FPBillingOfficeID FROM  #FISCALPROJECT fsp WHERE fsp.fPeriodCount > 0 ) fp
				INNER JOIN AssignmentFiscalRollup ar WITH (NOLOCK) ON   ar.ProjectID =fp.ProjectID AND ar.FPBillingOfficeID=fp.FPBillingOfficeID
				INNER JOIN #Tasks tt ON  ar.TaskID=tt.TaskID  AND  tt.HasFPData =0x1
				INNER JOIN Tasks t WITH (NOLOCK)   ON  t.Deleted=CAST(0 as bit) AND t.TaskID=tt.TaskID  AND t.OpenTask =0x0
				AND EXISTS(SELECT 1 FROM #FISCALPROJECT fsp WHERE fsp.fPeriodCount > 0 AND ar.ProjectID =fsp.ProjectID AND ar.FPBillingOfficeID=fsp.FPBillingOfficeID)
				GROUP BY  ar.ProjectID, ar.TaskID,  ar.FPBillingOfficeID, ar.FiscalYearID, ar.FiscalPeriodID,
				t.PlannedStart, t.PlannedFinish
					
				
				
				INSERT INTO #FiscalTasks (FPBillingOfficeID, FiscalPeriodId,ProjectId,TaskId, StartDate,EndDate, AssociatedWorkgroup)
				SELECT DISTINCT p.FPBillingOfficeID, fp.FiscalPeriodId, p.ProjectId, t.TaskId, 
				CASE WHEN t.PlannedStart < fp.StartDate THEN fp.StartDate ELSE t.PlannedStart END,
				CASE WHEN t.PlannedFinish< fp.EndDate THEN t.PlannedFinish ELSE fp.EndDate END, ISNULL(e.AssociatedWorkgroup, @NULLID)
				FROM #FISCALPROJECT p
				INNER JOIN Project pr WITH (NOLOCK) ON p.ProjectID=pr.ProjectId
				INNER JOIN Engagement e WITH (NOLOCK) ON pr.EngagementId=e.EngagementId
				INNER JOIN Tasks t WITH (NOLOCK) ON t.Deleted=0 AND t.ProjectId=p.ProjectId AND t.OpenTask=0x1
				INNER JOIN #Tasks tt ON t.TaskId=tt.TaskId 
				INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fp.BillingOfficeId=p.FPBillingOfficeId  AND fp.Deleted=0
				AND ((fp.StartDate BETWEEN t.PlannedStart AND t.PlannedFinish) OR (fp.EndDate BETWEEN t.PlannedStart AND t.PlannedFinish) 
				OR (t.PlannedStart BETWEEN fp.StartDate AND fp.EndDate))
				
				
				
				TRUNCATE TABLE  #PND_WorkingDaysConversionDay
			
				INSERT  INTO #PND_WorkingDaysConversionDay (LevelType,LevelTypeId, EntityId, FiscalPeriodId, StartPeriod,EndPeriod)
				SELECT  CASE WHEN ft.AssociatedWorkgroup=@NULLID THEN 's' ELSE 'w' END, 
				ft.AssociatedWorkgroup, ft.TaskId, ft.FiscalPeriodID,ft.StartDate, ft.EndDate
				FROM #FiscalTasks ft 
				EXEC dbo.PND_WorkingDaysConversionDay @CalculateWorkingDays, 0x0
				
				UPDATE #FiscalTasks SET WorkingDays=CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE  pnd.WorkingDays END, 
				PlannedWorkingDaysCalc=0x1 
				FROM  #FiscalTasks ft 
				INNER JOIN  #PND_WorkingDaysConversionDay pnd ON  pnd.EntityId=ft.TaskId 
				AND pnd.FiscalPeriodId= ft.FiscalPeriodID
				
				
				
				UPDATE ft SET   ft.WorkingDays = DATEDIFF(dd, ft.StartDate, ft.EndDate) + 1  
				FROM #FiscalTasks  ft WHERE NOT EXISTS
				(SELECT  TOP 1 1 FROM #FiscalTasks ft2 WHERE ft2.WorkingDays >0 AND ft.TaskId=ft2.TasKid)
	
				INSERT INTO #TOTALTask (TaskId, PlannedHours, WorkingDays) 
				SELECT t.TaskId, t.PlannedHours, tt.WorkingDays
				FROM (SELECT ft.ProjectId, ft.TaskId, SUM(ft.WorkingDays) WorkingDays FROM #FiscalTasks ft GROUP BY ft.ProjectId,ft.TaskId) tt
				INNER JOIN Tasks t WITH (NOLOCK)  ON t.ProjectId=tt.ProjectId AND tt.TaskId=t.TaskId AND t.PlannedHours > 0
				
				UPDATE #FiscalTasks SET PlannedHours=(t.PlannedHours*ft.WorkingDays/t.WorkingDays)
				FROM #TOTALTask t
			    INNER JOIN #FiscalTasks ft  ON t.TaskId=ft.TaskId AND t.WorkingDays>0
	
				UPDATE #FiscalTasks SET PlannedHours =ft.PlannedHours+tt.RemainingHours
				FROM #FiscalTasks ft INNER JOIN 
				(
					SELECT tt.RemainingHours, ft.TaskId, MAX(ft.StartDate) StartDate FROM #FiscalTasks ft 
					INNER JOIN 
					(	SELECT (t.PlannedHours - SUM(ft.PlannedHours)) RemainingHours, ft.TaskId
						FROM #FiscalTasks ft
						INNER JOIN #TOTALTask t ON ft.TaskId=t.TaskId
						GROUP BY ft.TaskId , t.PlannedHours
						HAVING SUM(ft.PlannedHours) <> t.PlannedHours
					) tt  ON ft.TaskId=tt.TaskId AND ft.PlannedHours + RemainingHours > 0 
					GROUP BY ft.TaskId,  tt.RemainingHours
				) tt ON tt.TaskId=ft.TaskId AND ft.StartDate=tt.StartDate
				
                 
				INSERT INTO #FiscalTasks (FPBillingOfficeID, FiscalPeriodId, ProjectId, TaskId, StartDate, EndDate, AssociatedWorkgroup)
				SELECT DISTINCT p.FPBillingOfficeID, fp.FiscalPeriodId, p.ProjectId, t.TaskId, fp.startDate, fp.endDate, ISNULL(e.AssociatedWorkgroup, @NULLID)
				FROM #FISCALPROJECT p
				INNER JOIN Project pr WITH (NOLOCK) ON p.ProjectID=pr.ProjectId
				INNER JOIN Engagement e WITH (NOLOCK) ON pr.EngagementId=e.EngagementId
				INNER JOIN Tasks t WITH (NOLOCK) ON t.Deleted=0 AND t.ProjectId=p.ProjectId AND t.OpenTask=0x1
				INNER JOIN AssignmentFiscalRollup tt WITH (NOLOCK) ON t.TaskId=tt.TaskId AND tt.projectid=p.projectid AND tt.fpBillingOfficeid=p.FPBillingOfficeID
				INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fp.BillingOfficeId=tt.FPBillingOfficeId AND fp.Deleted=0 AND tt.fiscalPeriodId =fp.fiscalPeriodid
				CROSS APPLY
				(
					SELECT TOP 1 ft.projectid FROM #FiscalTasks ft WHERE ft.FPBillingOfficeId=p.FPBillingOfficeID AND ft.projectid=p.projectid AND ft.taskid=t.taskid
				) tmp
				WHERE
					NOT EXISTS(SELECT TOP 1 1 FROM #FiscalTasks ft WHERE ft.FPBillingOfficeId=p.FPBillingOfficeID AND ft.projectid=p.projectid AND ft.taskid=t.taskid 
																				AND ft.fiscalPeriodId=fp.fiscalPeriodid)
				
				
				TRUNCATE TABLE  #PND_WorkingDaysConversionDay
			
				INSERT  INTO #PND_WorkingDaysConversionDay (LevelType,LevelTypeId, EntityId, FiscalPeriodId, StartPeriod,EndPeriod)
				SELECT  CASE WHEN ft.AssociatedWorkgroup=@NULLID THEN 's' ELSE 'w' END, 
				ft.AssociatedWorkgroup, ft.TaskId, ft.FiscalPeriodID,ft.StartDate, ft.EndDate
				FROM #FiscalTasks ft  WHERE ft.PlannedWorkingDaysCalc=0x0
				EXEC dbo.PND_WorkingDaysConversionDay @CalculateWorkingDays, 0x0
				
				UPDATE #FiscalTasks SET WorkingDays=CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE  pnd.WorkingDays END, 
				PlannedWorkingDaysCalc=0x1 
				FROM  #FiscalTasks ft 
				INNER JOIN  #PND_WorkingDaysConversionDay pnd ON  pnd.EntityId=ft.TaskId 
				AND pnd.FiscalPeriodId= ft.FiscalPeriodID
				
				DELETE tfr
				FROM TaskFiscalRollup tfr
				INNER JOIN #FiscalTasks ft
				ON ft.FiscalPeriodId = tfr.FiscalPeriodId AND ft.TaskId = tfr.TaskId 
				AND ft.ProjectID = tfr.ProjectID AND ft.FPBillingOfficeID = tfr.FPBillingOfficeID
				
				INSERT INTO TaskFiscalRollup(ProjectId, TaskId, FPBillingOfficeId, FiscalYearId, FiscalPeriodId, PlannedHours, ActualHours,
				RemainingHours, ForecastHours, PlannedDays, PlannedFTE, ActualDays,ActualFTE,RemainingDays,RemainingFTE)
				SELECT tmp.ProjectId, tmp.TaskId, tmp.BillingOfficeId, tmp.FiscalYearId, tmp.FiscalPeriodId, tmp.PlannedHours, tmp.actualHours,
				tmp.remainingHours, tmp.forecastHours, 
				CASE WHEN tmp.ConversionToDay=0 THEN 0 ELSE (tmp.PlannedHours/tmp.ConversionToDay) END, CASE WHEN (tmp.ConversionToDay=0 OR tmp.WorkingDays =0) THEN 0 ELSE tmp.PlannedHours/(tmp.ConversionToDay * tmp.WorkingDays) END, 
				CASE WHEN tmp.ConversionToDay=0 THEN 0 ELSE (tmp.actualHours/tmp.ConversionToDay) END,CASE WHEN (tmp.ConversionToDay=0 OR tmp.WorkingDays =0) THEN 0 ELSE tmp.actualHours/(tmp.ConversionToDay * tmp.WorkingDays) END, 
				CASE WHEN tmp.ConversionToDay=0 THEN 0 ELSE (tmp.remainingHours/tmp.ConversionToDay) END,CASE WHEN (tmp.ConversionToDay=0 OR tmp.WorkingDays =0) THEN 0 ELSE tmp.remainingHours/(tmp.ConversionToDay * tmp.WorkingDays) END
				FROM (
						SELECT  ft.ProjectId, ft.TaskId, fp.BillingOfficeId, fp.FiscalYearId, fp.FiscalPeriodId, ft.PlannedHours, ISNULL(tt.ActualHours,0) actualHours,
						0 remainingHours, ISNULL(tt.ForecastHours,0) forecastHours, 
						t.ConversionToDay, ft.WorkingDays FROM #FiscalTasks  ft 
						INNER JOIN Tasks t WITH (NOLOCK)  ON t.TaskId=ft.TaskId
						INNER  JOIN FiscalPeriod fp WITH (NOLOCK)  ON fp.FiscalPeriodId=ft.FiscalPeriodId
						LEFT JOIN 
						(
							SELECT SUM(ar.ActualHours) ActualHours ,  SUM(ar.ForecastHours) ForecastHours,  ar.ProjectId, ar.TaskId, ar.FiscalPeriodId
							FROM #FiscalTasks  ft 
							INNER JOIN AssignmentFiscalRollup ar WITH (NOLOCK)  ON ar.ProjectId=ft.ProjectId AND ar.Taskid=ft.TaskId 
							AND  ar.FPBillingOfficeId=ft.FPBillingOfficeId AND ar.FiscalPeriodId=ft.FiscalPeriodId
							where ( ar.actualhours!=0  )
							GROUP BY  ar.ProjectId, ar.TaskId, ar.FiscalPeriodId
						) tt  ON ft.ProjectId=tt.ProjectId AND ft.TaskId =tt.TaskId AND ft.FiscalPeriodId =tt.FiscalPeriodId
				) tmp WHERE  tmp.PlannedHours!=0  or tmp.actualHours!=0 or tmp.remainingHours!=0 or tmp.forecastHours!=0 
				
			
				
			END 
			
			
			DELETE tt
			FROM #Tasks tt
			INNER JOIN 
				(SELECT t.TaskID, HasFPData = MIN(CONVERT(INT, t.HasFPData))
				FROM #Tasks t
				GROUP BY t.TaskID
				HAVING COUNT(1)> 1) x
			ON x.TaskID = tt.TaskID AND tt.HasFPData = x.HasFPData
	UPDATE	#AssignmentREMAINING
	SET 
		remaininghours = case when isnull(ta.actualhours, 0) >= ta.plannedhours then 1.00 else ta.plannedhours - isnull(ta.actualhours, 0) end, 
		percentcomplete = 100 *
			case 
				when 
					(isnull(ta.actualhours,0)+case when isnull(ta.actualhours,0)>=ta.plannedhours then 1 else ta.plannedhours-isnull(ta.actualhours,0) end) = 0 
				then 
					null
				else 
					isnull(ta.actualhours,0)/(isnull(ta.actualhours,0)+case when isnull(ta.actualhours,0)>=ta.plannedhours then 1 else ta.plannedhours-isnull(ta.actualhours,0) end)
			end 
	FROM	#AssignmentREMAINING fa 
	INNER JOIN TaskAssignment TA WITH (NOLOCK)  ON ta.TaskAssignmentId = fa.AssignmentId 
	UPDATE	TaskAssignment 
	SET	
		remaininghours = fa.remaininghours,
		percentcomplete = fa.percentcomplete,
		UpdatedOn = @NOW, 
		ActualHours=ta.Actualhours
	FROM	TaskAssignment ta 
	INNER JOIN #AssignmentREMAINING fa on ta.ProjectId = fa.ProjectId and ta.TaskAssignmentId = fa.AssignmentId
	AND (ISNULL(fa.remaininghours, 0) <> ISNULL(ta.remaininghours, 0) OR ISNULL(fa.percentcomplete, 0) <> ISNULL(ta.percentcomplete, 0))
		
		BEGIN
		
			INSERT INTO #UpdateTask(ProjectID,TaskID,Type,Name,ActualStart,ActualFinish,
			ActualHours,ActualDays, ActualFTE, 
			ForecastStart,ForecastFinish,
			RemainingHours,
			RemainingDays, 
			RemainingFTE,
			PlannedHours,
			PlannedDays, 
			PlannedFTE, 
			PlannedStart,PlannedFinish,OBS,WBS,UPDATED, 
			PlannedRemainingHours,
			PlannedRemainingDays,
			PlannedRemainingFTE, MSP	)
			SELECT  t.ProjectID,t.TaskID, 't', t.Name,MIN(ta.ActualStart),
			CASE WHEN EXISTS (SELECT 1 FROM TaskAssignment ta  WITH (NOLOCK)  WHERE t.TaskId=ta.TaskId AND ta.Deleted=cast(0 as bit)
			 AND ta.ActualFinish IS NULL AND 
			ISNULL(ta.ResourceId, @NULLID)<>@NULLID)  
			THEN NULL ELSE MAX(ta.ActualFinish) END	,
			ISNULL(SUM(ta.ActualHours),0), ISNULL(SUM(ta. ActualDays),0), ISNULL(SUM(ta. ActualFTE),0),
			MIN(ta.ForecastStart),MAX(ta.ForecastFinish),
			ISNULL(SUM(ta.RemainingHours),0), ISNULL(SUM(ta.RemainingDays),0),  ISNULL(SUM(ta.RemainingFTE),0),
			CASE WHEN ISNULL(t.MSP_ProjectId,0)=0 THEN ISNULL(SUM(ta.PlannedHours),t.PlannedHours) ELSE t.PlannedHours END , 
			CASE WHEN ISNULL(t.MSP_ProjectId,0)=0 THEN ISNULL(SUM(ta.PlannedDays),t.PlannedDays) ELSE t.PlannedDays END ,  
			CASE WHEN ISNULL(t.MSP_ProjectId,0)=0 THEN ISNULL(SUM(ta.PlannedFTE),t.PlannedFTE) ELSE t.PlannedFTE END,
			CASE WHEN ISNULL(t.MSP_ProjectId,0)=0 THEN ISNULL(MIN(ta.PlannedStart),t.PlannedStart) ELSE t.PlannedStart END ,
			CASE WHEN ISNULL(t.MSP_ProjectId,0)=0 THEN ISNULL(MAX(ta.PlannedFinish),t.PlannedFinish) ELSE t.PlannedFinish END,
			t.OBS,t.WBS,1, 
			ISNULL(SUM(ta.PlannedRemainingHours),0), ISNULL(SUM(ta.PlannedRemainingDays),0),  ISNULL(SUM(ta.PlannedRemainingFTE),0), 
			CASE WHEN ISNULL(t.MSP_ProjectId,0)=0 THEN 0x0 ELSE 0x1 END 
			FROM  Tasks t   WITH (NOLOCK)   
			INNER JOIN #Tasks tt ON t.TaskID=tt.TaskID  
			LEFT OUTER JOIN TaskAssignment ta  WITH (NOLOCK)  ON t.TaskID=ta.TaskID AND ta.Deleted=0x0
			AND EXISTS(SELECT 1 FROM Resources r  WITH (NOLOCK)  WHERE r.ResourceID=ta.ResourceId)
			WHERE t.Deleted=0x0
			GROUP BY t.ProjectID, t.TaskID, t.PlannedHours, t.PlannedDays, t.PlannedFTE, t.WBS, t.Name, t.OBS, t.PlannedStart, t.PlannedFinish, 
			ISNULL(t.MSP_ProjectId,0)
			
			
		
			
			;WITH CTE_Tasks (TaskId) AS
			(
				SELECT t.TaskId
				FROM #UpdateTask t 
				LEFT OUTER JOIN TaskAssignment ta WITH (NOLOCK) ON t.TaskId = ta.TaskId AND ta.Deleted = 0x0 AND ISNULL(ta.ResourceId, @NULLID)<>@NULLID
				WHERE ta.TaskId IS NULL 
			)
			UPDATE #UpdateTask SET PlannedHours=CASE  WHEN tt.MSP=0x0 THEN  0 ELSE tt.PlannedHours END, 
			PlannedDays=CASE WHEN  tt.MSP=0x0 THEN 0 ELSE tt.PlannedDays END, 
			PlannedFTE=CASE WHEN  tt.MSP=0x0 THEN 0 ELSE tt.PlannedFTE END, PlannedRemainingHours=0, PlannedRemainingDays=0, PlannedRemainingFTE=0
			FROM #UpdateTask tt 
			INNER JOIN CTE_Tasks cte ON tt.TaskID = cte.TaskId 
			CROSS APPLY
			(
				SELECT TOP 1 t.TaskId FROM Tasks t WITH (NOLOCK) WHERE t.ProjectID=tt.ProjectID AND t.Deleted=0 AND LEN(t.WBS)>LEN(tt.WBS) AND t.WBS LIKE tt.WBS + '.%'
			) t2
			
			SELECT ut.TaskId INTO #CTE_Task
			FROM #UpdateTask ut
			WHERE
				ut.UPDATED=1 AND ut.Type='t'
				AND EXISTS(SELECT TOP 1 * FROM TaskAssignment ta WITH (NOLOCK) WHERE ut.TaskId = ta.TaskId AND ta.Deleted = CAST(0 AS BIT) AND ISNULL(ta.ResourceId, @NULLID)<>@NULLID)
			UPDATE Tasks SET 
				PlannedStart= t.PlannedStart ,  
				PlannedFinish = t.PlannedFinish, 
				PlannedHours= t.PlannedHours ,
				PlannedDays= t.PlannedDays ,
				PlannedFTE= t.PlannedFTE ,
									
				RollupActualStart= CASE
										WHEN NOT cte.TaskID IS NULL THEN DATEADD(dd,0, DATEDIFF(dd,0,ut.ActualStart))
										ELSE CASE WHEN t.Completed=0x0 THEN NULL ElSE DATEADD(dd,0, DATEDIFF(dd,0,t.RollupActualStart)) END
									END,
				RollupActualFinish=	CASE
										WHEN NOT cte.TaskID IS NULL THEN DATEADD(dd,0, DATEDIFF(dd,0,ut.ActualFinish))
										ELSE CASE WHEN t.Completed=0x0 THEN NULL ElSE DATEADD(dd,0, DATEDIFF(dd,0,t.RollupActualFinish)) END
									END,
									
				RollupActualHours=ut.ActualHours,
				RollupActualDays=ut.ActualDays,
				RollupActualFTE=ut.ActualFTE,
				RollupForecastStart= DATEADD(dd,0, DATEDIFF(dd,0,ut.ForecastStart)),
				RollupForecastFinish= DATEADD(dd,0, DATEDIFF(dd,0,ut.ForecastFinish)),
				RollupRemainingHours= ISNULL(ut.RemainingHours, 0) ,
				RollupRemainingDays= ISNULL(ut.RemainingDays, 0) ,
				RollupRemainingFTE= ISNULL(ut.RemainingFTE, 0) ,
				PlannedRemainingHours= ISNULL(ut.PlannedRemainingHours, 0) ,
				PlannedRemainingDays=  ISNULL(ut.PlannedRemainingDays, 0),
				PlannedRemainingFTE= ISNULL(ut.PlannedRemainingFTE, 0) , 
				LagDays=t.LagDays,	
				UpdatedON=@NOW
				FROM Tasks t  WITH (NOLOCK)
				INNER JOIN #UpdateTask ut ON t.ProjectID=ut.ProjectID AND t.TaskID=ut.TaskID AND ut.UPDATED=1 AND ut.Type='t'
				LEFT OUTER JOIN #CTE_Task cte ON ut.TaskID = cte.TaskID
				WHERE (t.OpenTask = 0x1 OR  ISNULL(t.MSP_ProjectID,0)=1)
			UPDATE Tasks SET 
				PlannedStart= DATEADD(dd,0, DATEDIFF(dd,0,ut.PlannedStart)) ,  
				PlannedFinish = DATEADD(dd,0, DATEDIFF(dd,0,ut.PlannedFinish)) , 
				PlannedHours= ut.PlannedHours ,
				PlannedDays= ut.PlannedDays ,
				PlannedFTE= ut.PlannedFTE ,
				RollupActualStart= CASE
										WHEN NOT cte.TaskID IS NULL THEN DATEADD(dd,0, DATEDIFF(dd,0,ut.ActualStart))
										ELSE CASE WHEN t.Completed=0x0 THEN NULL ElSE DATEADD(dd,0, DATEDIFF(dd,0,t.RollupActualStart)) END
									END,
				RollupActualFinish=	CASE
										WHEN NOT cte.TaskID IS NULL THEN DATEADD(dd,0, DATEDIFF(dd,0,ut.ActualFinish))
										ELSE CASE WHEN t.Completed=0x0 THEN NULL ElSE DATEADD(dd,0, DATEDIFF(dd,0,t.RollupActualFinish)) END
									END,
				RollupActualHours=ut.ActualHours,
				RollupActualDays=ut.ActualDays,
				RollupActualFTE=ut.ActualFTE,
				RollupForecastStart= DATEADD(dd,0, DATEDIFF(dd,0,ut.ForecastStart)),
				RollupForecastFinish= DATEADD(dd,0, DATEDIFF(dd,0,ut.ForecastFinish)),
				RollupRemainingHours= ut.RemainingHours ,
				RollupRemainingDays= ut.RemainingDays ,
				RollupRemainingFTE= ut.RemainingFTE ,
				PlannedRemainingHours= ut.PlannedRemainingHours ,
				PlannedRemainingDays= ut.PlannedRemainingDays ,
				PlannedRemainingFTE= ut.PlannedRemainingFTE , 
				LagDays=t.LagDays,	
				UpdatedON=@NOW
				FROM Tasks t  WITH (NOLOCK)
				INNER JOIN #UpdateTask ut ON t.ProjectID=ut.ProjectID AND t.TaskID=ut.TaskID AND ut.UPDATED=1 AND ut.Type='t'
				LEFT OUTER JOIN #CTE_Task cte ON ut.TaskID = cte.TaskID
				WHERE t.OpenTask = 0x0 AND  ISNULL(t.MSP_ProjectID,0)=0
				
			DROP TABLE #CTE_Task
			
			INSERT INTO #Currollup (ID, obs, WBS, type, ProjectID)
			SELECT p.ProjectID ID, p.OBS, '0' WBS , 'p' Type, p.ProjectID
				FROM #FISCALPROJECT fp
				INNER JOIN Project p WITH (NOLOCK) ON p.projectID = fp.projectID
				INNER JOIN Tasks t WITH (NOLOCK) ON t.ProjectID = p.ProjectID
				INNER JOIN #Tasks tt ON tt.TaskID = t.TaskID 
				GROUP BY p.ProjectID, p.OBS
			UNION
			SELECT t.TASKID ID, t.OBS, t.WBS, 's' Type, t.ProjectID
				FROM #UpdateTask ut
				INNER JOIN Tasks t WITH (NOLOCK) ON ut.taskID = t.taskID
				INNER JOIN Tasks t1 WITH (NOLOCK) ON t.ProjectID=t1.ProjectID AND t1.Deleted=0x0
						AND LEN(t1.wbs) > LEN(t.wbs)
						AND t1.wbs LIKE t.wbs + N'.%'
				OUTER APPLY
				(
					SELECT TOP 1 s.TaskID FROM SubProject s WITH (NOLOCK) INNER JOIN Project p WITH (NOLOCK) ON s.SubProjectID=p.ProjectID AND p.Deleted=0x0 AND s.TaskID=t.TaskID
				) tt
				WHERE 
					tt.TaskId IS NULL
			UNION
			SELECT t.TASKID ID, t.OBS, t.WBS, 't' Type, t.ProjectID 
				FROM #UpdateTask ut
				INNER JOIN Tasks t WITH (NOLOCK) ON ut.taskID = t.taskID  
				WHERE EXISTS(SELECT TOP 1 1 FROM SubProject s WITH (NOLOCK) INNER JOIN Project p WITH (NOLOCK) ON s.SubProjectID=p.ProjectID AND p.Deleted=0x0 AND s.TaskID=t.TaskID)
			
				create index IX_Currollup_IX1 on #Currollup(ID,[type])
				create index IX_Currollup_IX2 on #Currollup(ProjectID)
				IF @EmailId <> @NULLID
				BEGIN
				
				
				
				;WITH CTE_ProjectTaskdependencies (ProjectId, BodyParameters) AS
				(
					SELECT p.ProjectId AS ProjectId, p.Name+'|'+ t.Name+'|'+p2.Name+'|'+t2.Name AS BodyParameters
					FROM #Currollup c
					INNER JOIN ProjectTaskdependencies pd WITH (NOLOCK) ON pd.ParentTaskId = c.ID
					INNER JOIN Tasks t WITH (NOLOCK) ON t.TaskId = pd.ParentTaskId AND t.Deleted = 0x0
					INNER JOIN Project p WITH (NOLOCK) ON p.ProjectId = t.ProjectId AND p.Deleted = 0x0 AND p.IncludePlannedInRollup = 0x1 AND ISNULL(p.MSP_ProjectId,0) = 0x0
					INNER JOIN Tasks t2 WITH (NOLOCK) ON t2.TaskId = pd.TaskId AND t2.Deleted = 0x0
					INNER JOIN Project p2 WITH (NOLOCK) ON p2.ProjectId = t2.ProjectId AND p2.Deleted = 0x0
					WHERE c.type = 's'
					UNION
					SELECT p.ProjectId AS ProjectId, p.Name+'|'+ t.Name+'|'+p2.Name+'|'+t2.Name AS BodyParameters
					FROM #Currollup c
					INNER JOIN ProjectTaskdependencies pd WITH (NOLOCK) ON pd.TaskID = c.ID
					INNER JOIN Tasks t WITH (NOLOCK) ON t.TaskId = pd.ParentTaskId AND t.Deleted = 0x0
					INNER JOIN Project p WITH (NOLOCK) ON p.ProjectId = t.ProjectId AND p.Deleted = 0x0
					INNER JOIN Tasks t2 WITH (NOLOCK) ON t2.TaskId = pd.TaskId AND t2.Deleted = 0x0
					INNER JOIN Project p2 WITH (NOLOCK) ON p2.ProjectId = t2.ProjectId AND p2.Deleted = 0x0 AND p2.IncludePlannedInRollup = 0x1 AND ISNULL(p2.MSP_ProjectId,0) = 0x0
					WHERE c.type = 's'
				)
				INSERT EmailQueue(EmailQueueId, EmailID, ToEmail, BodyParameters)
				SELECT NEWID(), @EmailId, D.EmailAddress, cte.BodyParameters
				FROM CTE_ProjectTaskdependencies cte
				CROSS APPLY 
				(SELECT EmailAddress + ';' FROM 
										(
											SELECT mb.ProjectId, ra.EmailAddress
											FROM ManageMember mb WITH (NOLOCK)
											INNER JOIN ResourceAddress ra WITH (NOLOCK) ON ra.ResourceId = mb.ResourceId AND LEN(ISNULL(ra.EmailAddress,'')) > 0
											INNER JOIN Resources r WITH (NOLOCK) ON ra.ResourceId = r.ResourceId AND r.DisableEmail = 0x0
												AND NOT EXISTS(SELECT TOP 1 1 FROM ResourceEmail E WITH (NOLOCK) WHERE E.EmailId = @EmailId AND E.ResourceId = r.ResourceId)
											WHERE
												mb.ProjectId = cte.ProjectId
											UNION 
											SELECT cm.ProjectId, ra.EmailAddress
											FROM CoManageMember cm WITH (NOLOCK)
											INNER JOIN ResourceAddress ra WITH (NOLOCK) ON ra.ResourceId = cm.ResourceId AND LEN(ISNULL(ra.EmailAddress,'')) > 0
											INNER JOIN Resources r WITH (NOLOCK) ON ra.ResourceId = r.ResourceId AND r.DisableEmail = 0x0
												AND NOT EXISTS(SELECT TOP 1 1 FROM ResourceEmail E WITH (NOLOCK) WHERE E.EmailId = @EmailId AND E.ResourceId = r.ResourceId)
											CROSS APPLY
												(SELECT TOP 1 ft.ResourceId FROM dbo.FT_GetResourcesByFeatures('MTK') ft WHERE ft.ResourceId = ra.ResourceId) tt
											WHERE
												cm.ProjectId = cte.ProjectId
										) p2 
						FOR XML PATH('')
				) D (EmailAddress)
			
				END
			
			INSERT INTO #CriticalPathProjects (CriticalPathProjectId)
			SELECT DISTINCT p.ProjectId FROM #Currollup r
			INNER JOIN Project p with(nolock) ON p.ProjectId=r.ProjectId AND p.Deleted=0X0 AND p.CriticalPath=0x1 
			AND NOT EXISTS(SELECT TOP 1 1 FROM #CriticalPathProjects WHERE CriticalPathProjectId=p.ProjectId)	
			
		
			TRUNCATE TABLE  #PND_WorkingDaysConversionDay
		
			INSERT  INTO #PND_WorkingDaysConversionDay (LevelType,LevelTypeId, EntityId, StartPeriod,EndPeriod)
			SELECT  CASE WHEN ISNULL(e.AssociatedWorkgroup, @NULLID)=@NULLID THEN 's' ELSE 'w' END, e.AssociatedWorkgroup, t.TaskId, t.PlannedStart, t.PlannedFinish
			FROM  #UpdateTask tt with(nolock)
			INNER JOIN Tasks t WITH (NOLOCK) ON t.TaskId=tt.TaskID
			INNER JOIN Engagement e with(nolock) ON t.EngagementId=e.EngagementId
			WHERE tt.TaskID NOT IN 
			(
				SELECT ID FROM #Currollup  cr WITH (NOLOCK) WHERE cr.[type] IN ('s','t')
			)
				
			EXEC dbo.PND_WorkingDaysConversionDay 1, 0
				
			UPDATE Tasks SET WorkingDays= CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE pnd.WorkingDays END, 
			WorkingDaysUpdatedOn=GETDATE() FROM  Tasks t WITH (NOLOCK)
			INNER JOIN  #PND_WorkingDaysConversionDay pnd  WITH (NOLOCK) ON pnd.EntityId=t.TaskId 
			DECLARE @OBSLength INT
			SET @OBSLength = ISNULL((SELECT MAX(LEN(OBS)) FROM #Currollup), -1)	
			WHILE EXISTS(SELECT 1 FROM #Currollup WHERE LEN(OBS) = @OBSLength AND @OBSLength> 0)
				BEGIN	
				
					BEGIN
						
					
						
						
						
						
						
						
						IF OBJECT_ID('tempdb..#Tasks_S') IS NOT NULL DROP TABLE  #Tasks_S
						CREATE TABLE #Tasks_S
						(
						TaskID UNIQUEIDENTIFIER,
						TminStart DATETIME,
						TmaxFinish DATETIME,
						AminStart DATETIME,
						AmaxFinish DATETIME,
						FminStart DATETIME,
						FmaxFinish DATETIME,
						TSumPlanHours NUMERIC(12,5),
						TSumPlanDays NUMERIC(12,5),
						TSumPlanFTE NUMERIC(12,5),
						ASumPlanHours NUMERIC(12,5),
						ASumPlanDays NUMERIC(12,5),
						ASumPlanFTE	NUMERIC(12,5),
						RSumPlanHours NUMERIC(12,5),
						RSumPlanDays NUMERIC(12,5),
						RSumPlanFTE NUMERIC(12,5),
						SUMPlanRemHours	NUMERIC(12,5),
						SUMPlanRemDays	NUMERIC(12,5),
						SUMPlanRemFTE	NUMERIC(12,5),
						PRIMARY KEY (TaskID)
						)
						INSERT #Tasks_S (TaskID, TminStart, TmaxFinish, AminStart, AmaxFinish, FminStart, FmaxFinish)			
						SELECT	c.ID, 
						TminStart=MIN(CASE WHEN t.TaskID=c.ID THEN ISNULL(ta.PlannedStart,@MaxDate) ELSE t.PlannedStart END ),
						TmaxFinish=MAX(CASE WHEN t.TaskID=c.ID THEN ISNULL(ta.Plannedfinish,@MinDate) ELSE t.Plannedfinish END),
						AminStart=MIN(t.RollupActualStart),
						AmaxFinish=MAX(t.RollupActualFinish),
						FminStart=MIN(t.RollupForecastStart),
						FmaxFinish=MAX(t.RollupForecastFinish) 
						FROM Tasks t  WITH (NOLOCK)  LEFT OUTER JOIN TaskAssignment ta WITH (NOLOCK)  ON t.TaskID=ta.TaskID AND ta.Deleted=CAST(0 as bit)
						INNER JOIN #Currollup c ON 
						 t.ProjectID=c.ProjectID  AND LEN(c.OBS) = @OBSLength AND c.type = 's'
						AND ((t.WBS LIKE ( c.WBS + N'.%') AND t.WBS NOT LIKE ( c.WBS + N'.%.%'))  OR (t.WBS=c.WBS))
						AND t.Deleted=CAST(0 as bit)
						GROUP BY c.ID
						
						UPDATE s 
						SET TSumPlanHours= x.TSumPlanHours,
						TSumPlanDays =x.TSumPlanDays,
						TSumPlanFTE = x.TSumPlanFTE,
						ASumPlanHours = x.ASumPlanHours,
						ASumPlanDays =x.ASumPlanDays,
						ASumPlanFTE	=x.ASumPlanFTE,
						RSumPlanHours = x.RSumPlanHours,
						RSumPlanDays=x.RSumPlanDays,
						RSumPlanFTE =x.RSumPlanFTE,
						SUMPlanRemHours =x.SUMPlanRemHours,
						SUMPlanRemDays	=x.SUMPlanRemDays,
						SUMPlanRemFTE	=x.SUMPlanRemFTE
						FROM #Tasks_S s
						INNER JOIN 
							(SELECT	TaskID = c.ID, 
							TSumPlanHours=SUM(ISNULL(t.Plannedhours,0)),
							TSumPlanDays =SUM(ISNULL(t.PlannedDays,0)),
							TSumPlanFTE =SUM(ISNULL(t.PlannedFTE,0)),
							ASumPlanHours=SUM(ISNULL(t.RollupActualHours,0)),
							ASumPlanDays =SUM(ISNULL(t.RollupActualDays,0)),
							ASumPlanFTE	=SUM(ISNULL(t.RollupActualFTE,0)),
							RSumPlanHours=SUM(ISNULL(t.RollupRemainingHours,0)),
							RSumPlanDays=SUM(ISNULL(t.RollupRemainingDays,0)),
						    RSumPlanFTE =SUM(ISNULL(t.RollupRemainingFTE,0)),
							SUMPlanRemHours =SUM(ISNULL(t.PlannedRemainingHours,0)),
							SUMPlanRemDays	=SUM(ISNULL(t.PlannedRemainingDays,0)),
							SUMPlanRemFTE	=SUM(ISNULL(t.PlannedRemainingFTE,0))
							FROM Tasks t  WITH (NOLOCK) 
							INNER JOIN #Currollup c ON 
							t.ProjectID=c.ProjectID	AND LEN(c.OBS) = @OBSLength AND c.type = 's'
							AND ((t.WBS LIKE ( c.WBS + N'.%') AND t.WBS NOT LIKE ( c.WBS + N'.%.%'))  OR (t.WBS=c.WBS))
							AND t.Deleted=CAST(0 as bit)
							GROUP BY c.ID) AS x
						 ON x.TaskID = s.TaskID
						
						UPDATE t SET PlannedStart= CASE WHEN ISNULL(t.MSP_ProjectId,0) =0 THEN DATEADD(dd,0, DATEDIFF(dd,0,s.TminStart)) ELSE t.PlannedStart END,  
									 PlannedFinish= CASE WHEN ISNULL(t.MSP_ProjectId,0) =0 THEN DATEADD(dd,0, DATEDIFF(dd,0,s.TmaxFinish)) ELSE t.PlannedFinish END , 
									 PlannedHours=CASE WHEN ISNULL(t.MSP_ProjectId,0) =0 THEN s.TSumPlanHours ELSE t.PlannedHours END,
									 PlannedDays=CASE WHEN ISNULL(t.MSP_ProjectId,0) =0 THEN s.TSumPlanDays ELSE t.PlannedDays END, 
									 PlannedFTE = CASE WHEN ISNULL(t.MSP_ProjectId,0) =0 THEN s.TSumPlanFTE ELSE t.PlannedFTE END, 
									
									RollupActualStart= DATEADD(dd,0, DATEDIFF(dd,0,s.AminStart)),
									RollupActualFinish=CASE 
									WHEN t.Completed =0 AND EXISTS (SELECT TOP 1 t1.ProjectID  FROM Tasks t1  WITH (NOLOCK)  WHERE t1.Deleted=0 
									AND (t1.WBS LIKE ( t.WBS + N'.%') AND t1.WBS NOT LIKE (t.WBS + N'.%.%')) AND t.ProjectID=t1.ProjectID 
									AND t1.RollupActualFinish IS NULL)
									THEN NULL
									ELSE DATEADD(dd,0, DATEDIFF(dd,0,s.AmaxFinish)) END,
									RollupActualHours=s.ASumPlanHours,
									RollupActualDays=s.ASumPlanDays, 
									RollupActualFTE=s.ASumPlanFTE,
									RollupForecastStart= DATEADD(dd,0, DATEDIFF(dd,0,s.FminStart)),
									RollupForecastFinish= DATEADD(dd,0, DATEDIFF(dd,0,s.FmaxFinish)),
									RollupRemainingHours=s.RSumPlanHours,
									RollupRemainingDays=s.RSumPlanDays, 
									RollupRemainingFTE=s.RSumPlanFTE, 
									PlannedRemainingHours=s.SUMPlanRemHours,
									PlannedRemainingDays=s.SUMPlanRemDays,
									PlannedRemainingFTE=s.SUMPlanRemFTE,
									UpdatedON=@NOW,
									LagDays=t.LagDays	 
						FROM Tasks t WITH (NOLOCK) 
						INNER JOIN #Tasks_S s
						ON s.TaskID = t.TaskID
					
						IF EXISTS( SELECT TOP 1 1  FROM #FISCALPROJECT  WHERE FPBillingOfficeID<>@NULLID)
							BEGIN  
								INSERT  INTO #TEMPENTITY (FPBillingOfficeID, FiscalPeriodID,  EntityID , PlannedHours , ActualHours , RemainingHours, ForecastHours, 
								PlannedDays, PlannedFTE,  ActualDays, ActualFTE, RemainingDays,RemainingFTE)
								SELECT tf.FPBillingOfficeId ,tf.FiscalPeriodID, c.ID, ISNULL(SUM(tf. PlannedHours),0),  ISNULL(SUM(tf.ActualHours),0), ISNULL(SUM(tf.RemainingHours),0), ISNULL(SUM(tf.ForecastHours),0),
								ISNULL(SUM(tf. PlannedDays),0), ISNULL(SUM(tf.PlannedFTE),0), 
								ISNULL(SUM(tf. ActualDays),0), ISNULL(SUM(tf.ActualFTE),0), 
								ISNULL(SUM(tf. RemainingDays),0), ISNULL(SUM(tf.RemainingFTE),0)
								FROM  #Currollup c 
								INNER JOIN Tasks t WITH (NOLOCK)  ON  t.ProjectID=c.ProjectID AND LEN(c.OBS) = @OBSLength  AND c.type = 's'
								AND t.Deleted=CAST(0 as bit)
								INNER JOIN TaskFiscalRollup tf WITH (NOLOCK)  ON t.TaskID=tf.TaskID 
								AND EXISTS(SELECT 1 FROM #TEMPFISCAL tm INNER JOIN #FISCALPROJECT p ON tm.FPBillingOfficeId = p.FPBillingOfficeID AND p.RollupProjectID = tm.RollupProjectID 
								WHERE tm.FPBillingOfficeID=tf.FPBillingOfficeID AND c.ProjectID = p.ProjectID AND p.fPeriodCount > 0  AND p.FPBillingOfficeID = tf.FPBillingOfficeId) 
								AND ((t.WBS LIKE ( c.WBS + N'.%') AND t.WBS NOT LIKE ( c.WBS + N'.%.%'))  OR (t.WBS=c.WBS))
								GROUP BY tf.FPBillingOfficeId, c.ID, tf.FiscalPeriodID, c.ID
								
								UPDATE TaskFiscalRollup SET 
								PlannedHours=te.PlannedHours, 
								PlannedDays=te.PlannedDays, 
								PlannedFTE=te.PlannedFTE,
								ActualHours=te.ActualHours, 
								ActualDays=te.ActualDays,
								ActualFTE=te.ActualFTE,
								RemainingHours=te.RemainingHours, 
								RemainingDays=te.RemainingDays,
								RemainingFTE=te.RemainingFTE,
								ForecastHours=te.ForecastHours
								FROM #TEMPENTITY te
								INNER JOIN TaskFiscalRollup tr WITH (NOLOCK) ON te.FiscalPeriodID=tr.FiscalPeriodID AND te.EntityID=tr.TaskID
						
								INSERT INTO TaskFiscalRollup (ProjectID, TaskID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID, PlannedHours, ActualHours, RemainingHours, ForecastHours,
								PlannedDays, PlannedFTE,  ActualDays, ActualFTE, RemainingDays,RemainingFTE)
								SELECT t.ProjectID, te.EntityID, fp.BillingOfficeID, fp.FiscalYearID, te.FiscalPeriodID, 
								te.PlannedHours, te.ActualHours, te.RemainingHours,te.ForecastHours, 
								te.PlannedDays, te.PlannedFTE, te.ActualDays,te.ActualFTE,te.RemainingDays,te.RemainingFTE
								FROM #TEMPENTITY te INNER JOIN FiscalPeriod fp  WITH (NOLOCK)  ON  fp.FiscalPeriodID=te.FiscalPeriodID
								INNER JOIN Tasks t WITH (NOLOCK)  ON te.EntityID =t.TaskID
								WHERE NOT EXISTS(SELECT TOP 1 * FROM TaskFiscalRollup tr WITH (NOLOCK)  WHERE tr.TaskID=te.EntityID AND te.FiscalPeriodID=tr.FiscalPeriodID )
								AND ((te.PlannedHours <> 0)  OR (te.ActualHours <> 0) OR (te.RemainingHours<> 0) OR (te.ForecastHours<>0))
								GROUP BY t.ProjectID, te.EntityID, fp.BillingOfficeID, fp.FiscalYearID, te.FiscalPeriodID, 
								te.PlannedHours, te.ActualHours, te.RemainingHours,te.ForecastHours, t.PlannedStart, t.PlannedFinish, 
								te.PlannedDays, te.PlannedFTE, te.ActualDays,te.ActualFTE,te.RemainingDays,te.RemainingFTE
								TRUNCATE TABLE #TEMPENTITY
							END 
					END
					
					BEGIN
						IF OBJECT_ID('tempdb..#Tasks_T') IS NOT NULL DROP TABLE  #Tasks_T
						CREATE TABLE #Tasks_T
						(
						ID						UNIQUEIDENTIFIER,
						IncludePlannedInRollup	BIT,
						TminStart				DATETIME,
						TmaxFinish				DATETIME,
						AminStart				DATETIME,
						AmaxFinish				DATETIME,
						FminStart				DATETIME,
						FmaxFinish				DATETIME,
						TSumPlanHours			NUMERIC(12,5),
						TSumPlanDays			NUMERIC(12,5),
						TSumPlanFTE				NUMERIC(12,5),
						ASumPlanHours			NUMERIC(12,5),
						ASumPlanDays			NUMERIC(12,5),
						ASumPlanFTE				NUMERIC(12,5),
						RSumPlanHours			NUMERIC(12,5),
						RSumPlanDays			NUMERIC(12,5),
						RSumPlanFTE				NUMERIC(12,5),
						SUMPlanRemHours			NUMERIC(12,5),
						SUMPlanRemDays			NUMERIC(12,5),
						SUMPlanRemFTE			NUMERIC(12,5), 
						TminStart2				DATETIME,
						TmaxFinish2				DATETIME,
						AminStart2				DATETIME,
						AmaxFinish2				DATETIME,
						FminStart2				DATETIME,
						FmaxFinish2				DATETIME,
						TSumPlanHours2			NUMERIC(12,5),
						TSumPlanDays2			NUMERIC(12,5),
						TSumPlanFTE2			NUMERIC(12,5),
						ASumPlanHours2			NUMERIC(12,5),
						ASumPlanDays2			NUMERIC(12,5),
						ASumPlanFTE2			NUMERIC(12,5),
						RSumPlanHours2			NUMERIC(12,5), 
						RSumPlanDays2			NUMERIC(12,5),
						RSumPlanFTE2			NUMERIC(12,5),
						SUMPlanRemHours2		NUMERIC(12,5),
						SUMPlanRemDays2			NUMERIC(12,5),
						SUMPlanRemFTE2			NUMERIC(12,5)
						)
						
						
						
						INSERT #Tasks_T (ID, TminStart, TmaxFinish, TSumPlanHours, AminStart, AmaxFinish, ASumPlanHours, FminStart, FmaxFinish, RSumPlanHours, 
						TSumPlanDays,TSumPlanFTE,ASumPlanDays,ASumPlanFTE,RSumPlanDays,RSumPlanFTE,SUMPlanRemHours,SUMPlanRemDays,SUMPlanRemFTE	)			
						SELECT c.ID, TminStart = CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup))
								WHEN 1 THEN ISNULL(MIN(p.PlannedStart),@MaxDate)
								ELSE NULL END ELSE NULL END, 
			 				TmaxFinish = CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) 
								WHEN 1 THEN ISNULL(MAX(p.PlannedFinish), @MinDate)
								ELSE NULL END ELSE NULL END, 
			 				TSumPlanHours = CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup))WHEN 1 THEN ISNULL(SUM(p.PlannedHours),0) ELSE 0 END ELSE 0 END , 
							AminStart=ISNULL(MIN(p.ActualStart),@MaxDate) ,
			 				AmaxFinish=ISNULL(MAX(p.ActualFinish), @MinDate),
			 				ASumPlanHours=ISNULL(SUM(p.ActualHours),0),
							FminStart=ISNULL(MIN(p.RollupForecastStart), @MaxDate),
			 				FmaxFinish=ISNULL(MAX(p.RollupForecastFinish), @MinDate),
			 				RSumPlanHours=ISNULL(SUM(p.RollupRemainingHours),0), 
			 				TSumPlanDays =CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup))WHEN 1 THEN ISNULL(SUM(p.PlannedDays),0) ELSE 0 END ELSE 0 END , 
							TSumPlanFTE=CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup))WHEN 1 THEN ISNULL(SUM(p.PlannedFTE),0) ELSE 0 END ELSE 0 END , 
							ASumPlanDays=ISNULL(SUM(p.ActualDays),0),
							ASumPlanFTE=ISNULL(SUM(p.ActualFTE),0),
							RSumPlanDays=ISNULL(SUM(p.RollupRemainingDays),0),
							RSumPlanFTE=ISNULL(SUM(p.RollupRemainingFTE),0), 
							SUMPlanRemHours =CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup))WHEN 1 THEN ISNULL(SUM(p.PlannedRemainingHours),0) ELSE 0 END ELSE 0 END , 
							SUMPlanRemDays=CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup))WHEN 1 THEN ISNULL(SUM(p.PlannedRemainingDays),0) ELSE 0 END ELSE 0 END , 
							SUMPlanRemFTE= CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN  CASE Min(CONVERT(INT, p.IncludePlannedInRollup))WHEN 1 THEN ISNULL(SUM(p.PlannedRemainingFTE),0) ELSE 0 END ELSE 0 END  
						FROM Project p WITH (NOLOCK) 
						INNER JOIN SubProject sp WITH (NOLOCK)  ON p.ProjectID=sp.SubProjectID 
						INNER JOIN #Currollup c ON c.ID = sp.TaskID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
						INNER JOIN Project mainp WITH (NOLOCK) ON sp.ProjectId=mainp.ProjectId
				 		LEFT JOIN ProjectPhase ph WITH (NOLOCK)  ON p.Phase=ph.Code
						WHERE  p.Deleted=CAST(0 as bit) 
						GROUP BY c.ID,  ISNULL(mainp.MSP_ProjectId,0)
						
						
						
						
							
								
								
								
								
								
								
								IF OBJECT_ID('tempdb..#Tasks_T2') IS NOT NULL DROP TABLE  #Tasks_T2
								CREATE TABLE #Tasks_T2
								(
								ID UNIQUEIDENTIFIER,
								TminStart2 DATETIME,
								TmaxFinish2 DATETIME,
								AminStart2 DATETIME,
								AmaxFinish2 DATETIME,
								FminStart2 DATETIME,
								FmaxFinish2 DATETIME,
								TSumPlanHours2	NUMERIC(12,5),
								TSumPlanDays2	NUMERIC(12,5),
								TSumPlanFTE2	NUMERIC(12,5),
								ASumPlanHours2	NUMERIC(12,5),
								ASumPlanDays2	NUMERIC(12,5),
								ASumPlanFTE2	NUMERIC(12,5),
								RSumPlanHours2	NUMERIC(12,5),
								RSumPlanDays2	NUMERIC(12,5),
								RSumPlanFTE2	NUMERIC(12,5),
								SUMPlanRemHours2	NUMERIC(12,5),
								SUMPlanRemDays2		NUMERIC(12,5),
								SUMPlanRemFTE2		NUMERIC(12,5)
						
								
								)
								
								
								INSERT #Tasks_T2(ID, TminStart2, TmaxFinish2, AminStart2, AmaxFinish2, FminStart2, FmaxFinish2)
								SELECT c.ID, 
									
									TminStart2=MIN(CASE WHEN t.TaskId =c.Id THEN ISNULL(ta.PlannedStart,@MaxDate) ELSE t.PlannedStart END ),
					 				
									TmaxFinish2=MAX(CASE WHEN t.TaskId=c.Id THEN ISNULL(ta.Plannedfinish,@MinDate) ELSE t.Plannedfinish END),
					 				AminStart2=ISNULL(MIN(t.RollupActualStart), @MaxDate),
					 				AmaxFinish2=ISNULL(MAX(T.RollupActualFinish), @MinDate),
					 				FminStart2=ISNULL(MIN(t.RollupForecastStart), @MaxDate),
					 				FmaxFinish2=ISNULL(MAX(t.RollupForecastFinish), @MinDate)
								FROM Tasks t  WITH (NOLOCK)  
								INNER JOIN #Currollup c ON c.ProjectID = t.ProjectID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
								LEFT OUTER JOIN TaskAssignment ta  WITH (NOLOCK)  ON t.TaskId=ta.TaskId AND ta.Deleted=CAST(0 as bit)
								WHERE t.ProjectId=c.ProjectId	
								AND ((t.WBS LIKE ( c.WBS + N'.%') 
								AND t.WBS NOT LIKE ( c.WBS + N'.%.%'))  OR (t.WBS=c.WBS))
								AND t.Deleted=CAST(0 as bit)
								AND EXISTS (SELECT 1 FROM Tasks tt WITH (NOLOCK)  INNER JOIN Tasks t1 ON tt.ProjectID =t1.ProjectID AND t1.Deleted=0 AND t1.WBS LIKE tt.WBS + '.%' WHERE tt.TaskID=c.ID )
								GROUP BY c.ID
								
					 			
					 			UPDATE t2
					 			SET TSumPlanHours2 = x.Plannedhours, 
					 			TSumPlanDays2=x.TSumPlanDays2,
								TSumPlanFTE2=x.TSumPlanFTE2,
					 			ASumPlanHours2 = x.RollupActualHours,
					 			ASumPlanDays2=x.ASumPlanDays2,
								ASumPlanFTE2=x.ASumPlanFTE2,
					 			RSumPlanHours2 = x.RollupRemainingHours, 
					 			RSumPlanDays2=x.RSumPlanDays2,
								RSumPlanFTE2=x.RSumPlanFTE2,
					 			SUMPlanRemHours2=x.SUMPlanRemHours2,
								SUMPlanRemDays2=x.SUMPlanRemDays2,
								SUMPlanRemFTE2=x.SUMPlanRemFTE2
					 			FROM #Tasks_T2 t2 
					 			INNER JOIN 
					 				(SELECT c.ID,  
					 				Plannedhours = (ISNULL(SUM(t.Plannedhours),0)),
					 				TSumPlanDays2= (ISNULL(SUM(t.PlannedDays),0)), 
									TSumPlanFTE2= (ISNULL(SUM(t.PlannedFTE),0)), 
									RollupActualHours= SUM(ISNULL(t.RollupActualHours,0)),
									ASumPlanDays2= SUM(ISNULL(t.RollupActualDays,0)),
									ASumPlanFTE2= SUM(ISNULL(t.RollupActualFTE,0)),
									RollupRemainingHours =SUM(ISNULL(t.RollupRemainingHours,0)),
									RSumPlanDays2=SUM(ISNULL(t.RollupRemainingDays,0)),
									RSumPlanFTE2=SUM(ISNULL(t.RollupRemainingFTE,0)),
									SUMPlanRemHours2 =SUM(ISNULL(t.PlannedRemainingHours,0)),
									SUMPlanRemDays2	=SUM(ISNULL(t.PlannedRemainingDays,0)),
									SUMPlanRemFTE2	=SUM(ISNULL(t.PlannedRemainingFTE,0))
									FROM Tasks t  WITH (NOLOCK)  
									INNER JOIN #Currollup c ON c.ProjectID = t.ProjectID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
									WHERE t.ProjectId=c.ProjectId	
									AND ((t.WBS LIKE ( c.WBS + N'.%') 
									AND t.WBS NOT LIKE ( c.WBS + N'.%.%'))  OR (t.WBS=c.WBS))
									AND t.Deleted=CAST(0 as bit)
									AND EXISTS (SELECT 1 FROM Tasks tt WITH (NOLOCK)  INNER JOIN Tasks t1 ON tt.ProjectID =t1.ProjectID AND t1.Deleted=0 AND t1.WBS LIKE tt.WBS + '.%' WHERE tt.TaskID=c.ID )
									GROUP BY c.ID
									) x ON t2.ID = x.ID
							
						
							
								INSERT #Tasks_T2 (ID, TminStart2, TmaxFinish2, AminStart2, AmaxFinish2, FminStart2, FmaxFinish2, TSumPlanHours2, ASumPlanHours2, RSumPlanHours2, 
								TSumPlanDays2, TSumPlanFTE2,ASumPlanDays2, ASumPlanFTE2, RSumPlanDays2,RSumPlanFTE2, SUMPlanRemHours2 ,
								SUMPlanRemDays2,SUMPlanRemFTE2)
								SELECT	c.ID,
									TminStart2=ISNULL(MIN(ta.PlannedStart), MIN(t.PlannedStart)), 
					 				TmaxFinish2=ISNULL(MAX(ta.PlannedFinish), MAX(t.PlannedFinish)),
					 				AminStart2=ISNULL(MIN(t.RollupActualStart), @MaxDate),
					 				AmaxFinish2=ISNULL(MAX(T.RollupActualFinish), @MinDate),
					 				FminStart2=ISNULL(MIN(t.RollupForecastStart), @MaxDate),
					 				FmaxFinish2=ISNULL(MAX(t.RollupForecastFinish), @MinDate),
					 				TSumPlanHours2= ISNULL(MAX(t.Plannedhours),0),
					 				ASumPlanHours2=ISNULL(MAX(t.RollupActualHours),0),
					 				RSumPlanHours2=ISNULL(MAX(t.RollupRemainingHours),0),
					 				TSumPlanDays2= ISNULL(MAX(t.PlannedDays),0),
					 				TSumPlanFTE2=ISNULL(MAX(t.PlannedFTE),0),
					 				ASumPlanDays2=ISNULL(MAX(t.RollupActualDays),0),
					 				ASumPlanFTE2=ISNULL(MAX(t.RollupActualFTE),0), 
					 				RSumPlanDays2=ISNULL(MAX(t.RollupRemainingDays),0) ,
					 				RSumPlanFTE2=ISNULL(MAX(t.RollupRemainingFTE),0) ,
					 				SUMPlanRemHours2=ISNULL(MAX(t.PlannedRemainingHours),0) , 
									SUMPlanRemDays2=ISNULL(MAX(t.PlannedRemainingDays),0) ,
									SUMPlanRemFTE2=ISNULL(MAX(t.PlannedRemainingFTE),0) 	
								FROM Tasks t WITH (NOLOCK)  
								LEFT OUTER JOIN TaskAssignment ta WITH (NOLOCK)  ON t.TaskID=ta.TaskID AND ta.Deleted=CAST(0 as bit)
								INNER JOIN #Currollup c ON c.ID = t.TaskID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
								WHERE NOT EXISTS (SELECT 1 FROM Tasks tt WITH (NOLOCK)  INNER JOIN Tasks t1 ON tt.ProjectID =t1.ProjectID AND t1.Deleted=0 AND t1.WBS LIKE tt.WBS + '.%' WHERE tt.TaskID=c.ID )
								GROUP BY c.ID
							
						
						UPDATE t SET 
						TminStart2 = t2.TminStart2, TmaxFinish2 = t2.TmaxFinish2, AminStart2= t2.AminStart2,
						AmaxFinish2 = t2.AmaxFinish2, FminStart2= t2.FminStart2, FmaxFinish2 = t2.FmaxFinish2, 
						TSumPlanHours2=t2.TSumPlanHours2,TSumPlanDays2=t2.TSumPlanDays2, TSumPlanFTE2=t2.TSumPlanFTE2,
						ASumPlanHours2 = t2.ASumPlanHours2,  ASumPlanDays2=t2.ASumPlanDays2, ASumPlanFTE2=t2.ASumPlanFTE2,
						RSumPlanHours2 = t2.RSumPlanHours2,  RSumPlanDays2=t2.RSumPlanDays2, RSumPlanFTE2=t2.RSumPlanFTE2,
						SUMPlanRemHours2 =t2.SUMPlanRemHours2 ,SUMPlanRemDays2 = t2.SUMPlanRemDays2,
						SUMPlanRemFTE2=t2.SUMPlanRemFTE2
						FROM #Tasks_T t
						INNER JOIN #Tasks_T2 t2 ON t.ID = t2.ID
						
						UPDATE tt
						SET IncludePlannedInRollup = CASE WHEN ISNULL(p.MSP_ProjectId,0)=0 THEN p.IncludePlannedInRollup ELSE 0 END
						FROM #Tasks_T tt
						INNER JOIN Tasks t ON t.TaskId = tt.ID
						INNER JOIN Project p ON p.ProjectId = t.ProjectId
								
						
						
						
						
						
						
						
									UPDATE t
									SET TminStart = TminStart2
									, TmaxFinish = TmaxFinish2
									, TSumPlanHours=TSumPlanHours+TSumPlanHours2,TSumPlanDays=TSumPlanDays+TSumPlanDays2,
									 TSumPlanFTE=TSumPlanFTE+TSumPlanFTE2,
									 SUMPlanRemHours=SUMPlanRemHours+SUMPlanRemHours2 ,SUMPlanRemDays=SUMPlanRemDays+SUMPlanRemDays2,SUMPlanRemFTE=SUMPlanRemFTE+SUMPlanRemFTE2
									FROM #Tasks_T t
									WHERE t.IncludePlannedInRollup = 0x0 AND t.TminStart2 IS NOT NULL					
						
						
						
						
						
									UPDATE t
									SET TminStart = TminStart2
									FROM #Tasks_T t
									WHERE IncludePlannedInRollup = 0x1 AND t.TminStart2 IS NOT NULL
									AND (TminStart IS NULL OR TminStart > TminStart2)
						
						
									UPDATE t
									SET TmaxFinish = TmaxFinish2
									FROM #Tasks_T t
									WHERE IncludePlannedInRollup = 0x1 AND t.TmaxFinish2 IS NOT NULL
									AND (TmaxFinish IS NULL OR TmaxFinish < TmaxFinish2)
						
						
									UPDATE t
									SET TSumPlanHours=TSumPlanHours+TSumPlanHours2, 
									TSumPlanDays=TSumPlanDays+TSumPlanDays2,
									TSumPlanFTE=TSumPlanFTE+TSumPlanFTE2,
									SUMPlanRemHours=SUMPlanRemHours+SUMPlanRemHours2 ,
									SUMPlanRemDays=SUMPlanRemDays+SUMPlanRemDays2,
									SUMPlanRemFTE=SUMPlanRemFTE+SUMPlanRemFTE2
									FROM #Tasks_T t
									WHERE IncludePlannedInRollup = 0x1 AND t.TminStart2 IS NOT NULL
						
		
						
						
									UPDATE t
									SET AminStart = AminStart2
									FROM #Tasks_T t
									WHERE AminStart > AminStart2 AND t.TminStart2 IS NOT NULL					
						
						
									UPDATE t
									SET AmaxFinish = AmaxFinish2
									FROM #Tasks_T t
									WHERE AmaxFinish < AmaxFinish2 AND t.TminStart2 IS NOT NULL
						
						
									UPDATE t
									SET ASumPlanHours=ASumPlanHours+ASumPlanHours2, 
									ASumPlanDays=ASumPlanDays+ASumPlanDays2,
									ASumPlanFTE=ASumPlanFTE + ASumPlanFTE2, 
									RSumPlanHours=RSumPlanHours+RSumPlanHours2,
									RSumPlanDays=RSumPlanDays +RSumPlanDays2, 
									RSumPlanFTE= RSumPlanFTE + RSumPlanFTE2
									FROM #Tasks_T t WHERE t.TminStart2 IS NOT NULL
				
						
						
									UPDATE t
									SET FminStart = FminStart2
									FROM #Tasks_T t
									WHERE FminStart > FminStart2 AND t.FminStart2 IS NOT NULL					
						
						
									UPDATE t
									SET FmaxFinish = FmaxFinish2
									FROM #Tasks_T t
									WHERE FmaxFinish < FmaxFinish2 AND t.FmaxFinish2 IS NOT NULL						
							
						
																	
						
						
						UPDATE #Tasks_T SET AminStart = NULL
						WHERE AminStart =@MaxDate
						UPDATE #Tasks_T SET AmaxFinish = NULL
						WHERE AmaxFinish =@MinDate
						UPDATE #Tasks_T SET FminStart = NULL
						WHERE FminStart = @MaxDate
						UPDATE #Tasks_T SET FmaxFinish = NULL
						WHERE FmaxFinish = @MinDate	
			
						UPDATE Tasks SET 
							PlannedStart = CASE WHEN (t.OpenTask = 0x1 OR ISNULL(t.MSP_ProjectId,0) =1) THEN t.PlannedStart ELSE DATEADD(dd,0, DATEDIFF(dd,0,u.TminStart)) END,
							PlannedFinish = CASE WHEN (t.OpenTask = 0x1 OR ISNULL(t.MSP_ProjectId,0) =1) THEN t.PlannedFinish ELSE DATEADD(dd,0, DATEDIFF(dd,0,u.TmaxFinish)) END,
							PlannedHours = CASE WHEN (t.OpenTask = 0x1 OR ISNULL(t.MSP_ProjectId,0) =1)THEN t.PlannedHours ELSE TSumPlanHours END,
							PlannedDays = CASE WHEN (t.OpenTask = 0x1 OR ISNULL(t.MSP_ProjectId,0) =1) THEN t.PlannedDays ELSE TSumPlanDays END,
							PlannedFTE = CASE WHEN (t.OpenTask = 0x1 OR ISNULL(t.MSP_ProjectId,0) =1) THEN t.PlannedFTE ELSE TSumPlanFTE END,
							PlannedRemainingHours = CASE t.OpenTask WHEN 0x1 THEN t.PlannedRemainingHours ELSE SUMPlanRemHours END,
							PlannedRemainingDays = CASE t.OpenTask WHEN 0x1 THEN t.PlannedRemainingDays ELSE SUMPlanRemDays END,
							PlannedRemainingFTE = CASE t.OpenTask WHEN 0x1 THEN t.PlannedRemainingFTE ELSE SUMPlanRemFTE END,
							RollupActualStart= DATEADD(dd,0, DATEDIFF(dd,0,AminStart)),
							RollupActualFinish=CASE 
							WHEN t.Completed=0 AND EXISTS(SELECT 1 FROM TaskAssignment ta  WITH (NOLOCK)  WHERE ta.Deleted=0 AND ta.TaskId=t.TasKid AND ta.ActualFinish IS NULL)
							THEN NULL
							WHEN t.Completed=0 AND EXISTS (SELECT 1  FROM Tasks t1  WITH (NOLOCK)  WHERE t1.Deleted=0 
							AND (t1.WBS LIKE ( t.WBS + N'.%') AND t1.WBS NOT LIKE ( t.WBS + N'.%.%')) AND t.ProjectId=t1.ProjectId 
							AND t1.RollupActualFinish IS NULL)
							THEN NULL
							WHEN t.Completed=0 
								AND EXISTS(SELECT TOP 1 1 FROM SubProject sp WITH (NOLOCK) INNER JOIN Project p WITH (NOLOCK) ON sp.SubProjectId=p.ProjectId 
												AND p.Deleted=0x0 AND p.ActualFinish IS NULL WHERE t.TaskId=sp.TaskId)
							THEN NULL
							ELSE DATEADD(dd,0, DATEDIFF(dd,0,u.AmaxFinish)) END,
							RollupActualHours=ASumPlanHours,
							RollupActualDays=ASumPlanDays,
							RollupActualFTE=ASumPlanFTE,
							RollupForecastStart= DATEADD(dd,0, DATEDIFF(dd,0,FminStart)),
							RollupForecastFinish= DATEADD(dd,0, DATEDIFF(dd,0,FmaxFinish)),
							RollupRemainingHours=RSumPlanHours,
							RollupRemainingDays=RSumPlanDays,
							RollupRemainingFTE=RSumPlanFTE,
							UpdatedON=@NOW, 
							LagDays=t.LagDays
						FROM Tasks t  WITH (NOLOCK) 
						INNER JOIN #Tasks_T u ON u.ID = t.TaskID
					
						IF EXISTS( SELECT TOP 1 1  FROM #FISCALPROJECT  WHERE FPBillingOfficeID<>@NULLID)
							BEGIN
								INSERT  INTO #TEMPENTITY1 (FPBillingOfficeID, FiscalPeriodID,  EntityID , PlannedHours , ActualHours , RemainingHours,ForecastHours,
								PlannedDays, PlannedFTE,  ActualDays, ActualFTE, RemainingDays,RemainingFTE)
								SELECT tf.FPBillingOfficeID, tf.FiscalPeriodID , c.ID, ISNULL(SUM(tf. PlannedHours),0),  ISNULL(SUM(tf.ActualHours),0), ISNULL(SUM(tf.RemainingHours),0),ISNULL(SUM(tf.ForecastHours),0),
								ISNULL(SUM(tf. PlannedDays),0), ISNULL(SUM(tf. PlannedFTE),0),ISNULL(SUM(tf.ActualDays),0), ISNULL(SUM(tf.ActualFTE),0), 
								ISNULL(SUM(tf.RemainingDays),0),  ISNULL(SUM(tf.RemainingFTE),0)
								FROM Tasks t WITH (NOLOCK) 
								INNER JOIN TaskFiscalRollup tf WITH (NOLOCK) ON t.TaskID=tf.TaskID
								INNER JOIN #Currollup c ON t.ProjectID=c.ProjectID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
								WHERE  ((t.WBS LIKE ( c.WBS + N'.%') AND t.WBS NOT LIKE ( c.WBS + N'.%.%'))  OR (t.WBS=c.WBS))
								AND t.Deleted=CAST(0 as bit)
								AND EXISTS(SELECT 1 FROM #TEMPFISCAL tm INNER JOIN #FISCALPROJECT fp ON tm.FPBillingOfficeId = fp.FPBillingOfficeID AND fp.RollupProjectID = tm.RollupProjectID AND tm.FPBillingOfficeID=tf.FPBillingOfficeID
								WHERE fp.FPBillingOfficeID = tf.FPBillingOfficeId AND c.ProjectID = fp.ProjectID AND fp.fPeriodCount > 0) 
								GROUP BY tf.FPBillingOfficeId, c.ID, tf.FiscalPeriodID
								
								UNION  ALL
								
								SELECT pf.FPBillingOfficeId, pf.FiscalPeriodID, c.ID, 
								CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) WHEN 1 THEN ISNULL(SUM(pf.PlannedHours),0) ELSE 0 END ELSE 0 END,  
								ISNULL(SUM(pf.ActualHours),0), 
								CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) WHEN 1 THEN ISNULL(SUM(pf.RemainingHours),0) ELSE 0 END ELSE 0 END,  
								ISNULL(SUM(pf.ForecastHours),0), 
								CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) WHEN 1 THEN ISNULL(SUM(pf.PlannedDays),0) ELSE 0 END ELSE 0 END,  
								CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) WHEN 1 THEN ISNULL(SUM(pf.PlannedFTE),0) ELSE 0 END ELSE 0 END,  
								ISNULL(SUM(pf.ActualDays),0), ISNULL(SUM(pf.ActualFTE),0), 
								CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) WHEN 1 THEN ISNULL(SUM(pf.RemainingDays),0) ELSE 0 END ELSE 0 END,  
								CASE WHEN ISNULL(mainp.MSP_ProjectId,0) =0 THEN CASE Min(CONVERT(INT, p.IncludePlannedInRollup)) WHEN 1 THEN ISNULL(SUM(pf.RemainingFTE),0) ELSE 0 END ELSE 0 END
								FROM ProjectFiscalRollup pf WITH (NOLOCK) 
								INNER JOIN SubProject sp WITH (NOLOCK) ON pf.ProjectID=sp.SubProjectID
								INNER JOIN Project p WITH (NOLOCK)  ON sp.SubprojectID=p.ProjectID
								INNER JOIN #Currollup c ON sp.TaskID=c.ID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
								INNER JOIN Project mainp WITH (NOLOCK) ON mainp.ProjectId=sp.ProjectID
								WHERE  p.Deleted=CAST(0 as bit) 
								AND EXISTS(SELECT 1 FROM #TEMPFISCAL tm INNER JOIN #FISCALPROJECT fp ON tm.FPBillingOfficeId = fp.FPBillingOfficeID AND fp.RollupProjectID = tm.RollupProjectID AND tm.FPBillingOfficeID=pf.FPBillingOfficeID
											WHERE fp.FPBillingOfficeID = pf.FPBillingOfficeId AND c.ProjectID = fp.ProjectID AND fp.fPeriodCount > 0) 
								GROUP BY pf.FPBillingOfficeId, c.ID, pf.FiscalPeriodID, ISNULL(mainp.MSP_ProjectId,0)
								
								
								
								INSERT  INTO #TEMPENTITY (FPBillingOfficeID, FiscalPeriodID,  EntityID , PlannedHours , ActualHours , RemainingHours, ForecastHours, 
								PlannedDays, PlannedFTE,  ActualDays, ActualFTE, RemainingDays,RemainingFTE)
								SELECT te.FPBillingOfficeID, te.FiscalPeriodID, te.EntityID, 
								SUM(te.PlannedHours), SUM(te.ActualHours), SUM(te.RemainingHours), SUM(te.ForecastHours), 
								SUM(te.PlannedDays), SUM(te.PlannedFTE),  SUM(te.ActualDays), SUM(te.ActualFTE), SUM(te.RemainingDays),
								SUM(te.RemainingFTE)
								FROM #TEMPENTITY1 te 
								GROUP BY te.FPBillingOfficeId, te.FiscalPeriodID, te.EntityID
								
								
								UPDATE TaskFiscalRollup SET 
									PlannedHours=tr.PlannedHours, 
									PlannedDays=tr.PlannedDays, 
									PlannedFTE=tr.PlannedFTE, 
									ActualHours=te.ActualHours,  ActualDays=te.ActualDays,ActualFTE=te.ActualFTE,
									RemainingHours=0, 
									RemainingDays=0, 
									RemainingFTE=0, 
									ForecastHours=te.ForecastHours
								FROM #TEMPENTITY te
								INNER JOIN TaskFiscalRollup tr WITH (NOLOCK)  ON te.FiscalPeriodID=tr.FiscalPeriodID AND te.EntityID=tr.TaskID 
								INNER JOIN Tasks t ON 1=1 AND t.OpenTask=0x1
								INNER JOIN #Currollup c ON c.ID = t.TaskID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
								UPDATE TaskFiscalRollup SET 
									PlannedHours=te.PlannedHours, 
									PlannedDays=te.PlannedDays, 
									PlannedFTE=te.PlannedFTE, 
									ActualHours=te.ActualHours,  ActualDays=te.ActualDays,ActualFTE=te.ActualFTE,
									RemainingHours=te.RemainingHours, 
									RemainingDays=te.RemainingDays, 
									RemainingFTE=te.RemainingFTE, 
									ForecastHours=te.ForecastHours
								FROM #TEMPENTITY te
								INNER JOIN TaskFiscalRollup tr WITH (NOLOCK)  ON te.FiscalPeriodID=tr.FiscalPeriodID AND te.EntityID=tr.TaskID 
								INNER JOIN Tasks t ON 1=1 AND t.OpenTask=0x0
								INNER JOIN #Currollup c ON c.ID = t.TaskID AND c.type = 't' AND LEN(c.OBS) = @OBSLength
								
						
								INSERT INTO TaskFiscalRollup (ProjectID, TaskID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID, PlannedHours, ActualHours, RemainingHours,ForecastHours, 
								PlannedDays, PlannedFTE,  ActualDays, ActualFTE, RemainingDays,RemainingFTE) 
								SELECT t.ProjectID, te.EntityID, fp.BillingOfficeID, fp.FiscalYearID, te.FiscalPeriodID, 
									0, te.ActualHours, 
									0, te.ForecastHours, 
									0, 0,
									te.ActualDays, te.ActualFTE,
									0, 
									0
								FROM #TEMPENTITY te INNER JOIN FiscalPeriod fp  WITH (NOLOCK)  ON fp.FiscalPeriodID=te.FiscalPeriodID
								INNER JOIN Tasks t WITH (NOLOCK)  ON te.EntityID =t.TaskID AND t.OpenTask=0x1					
								WHERE NOT EXISTS (SELECT TOP 1 * FROM TaskFiscalRollup tr WITH (NOLOCK)  WHERE tr.TaskID=te.EntityID AND te.FiscalPeriodID=tr.FiscalPeriodID)
								AND ((te.PlannedHours <> 0)  OR (te.ActualHours <> 0) OR (te.RemainingHours<> 0) OR (te.ForecastHours<>0))
								GROUP BY  t.ProjectID, te.EntityID, fp.BillingOfficeID, fp.FiscalYearID, te.FiscalPeriodID, te.PlannedHours, te.ActualHours, te.RemainingHours, te.ForecastHours, t.PlannedStart, t.PlannedFinish, t.OpenTask,
								te.PlannedDays, te.PlannedFTE,  te.ActualDays, te.ActualFTE, te.RemainingDays,te.RemainingFTE
								INSERT INTO TaskFiscalRollup (ProjectID, TaskID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID, PlannedHours, ActualHours, RemainingHours,ForecastHours, 
								PlannedDays, PlannedFTE,  ActualDays, ActualFTE, RemainingDays,RemainingFTE) 
								SELECT t.ProjectID, te.EntityID, fp.BillingOfficeID, fp.FiscalYearID, te.FiscalPeriodID, 
									te.PlannedHours, te.ActualHours, 
									te.RemainingHours, te.ForecastHours, 
									te.PlannedDays, te.PlannedFTE,
									te.ActualDays, te.ActualFTE,
									te.RemainingDays, 
									te.RemainingFTE
								FROM #TEMPENTITY te INNER JOIN FiscalPeriod fp  WITH (NOLOCK)  ON fp.FiscalPeriodID=te.FiscalPeriodID
								INNER JOIN Tasks t WITH (NOLOCK)  ON te.EntityID =t.TaskID AND t.OpenTask=0x0						
								WHERE NOT EXISTS (SELECT TOP 1 * FROM TaskFiscalRollup tr WITH (NOLOCK)  WHERE tr.TaskID=te.EntityID AND te.FiscalPeriodID=tr.FiscalPeriodID)
								AND ((te.PlannedHours <> 0)  OR (te.ActualHours <> 0) OR (te.RemainingHours<> 0) OR (te.ForecastHours<>0))
								GROUP BY  t.ProjectID, te.EntityID, fp.BillingOfficeID, fp.FiscalYearID, te.FiscalPeriodID, te.PlannedHours, te.ActualHours, te.RemainingHours, te.ForecastHours, t.PlannedStart, t.PlannedFinish, t.OpenTask,
								te.PlannedDays, te.PlannedFTE,  te.ActualDays, te.ActualFTE, te.RemainingDays,te.RemainingFTE
								
								
		
								TRUNCATE TABLE #TEMPENTITY
								TRUNCATE TABLE #TEMPENTITY1
							END
					END
				
					BEGIN	
				
						
							BEGIN
								
								
								
								
								
								
								
								IF OBJECT_ID('tempdb..#Tasks_P') IS NOT NULL DROP TABLE  #Tasks_P
								CREATE TABLE #Tasks_P
								(ProjectID UNIQUEIDENTIFIER,
								ID UNIQUEIDENTIFIER,
								TminStart DATETIME,
								TmaxFinish DATETIME,
								AminStart DATETIME,
								AmaxFinish DATETIME,
								FminStart DATETIME,
								FmaxFinish DATETIME,
								TSumPlanHours NUMERIC(12,5),
								TSumPlanDays NUMERIC(12,5),
								TSumPlanFTE NUMERIC(12,5),
								ASumPlanHours NUMERIC(12,5),
								ASumPlanDays NUMERIC(12,5),
								ASumPlanFTE	NUMERIC(12,5),
								RSumPlanHours NUMERIC(12,5),
								RSumPlanDays NUMERIC(12,5),
								RSumPlanFTE NUMERIC(12,5),
								SUMPlanRemHours	NUMERIC(12,5),
								SUMPlanRemDays	NUMERIC(12,5),
								SUMPlanRemFTE	NUMERIC(12,5)
								)
								
								
								INSERT  #Tasks_P(ProjectID, TminStart, TmaxFinish, AminStart, AmaxFinish, FminStart, FmaxFinish)		
								SELECT	c.ProjectID, 
									TminStart=MIN(CASE WHEN ta.PlannedStart IS NULL THEN t.PlannedStart WHEN t.OpenTask = 0x1 THEN t.PlannedStart WHEN ta.PlannedStart < t.PlannedStart THEN ta.PlannedStart ELSE t.PlannedStart END),
						 			TmaxFinish=MAX(CASE WHEN ta.Plannedfinish IS NULL THEN t.Plannedfinish WHEN t.OpenTask = 0x1 THEN t.PlannedFinish  WHEN ta.Plannedfinish > t.Plannedfinish THEN ta.Plannedfinish ELSE t.Plannedfinish END),
						 			AminStart=MIN(t.RollupActualStart),
						 			AmaxFinish=MAX(t.RollupActualFinish),
						 			FminStart=MIN(t.RollupForecastStart),
						 			FmaxFinish=MAX(t.RollupForecastFinish)
								FROM Tasks t WITH (NOLOCK)  
								LEFT OUTER JOIN TaskAssignment ta WITH (NOLOCK)  ON t.TaskID = ta.TaskID AND ta.Deleted=CAST(0 as bit)
								INNER JOIN #Currollup c ON t.ProjectID=c.ProjectID AND LEN(c.OBS) = @OBSLength AND c.type = 'p'
								WHERE t.ProjectID=c.ProjectID	
									AND CHARINDEX('.', t.WBS) = 0
									AND t.Deleted=CAST(0 as bit)
								GROUP BY c.ProjectID
								
								
								UPDATE u
									SET TSumPlanHours=x.TSumPlanHours,
									TSumPlanDays=x.TSumPlanDays,
									TSumPlanFTE=x.TSumPlanFTE,
						 			ASumPlanHours=x.ASumPlanHours,
						 			ASumPlanDays=x.ASumPlanDays,
									ASumPlanFTE=x.ASumPlanFTE,
						 			RSumPlanHours=x.RSumPlanHours, 
						 			RSumPlanDays=x.RSumPlanDays, 
									RSumPlanFTE =x.RSumPlanFTE, 
									SUMPlanRemHours=x.SUMPlanRemHours, 
									SUMPlanRemDays=x.SUMPlanRemDays, 
									SUMPlanRemFTE=x.SUMPlanRemFTE
								FROM #Tasks_P u
								INNER JOIN 
									(SELECT	p.ProjectID, 
									TSumPlanHours=SUM(ISNULL(t.Plannedhours,0)),
									TSumPlanDays=SUM(ISNULL(t.PlannedDays,0)),
									TSumPlanFTE=SUM(ISNULL(t.PlannedFTE,0)),
						 			ASumPlanHours=SUM(ISNULL(t.RollupActualHours,0)),
						 			ASumPlanDays=SUM(ISNULL(t.RollupActualDays,0)),
									ASumPlanFTE=SUM(ISNULL(t.RollupActualFTE,0)),
						 			RSumPlanHours=SUM(ISNULL(t.RollupRemainingHours,0)),
						 			RSumPlanDays=SUM(ISNULL(t.RollupRemainingDays,0)),
									RSumPlanFTE =SUM(ISNULL(t.RollupRemainingFTE,0)),
									SUMPlanRemHours=SUM(ISNULL(t.PlannedRemainingHours,0)),
									SUMPlanRemDays=SUM(ISNULL(t.PlannedRemainingDays,0)),
									SUMPlanRemFTE=SUM(ISNULL(t.PlannedRemainingFTE,0))
									FROM Tasks t WITH (NOLOCK) 
									INNER JOIN (SELECT DISTINCT ProjectID FROM #Tasks_P) p
									 ON t.ProjectID=p.ProjectID AND LEN(t.OBS) = @OBSLength + 38
									WHERE t.DELETED = 0x0 AND t.WBS NOT LIKE '%.%'
									GROUP BY p.ProjectID) x 
								 ON u.ProjectID = x.ProjectID
								 
								INSERT INTO  #PHASE (ProjectID, PHASEID,WBS)
								SELECT c.ProjectID, t.PHASE, t.WBS
								FROM Tasks t WITH (NOLOCK) , ProjectPhase ph WITH (NOLOCK) , #Currollup c
								WHERE t.ProjectID=c.ProjectID AND LEN(c.OBS) = @OBSLength AND c.type = 'p'
								AND t.Phase=ph.Code
								AND NOT t.Phase IS NULL
								AND t.Deleted=CAST(0 as bit) AND ph.Deleted=CAST(0 as bit)
								AND  ISNULL( t.RollupActualHours,0) >0
		
								DELETE p1 FROM #PHASE p1 INNER JOIN #PHASE p2 
								ON p1.WBS LIKE ( p2.WBS +'.%') AND p1.ProjectID = p2.ProjectID
								
								IF OBJECT_ID('tempdb..#IPHASE') IS NOT NULL DROP TABLE  #IPHASE
								CREATE TABLE #IPHASE
								(ProjectID UNIQUEIDENTIFIER,
								IPHASE INT,
								PHASEID UNIQUEIDENTIFIER)
								
								INSERT #IPHASE (ProjectID, IPHASE)
								SELECT ProjectID, IPHASE=MAX (CASE WHEN CHARINDEX('.',ph.Description)> 0 
		 							THEN CASE 
										 WHEN ISNUMERIC(LEFT(ph.Description,CHARINDEX('.', ph.Description)-1))=1 THEN CAST(LEFT(ph.Description,CHARINDEX('.', ph.Description)-1) AS INT)
										 ELSE -1
										 END
		  							ELSE -1
		  							END)
								FROM #PHASE p, ProjectPhase ph WITH (NOLOCK)  
								WHERE p.PHASEID=ph.Code
								GROUP BY p.ProjectID
								create index ix_IPHASE_1 on #IPHASE (ProjectID, IPHASE)
								UPDATE #IPHASE SET IPHASE = -1 WHERE IPHASE IS NULL
								
								UPDATE i SET PHASEID = pp.Code
								FROM #IPHASE i 
								INNER JOIN ProjectPhase pp WITH (NOLOCK)  ON pp.Description LIKE (CAST(i.IPHASE AS VARCHAR)+N'.%'  ) 
								WHERE pp.Deleted=CAST(0 as bit) 
								
								
						    	UPDATE Project  SET 	
									PlannedStart= DATEADD(dd,0, DATEDIFF(dd,0,tp.TminStart)),  
									PlannedFinish= DATEADD(dd,0, DATEDIFF(dd,0,tp.TmaxFinish)), 
									PlannedHours=tp.TSumPlanHours, PlannedDays=tp.TSumPlanDays, PlannedFTE=tp.TSumPlanFTE,
									ActualStart= DATEADD(dd,0, DATEDIFF(dd,0,tp.AminStart)),
								    ActualFinish=CASE WHEN p.ProjectStatus <> 'C'  THEN NULL ELSE  DATEADD(dd,0, DATEDIFF(dd,0,tp.AmaxFinish))  END,
									ActualHours=tp.ASumPlanHours,  ActualDays=tp.ASumPlanDays,  ActualFTE=tp.ASumPlanFTE, 
									RollupForecastStart= DATEADD(dd,0, DATEDIFF(dd,0,tp.FminStart)),
									RollupForecastFinish= DATEADD(dd,0, DATEDIFF(dd,0,tp.FmaxFinish)),
									RollupRemainingHours=tp.RSumPlanHours, RollupRemainingDays=tp.RSumPlanDays,RollupRemainingFTE=tp.RSumPlanFTE,
									PlannedRemainingHours=tp.SUMPlanRemHours, 
									PlannedRemainingDays=tp.SUMPlanRemDays, 
									PlannedRemainingFTE=tp.SUMPlanRemFTE,
									Phase=i.PHASEID,
									RollupLastDate=@NOW,
									SystemNonWorkingDayChanged=CASE WHEN (p.PlannedStart > tp.TminStart) THEN 1 ELSE SystemNonWorkingDayChanged END,
									MSPNonWorkingDayNotSync=CASE WHEN (p.PlannedStart > tp.TminStart) THEN 1 ELSE MSPNonWorkingDayNotSync END,
									UpdatedOn = @NOW
								FROM Project p WITH (NOLOCK)  
								INNER JOIN #Tasks_P tp ON tp.ProjectID = p.ProjectID
								LEFT OUTER JOIN #IPHASE i ON i.ProjectID = p.ProjectID
								
								
								
							END
						
							BEGIN
						    		UPDATE Project  SET 	
									PlannedHours=0,PlannedDays=0, PlannedFTE=0,
									ActualStart=NULL,
									ActualFinish=NULL ,
									ActualHours=0,  ActualDays=0,  ActualFTE=0,
									RollupForecastStart=NULL,
									RollupForecastFinish=NULL,
									RollupRemainingHours=0,RollupRemainingDays=0,RollupRemainingFTE=0,
									PlannedRemainingHours=0, PlannedRemainingDays=0, PlannedRemainingFTE=0,
									Phase=NULL,
									RollupLastDate=@NOW,
									UpdatedOn = @NOW
								FROM Project p WITH (NOLOCK) INNER JOIN
								#Currollup c ON p.ProjectID = c.ProjectID WHERE c.type = 'p' AND LEN(c.OBS) = @OBSLength
								AND NOT EXISTS (SELECT 1 FROM Tasks WITH (NOLOCK)  WHERE ProjectID=c.ProjectID AND Deleted=CAST(0 as bit))
							END
		
						IF EXISTS( SELECT TOP 1 1  FROM #FISCALPROJECT  WHERE FPBillingOfficeID<>@NULLID)
							BEGIN
					
								DELETE   ProjectFiscalRollup  FROM  ProjectFiscalRollup pf WITH (NOLOCK) 
								INNER JOIN #Currollup c ON pf.ProjectID=c.ProjectID
								INNER JOIN #TEMPFISCAL t ON pf.FPBillingOfficeID=t.FPBillingOfficeID
								WHERE c.type = 'p' AND LEN(c.OBS) = @OBSLength
								AND EXISTS(SELECT 1 FROM #FISCALPROJECT p WHERE p.fPeriodCount > 0  AND p.ProjectID = c.ProjectID AND pf.FPBillingOfficeId = p.FPBillingOfficeID AND p.RollupProjectID = t.RollupProjectID) 
								INSERT INTO ProjectFiscalRollup (ProjectID, FPBillingOfficeID, FiscalYearID, FiscalPeriodID, PlannedHours, ActualHours, RemainingHours, ForecastHours, LastRun, PastPeriodUpdated, 
								PlannedDays, PlannedFTE, ActualDays, ActualFTE, RemainingDays, RemainingFTE)
								SELECT c.ProjectID, fp.BillingOfficeID, fp.FiscalYearID, tf.FiscalPeriodID,
								ISNULL(SUM(tf.PlannedHours),0), ISNULL(SUM(tf.ActualHours),0), ISNULL(SUM(tf.RemainingHours),0), ISNULL(SUM(tf.ForecastHours),0),
								@NOW, CASE WHEN MAX(s.SChed) = 1 AND fp.EndDate < @TODAY THEN 1 ELSE 0 END,
								ISNULL(SUM(tf.PlannedDays),0), ISNULL(SUM(tf.PlannedFTE),0), ISNULL(SUM(tf.ActualDays),0), ISNULL(SUM(tf.ActualFTE),0),
								ISNULL(SUM(tf.RemainingDays),0), ISNULL(SUM(tf.RemainingFTE),0)
								FROM #Currollup c
								INNER JOIN Tasks t WITH (NOLOCK) ON t.ProjectID=c.ProjectID AND t.Deleted = 0x0 AND CHARINDEX('.', t.WBS) = 0
								INNER JOIN TaskFiscalRollup tf WITH (NOLOCK) ON t.TaskID=tf.TaskID
								INNER JOIN FiscalPeriod fp WITH (NOLOCK) ON fp.FiscalPeriodID=tf.FiscalPeriodID
								INNER JOIN (SELECT ProjectID, SChed = MAX(CONVERT(INT, SChed)) FROM #FISCALPROJECT GROUP BY ProjectID) s ON s.ProjectID = c.ProjectID
								WHERE
									c.type = 'p' AND LEN(c.OBS) = @OBSLength
									AND NOT EXISTS(SELECT TOP 1 1 FROM ProjectFiscalRollup pr WITH (NOLOCK) WHERE pr.ProjectID=c.ProjectID AND pr.FiscalPeriodID=tf.FiscalPeriodID)
									AND EXISTS(SELECT TOP 1 1 FROM #TEMPFISCAL tm
												INNER JOIN #FISCALPROJECT p ON tm.FPBillingOfficeId = p.FPBillingOfficeID AND tm.RollupProjectID = p.RollupProjectID
													AND p.ProjectID = c.ProjectID AND p.FPBillingOfficeID = fp.BillingOfficeId AND p.fPeriodCount > 0
												WHERE tm.FPBillingOfficeID=tf.FPBillingOfficeID)
								GROUP BY c.ProjectID, fp.BillingOfficeID, fp.FiscalYearID, tf.FiscalPeriodID, fp.EndDate
								HAVING
									((ISNULL(SUM(tf.PlannedHours),0)<>0) OR (ISNULL(SUM(tf.ActualHours),0)<>0) OR (ISNULL(SUM(tf.RemainingHours),0)<>0) OR (ISNULL(SUM(tf.ForecastHours),0)<>0)) 
							END
					END
			
				TRUNCATE TABLE  #Task_Duration
				TRUNCATE TABLE #PND_WorkingDaysConversionDay
				INSERT INTO #Task_Duration (ProjectId, TaskId,WBS)  
				SELECT cr.ProjectId,  cr.Id, cr.WBS FROM  #Currollup cr  WITH (NOLOCK)  WHERE cr.type in ('s', 't') AND LEN(cr.OBS) = @OBSLength 
				UPDATE #Task_Duration SET ChildCount=tt.cnt, Duration =tt.duration
				FROM  #Task_Duration t WITH  (NOLOCK) 
				CROSS APPLY 
				(
					SELECT COUNT(1) cnt, SUM(t2.Duration) duration FROM Tasks t2  WITH (NOLOCK) WHERE t2.Deleted=0x0  AND t2.ProjectId=t.ProjectId
					AND  LEN(t2.WBS) - LEN(REPLACE(t2.WBS,'.',''))= LEN(t.WBS) - LEN(REPLACE(t.WBS,'.','')) +1
					AND t2.WBS  LIKE t.WBS  +'.%'  
				) tt
				WHERE tt.cnt = 1
				INSERT INTO #PND_WorkingDaysConversionDay (LevelType, LevelTypeId, EntityId, StartPeriod, EndPeriod)
				SELECT  CASE WHEN ISNULL(e.AssociatedWorkgroup, @NULLID)=@NULLID THEN 's' ELSE 'w' END, e.AssociatedWorkgroup,
				t.TaskId, t.PlannedStart, t.PlannedFinish
				FROM #Task_Duration tt WITH (NOLOCK) 
				INNER JOIN Tasks t WITH (NOLOCK) ON tt.TaskId=t.TaskId  AND t.Deleted=0x0 
				INNER JOIN Engagement e WITH (NOLOCK) ON e.EngagementId=t.EngagementId
				EXEC dbo.PND_WorkingDaysConversionDay 0x1,0x0
				UPDATE Tasks SET WorkingDays= CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE pnd.WorkingDays END, 
				Duration=CASE WHEN  tt.ChildCount=1 THEN tt.Duration ELSE CASE WHEN pnd.WorkingDays < 0 THEN 0 ELSE pnd.WorkingDays END END,
				WorkingDaysUpdatedOn=GETDATE()
				FROM  Tasks t WITH (NOLOCK)
				INNER JOIN #Task_Duration tt ON tt.TaskId=t.TaskId
				INNER JOIN  #PND_WorkingDaysConversionDay pnd WITH (NOLOCK) ON pnd.EntityId=t.TaskId 
				DELETE #Currollup  WHERE LEN(OBS) = @OBSLength
				SET @OBSLength = ISNULL((SELECT MAX(LEN(OBS)) FROM #Currollup),-1)
			END 
				
		END 
		
		EXEC dbo.CalculateCriticalPath NULL
		UPDATE p  SET RollupLastDate=@NOW
		FROM Project p INNER JOIN #InputPrjID i ON i.RollupProjectID= p.ProjectID
		
		
		UPDATE Project SET RollupInProgress=0x0
		FROM Project p WITH (NOLOCK) 
		INNER JOIN 
		(SELECT DISTINCT Projectid FROM  #FISCALPROJECT) t ON t.ProjectID=p.ProjectId 
		 
	END TRY
	BEGIN CATCH
		
		UPDATE Project SET RollupInProgress=0x0
		FROM Project p WITH (NOLOCK) 
		INNER JOIN 
		(SELECT DISTINCT Projectid FROM  #FISCALPROJECT) t ON t.ProjectID=p.ProjectId 
		 
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		SELECT  @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE();
  
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState );
		
	END CATCH 
SET NOCOUNT OFF

GO
