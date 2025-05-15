# AWS CloudWatch Dashboard for Backup and Disaster Recovery Monitoring

resource "aws_cloudwatch_dashboard" "backup_dr" {
  dashboard_name = "${var.project_name}-backup-dr-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${upper(var.environment)} Backup & Disaster Recovery Dashboard"
        }
      },
      # AWS Backup Job Status
      {
        type   = "text"
        x      = 0
        y      = 1
        width  = 24
        height = 1
        properties = {
          markdown = "## AWS Backup Job Status"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", aws_backup_vault.main.name, "State", "COMPLETED", { "stat" = "Sum", "label": "Completed" }],
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", aws_backup_vault.main.name, "State", "FAILED", { "stat" = "Sum", "label": "Failed" }],
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", aws_backup_vault.main.name, "State", "EXPIRED", { "stat" = "Sum", "label": "Expired" }]
          ]
          region = var.aws_region
          title  = "Backup Jobs Status - Main Vault"
          period = 86400 # 1 day
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", aws_backup_vault.secondary.name, "State", "COMPLETED", { "stat" = "Sum", "label": "Completed" }],
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", aws_backup_vault.secondary.name, "State", "FAILED", { "stat" = "Sum", "label": "Failed" }],
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", aws_backup_vault.secondary.name, "State", "EXPIRED", { "stat" = "Sum", "label": "Expired" }]
          ]
          region = var.secondary_region
          title  = "Backup Jobs Status - Secondary Vault"
          period = 86400 # 1 day
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Backup", "NumberOfRecoveryPointsCompleted", "BackupVaultName", aws_backup_vault.main.name, { "stat" = "Sum", "label": "Main Region" }],
            ["AWS/Backup", "NumberOfRecoveryPointsCompleted", "BackupVaultName", aws_backup_vault.secondary.name, { "stat" = "Sum", "label": "Secondary Region" }]
          ]
          region = var.aws_region
          title  = "Recovery Points Created"
          period = 86400 # 1 day
        }
      },
      # Backup Job Duration
      {
        type   = "text"
        x      = 0
        y      = 8
        width  = 24
        height = 1
        properties = {
          markdown = "## Backup Job Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Backup", "JobDuration", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "RDS", { "stat" = "Average", "label": "RDS" }],
            ["AWS/Backup", "JobDuration", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "EBS", { "stat" = "Average", "label": "EBS" }],
            ["AWS/Backup", "JobDuration", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "DynamoDB", { "stat" = "Average", "label": "DynamoDB" }],
            ["AWS/Backup", "JobDuration", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "EFS", { "stat" = "Average", "label": "EFS" }]
          ]
          region = var.aws_region
          title  = "Backup Job Duration by Resource Type (seconds)"
          period = 86400 # 1 day
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Backup", "JobSize", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "RDS", { "stat" = "Average", "label": "RDS" }],
            ["AWS/Backup", "JobSize", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "EBS", { "stat" = "Average", "label": "EBS" }],
            ["AWS/Backup", "JobSize", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "DynamoDB", { "stat" = "Average", "label": "DynamoDB" }],
            ["AWS/Backup", "JobSize", "BackupVaultName", aws_backup_vault.main.name, "ResourceType", "EFS", { "stat" = "Average", "label": "EFS" }]
          ]
          region = var.aws_region
          title  = "Backup Job Size by Resource Type (bytes)"
          period = 86400 # 1 day
        }
      },
      # Restore Job Status
      {
        type   = "text"
        x      = 0
        y      = 15
        width  = 24
        height = 1
        properties = {
          markdown = "## Restore Job Status"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/Backup", "NumberOfRestoreJobsCompleted", "State", "COMPLETED", { "stat" = "Sum", "label": "Completed" }],
            ["AWS/Backup", "NumberOfRestoreJobsCompleted", "State", "FAILED", { "stat" = "Sum", "label": "Failed" }]
          ]
          region = var.aws_region
          title  = "Restore Jobs Status - Main Region"
          period = 86400 # 1 day
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 16
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Backup", "RestoreJobDuration", "ResourceType", "RDS", { "stat" = "Average", "label": "RDS" }],
            ["AWS/Backup", "RestoreJobDuration", "ResourceType", "EBS", { "stat" = "Average", "label": "EBS" }],
            ["AWS/Backup", "RestoreJobDuration", "ResourceType", "DynamoDB", { "stat" = "Average", "label": "DynamoDB" }],
            ["AWS/Backup", "RestoreJobDuration", "ResourceType", "EFS", { "stat" = "Average", "label": "EFS" }]
          ]
          region = var.aws_region
          title  = "Restore Job Duration by Resource Type (seconds)"
          period = 86400 # 1 day
        }
      },
      # Cross-Region Replication
      {
        type   = "text"
        x      = 0
        y      = 22
        width  = 24
        height = 1
        properties = {
          markdown = "## Cross-Region Replication"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 23
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Backup", "NumberOfCopyJobsCompleted", "State", "COMPLETED", { "stat" = "Sum", "label": "Completed" }],
            ["AWS/Backup", "NumberOfCopyJobsCompleted", "State", "FAILED", { "stat" = "Sum", "label": "Failed" }]
          ]
          region = var.aws_region
          title  = "Cross-Region Copy Jobs Status"
          period = 86400 # 1 day
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 23
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Backup", "CopyJobDuration", { "stat" = "Average", "label": "Copy Duration" }]
          ]
          region = var.aws_region
          title  = "Cross-Region Copy Job Duration (seconds)"
          period = 86400 # 1 day
        }
      },
      # Automated Testing Status
      {
        type   = "text"
        x      = 0
        y      = 29
        width  = 24
        height = 1
        properties = {
          markdown = "## Backup Testing Status"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${var.project_name}/BackupTesting", "TestSuccess", { "stat" = "Average", "label": "Success Rate (%)" }],
            ["${var.project_name}/BackupTesting", "TestDuration", { "stat" = "Average", "label": "Test Duration (seconds)", "yAxis": "right" }]
          ]
          region = var.aws_region
          title  = "Automated Backup Testing Results"
          period = 86400 # 1 day
        }
      }
    ]
  })
}

# Output dashboard URL
output "backup_dr_dashboard_url" {
  description = "URL for the Backup & DR dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.backup_dr.dashboard_name}"
}
