USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[CleanDailyAllocationData]    Script Date: 10/14/2019 2:31:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CleanDailyAllocationData]
(
	@RequestId		UNIQUEIDENTIFIER,
	@TYPE			VARCHAR(3),
	@RemoveLock		BIT=0
)
AS
SET NOCOUNT ON;
DECLARE @ResourceId UNIQUEIDENTIFIER, @BackUPSessionId UNIQUEIDENTIFIER
IF (@TYPE = 'PPW')
	BEGIN
		DELETE RecordLock 
			FROM ProjectTeamRequest pt WITH (NOLOCK) 
			INNER JOIN RecordLock r WITH (NOLOCK) ON pt.ProjectTeamId = r.RecordId AND r.RecordType = 'PRT' AND r.CreatedBy = @ResourceId
			WHERE pt.LevRequestId = @RequestId
		DELETE ProjectTeamRequest WHERE LevRequestId = @RequestId
		DELETE ProjectTeamBalance WHERE RequestId = @RequestId
		DELETE PTeamDailyallocationRequest WHERE RequestId = @RequestId
	END
ELSE
	BEGIN
		SELECT @ResourceId = ResourceId, @BackUPSessionId = BackUPSessionId FROM TaskDepRequest WITH (NOLOCK) WHERE RequestId = @RequestId
		DELETE RecordLock FROM RecordLock r WITH (NOLOCK)
			WHERE r.RecordType = 'PRT' AND r.CreatedBy = @ResourceId AND ISNULL(r.LockedFrom,'') <> 'RMV'
		DELETE DailyAllocationRequest WHERE RequestId = @RequestId
		DELETE TaskassignmentFiscalRequest WHERE RequestId = @RequestId 
		DELETE TaskAssignmentRequest WHERE RequestId = @RequestId
		DELETE ProcessProjectTeam WHERE RequestId = @RequestId  
		DELETE ProcessProjectTaskDependencies WHERE RequestId = @RequestId
		DELETE ErrorLog WHERE ProcessId = @RequestId
		DELETE ErrorLog WHERE @BackUPSessionId IS NOT NULL AND ProcessId = @BackUPSessionId
		DELETE ProcessResLeveling WHERE RequestId = @RequestId
		DELETE TaskAssignmentDeleteRequest WHERE RequestId = @RequestId
		DELETE ProjectTeamRequest WHERE LevRequestId = @RequestId
		DELETE ProjectTeamBalance WHERE RequestId = @RequestId 
		DELETE PTeamDailyallocationRequest WHERE RequestId = @RequestId 
		IF @TYPE <> 'PSW' AND NOT EXISTS(SELECT TOP 1 1 FROM TaskAssignmentRequest WITH (NOLOCK) WHERE RequestId = @RequestId)
			BEGIN
				DELETE TaskDepRequest WHERE RequestId = @RequestId
			END 
		IF (@TYPE = 'PAW')
			BEGIN
				DELETE RecordLock WHERE CreatedBy = @ResourceId AND RecordType = 'TSK' AND ISNULL(LockedFrom,'') = 'PAW'
			END
		ELSE IF(@Type = 'ASG')
			BEGIN
				DELETE RecordLock WHERE CreatedBy = @ResourceId AND RecordType = 'TSK' AND ISNULL(LockedFrom,'TSK') = 'TSK'
			END
		ELSE IF ((@TYPE NOT IN ('PSW','DAL','IGN','TRT','RMV','RMC','PPW','CSL') ) OR (@RemoveLock=1)) 
			BEGIN
				DELETE RecordLock WHERE CreatedBy = @ResourceId AND RecordType = 'TSK' AND ISNULL(LockedFrom,'') <> 'RMV'
			END
	END

GO
