USE [Changepoint]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_EngagementBillingRate_CG]    Script Date: 10/14/2019 3:46:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[BG_EngagementBillingRate_CG](@EngagementId uniqueidentifier, @BillingRoleId uniqueidentifier, @TimeDate date)
returns table
as
return
select 
	top 1
	--EngagementId,
	--BillingRoleId,
	BillingRate,
	CostRate
from 
	[BG_EngagementBillingRates_Table_CG]
where
	EngagementId=@EngagementId
	and BillingRoleId =@BillingRoleId
	and @TimeDate>=RateStartDate 
	and @TimeDate<=EndDate

GO
