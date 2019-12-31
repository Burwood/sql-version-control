USE [Changepoint]
GO
/****** Object:  View [dbo].[D_WriteOffsByResource]    Script Date: 12/31/2019 9:58:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[D_WriteOffsByResource]
AS
SELECT DISTINCT TOP 999999 '00000000-0000-0000-0000-000000000000' AS RevenueDetailID, dbo.Engagement.CustomerId, dbo.Engagement.EngagementID, dbo.Engagement.[Name], dbo.Engagement.RevRecDate,
				dbo.Time.ResourceId, 
				SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId, dbo.Time.ResourceId) AS ResourceHours, 
				SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId) AS TotalHours,
				CASE WHEN 
					ISNULL(SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId), 0) = 0 THEN 0 
				ELSE 
					SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId, dbo.Time.ResourceId) 
					/ SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId)
				END AS ResourcePercent,
				-SUM(((dbo.Time.RegularHours + dbo.Time.OvertimeHours) * dbo.Time.BillingRate) - ISNULL(dbo.Time.RevRec, 0)) OVER(PARTITION BY dbo.Time.EngagementId) AS TotalAmount,
				CASE WHEN 
					ISNULL(SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId), 0) = 0 THEN 0 
				ELSE 
					(SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId, dbo.Time.ResourceId) 
					/ SUM(dbo.Time.RegularHours + dbo.Time.OvertimeHours) OVER(PARTITION BY dbo.Time.EngagementId)) *
					-SUM(((dbo.Time.RegularHours + dbo.Time.OvertimeHours) * dbo.Time.BillingRate) - ISNULL(dbo.Time.RevRec, 0)) OVER(PARTITION BY dbo.Time.EngagementId)
				END AS ResourceAmount

FROM  dbo.Engagement
	  JOIN dbo.Time ON dbo.Time.EngagementId = dbo.Engagement.EngagementId
WHERE EngagementStatus = 'F' AND engagement.RevRecDate > '2019-01-01' 
ORDER BY Engagement.EngagementID, dbo.Time.ResourceId
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "AdditionalItems"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_WriteOffsByResource'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_WriteOffsByResource'
GO
