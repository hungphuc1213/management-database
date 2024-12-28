CREATE PROCEDURE BackupFullDatabase05
AS
BEGIN
    -- Tạo tên file sao lưu với thời gian
    DECLARE @BackupFileName NVARCHAR(255);
    SET @BackupFileName = 'D:\BackupAzure\DatabaseofGroup5_FULL_' + 
                          REPLACE(CONVERT(VARCHAR(20), GETDATE(), 120), ':', '-') + '.bak';

    -- Sao lưu toàn bộ cơ sở dữ liệu
    BACKUP DATABASE [DatabaseofGroup5]
    TO DISK = @BackupFileName
    WITH INIT, COMPRESSION, STATS = 10;
    
    PRINT 'Full database backup saved to: ' + @BackupFileName;
END;
GO

-- Kiểm tra và xóa Job nếu đã tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'BackupFullDatabaseDailyJob')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'BackupFullDatabaseDailyJob';
    PRINT 'Existing job "BackupFullDatabaseDailyJob" has been deleted.';
END;

-- Kiểm tra và xóa lịch nếu đã tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = N'DailyFullDatabaseBackupSchedule')
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'DailyFullDatabaseBackupSchedule';
    PRINT 'Existing schedule "DailyFullDatabaseBackupSchedule" has been deleted.';
END;

-- Tạo lại Job sao lưu toàn bộ cơ sở dữ liệu
EXEC msdb.dbo.sp_add_job 
    @job_name = N'BackupFullDatabaseDailyJob', 
    @enabled = 1, 
    @description = N'Sao lưu toàn bộ cơ sở dữ liệu cho DatabaseofGroup5';

-- Tạo Job Step cho sao lưu toàn bộ cơ sở dữ liệu
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'BackupFullDatabaseDailyJob', 
    @step_name = N'BackupFullDatabaseDailyStep',
    @subsystem = N'TSQL', 
    @command = N'EXEC BackupFullDatabaseDaily;', 
    @database_name = N'master', 
    @on_success_action = 1,  -- Tiếp tục
    @on_fail_action = 2;     -- Dừng

-- Tạo lịch sao lưu hàng ngày lúc 1h30 sáng
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'DailyFullDatabaseBackupSchedule', 
    @enabled = 1, 
    @freq_type = 4,            -- Lặp lại hàng ngày
    @freq_interval = 1,        -- Chạy mỗi ngày
    @active_start_time = 012200, 
    @active_end_time = 235959;  

-- Gán lịch vào Job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'BackupFullDatabaseDailyJob', 
    @schedule_name = N'DailyFullDatabaseBackupSchedule';

-- Gán Job vào SQL Server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'BackupFullDatabaseDailyJob';

PRINT 'Job "BackupFullDatabaseDailyJob" and schedule "DailyFullDatabaseBackupSchedule" have been created successfully.';


CREATE PROCEDURE BackupDifferential05
AS
BEGIN
    -- Tạo tên file sao lưu với thời gian
    DECLARE @DiffBackupFileName NVARCHAR(255);
    SET @DiffBackupFileName = 'D:\BackupAzure\DatabaseofGroup5_DIFF_' + 
                              REPLACE(CONVERT(VARCHAR(20), GETDATE(), 120), ':', '-') + '.bak';

    -- Sao lưu Differential
    BACKUP DATABASE [DatabaseofGroup5]
    TO DISK = @DiffBackupFileName
    WITH DIFFERENTIAL, COMPRESSION, STATS = 10;

    PRINT 'Differential backup saved to: ' + @DiffBackupFileName;
END;
GO

-- Kiểm tra và xóa Job nếu đã tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'BackupDifferentialJob')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'BackupDifferentialJob';
    PRINT 'Existing job "BackupDifferentialJob" has been deleted.';
END;

-- Kiểm tra và xóa lịch nếu đã tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = N'DifferentialBackupSchedule')
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'DifferentialBackupSchedule';
    PRINT 'Existing schedule "DifferentialBackupSchedule" has been deleted.';
END;

-- Tạo lại Job sao lưu Differential
EXEC msdb.dbo.sp_add_job 
    @job_name = N'BackupDifferentialJob', 
    @enabled = 1, 
    @description = N'Sao lưu Differential cho DatabaseofGroup5';

-- Tạo Job Step cho sao lưu Differential
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'BackupDifferentialJob', 
    @step_name = N'BackupDifferentialStep',
    @subsystem = N'TSQL', 
    @command = N'EXEC BackupDifferential05;', 
    @database_name = N'master', 
    @on_success_action = 1,  -- Tiếp tục
    @on_fail_action = 2;     -- Dừng

-- Tạo lịch sao lưu Differential mỗi giờ
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'DifferentialBackupSchedule', 
    @enabled = 1, 
    @freq_type = 4,            -- Lặp lại hàng ngày
    @freq_interval = 1,        -- Chạy mỗi ngày
    @freq_subday_type = 4,     -- Lặp lại theo phút
    @freq_subday_interval = 60, -- Lặp lại mỗi 1 giờ
    @active_start_time = 020000,    
    @active_end_time = 235959;

-- Gán lịch vào Job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'BackupDifferentialJob', 
    @schedule_name = N'DifferentialBackupSchedule';

-- Gán Job vào SQL Server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'BackupDifferentialJob';

PRINT 'Job "BackupDifferentialJob" and schedule "DifferentialBackupSchedule" have been created successfully.';

CREATE PROCEDURE BackupTransactionLog05
AS
BEGIN
    -- Tạo tên file sao lưu với thời gian
    DECLARE @LogBackupFileName NVARCHAR(255);
    SET @LogBackupFileName = 'D:\BackupAzure\DatabaseofGroup5_LOG_' + 
                             REPLACE(CONVERT(VARCHAR(20), GETDATE(), 120), ':', '-') + '.trn';

    -- Sao lưu Transaction Log
    BACKUP LOG [DatabaseofGroup5]
    TO DISK = @LogBackupFileName
    WITH INIT, COMPRESSION, STATS = 10;

    PRINT 'Transaction Log backup saved to: ' + @LogBackupFileName;
END;
GO

-- Kiểm tra và xóa Job nếu đã tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'BackupTransactionLogJob')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'BackupTransactionLogJob';
    PRINT 'Existing job "BackupTransactionLogJob" has been deleted.';
END;

-- Kiểm tra và xóa lịch nếu đã tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = N'Every5MinutesTransactionLogBackupSchedule')
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'Every5MinutesTransactionLogBackupSchedule';
    PRINT 'Existing schedule "Every5MinutesTransactionLogBackupSchedule" has been deleted.';
END;

-- Tạo lại Job sao lưu Transaction Log
EXEC msdb.dbo.sp_add_job 
    @job_name = N'BackupTransactionLogJob', 
    @enabled = 1, 
    @description = N'Sao lưu Transaction Log cho DatabaseofGroup5 mỗi 5 phút';

-- Tạo Job Step cho sao lưu Transaction Log
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'BackupTransactionLogJob', 
    @step_name = N'BackupTransactionLogStep',
    @subsystem = N'TSQL', 
    @command = N'EXEC BackupTransactionLog05;', 
    @database_name = N'master', 
    @on_success_action = 1,  -- Tiếp tục
    @on_fail_action = 2;     -- Dừng

-- Tạo lịch sao lưu Transaction Log mỗi 5 phút
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Every5MinutesTransactionLogBackupSchedule', 
    @enabled = 1, 
    @freq_type = 4,            -- Lặp lại hàng ngày
    @freq_interval = 1,        -- Chạy mỗi ngày
    @freq_subday_type = 4,     -- Lặp lại theo phút
    @freq_subday_interval = 5, -- Lặp lại mỗi 5 phút
    @active_start_time = 012500,    
    @active_end_time = 235959; 

-- Gán lịch vào Job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'BackupTransactionLogJob', 
    @schedule_name = N'Every5MinutesTransactionLogBackupSchedule';

-- Gán Job vào SQL Server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'BackupTransactionLogJob';

PRINT 'Job "BackupTransactionLogJob" and schedule "Every5MinutesTransactionLogBackupSchedule" have been created successfully.';


EXEC BackupFullDatabase05
EXEC BackupDifferential05
EXEC BackupTransactionLog05

-- Xóa tất cả storeprocedure
-- Tạo lệnh xóa tất cả thủ tục
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'DROP PROCEDURE [' + SCHEMA_NAME(schema_id) + N'].[' + name + N'];' + CHAR(13)
FROM sys.procedures;

-- Thực thi các lệnh xóa
EXEC sp_executesql @sql;

PRINT 'All stored procedures have been dropped.';

-- Xóa tất cả Jobs trong SQL Server Agent
DECLARE @job_name NVARCHAR(256);

DECLARE job_cursor CURSOR FOR
SELECT name
FROM msdb.dbo.sysjobs;

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = @job_name;
    PRINT 'Job deleted: ' + @job_name;
    FETCH NEXT FROM job_cursor INTO @job_name;
END;

-- Xóa tất cả lịch trong SQL Server Agent bằng cách sử dụng schedule_id
DECLARE @schedule_id INT;
DECLARE @schedule_name NVARCHAR(256);

DECLARE schedule_cursor CURSOR FOR
SELECT schedule_id, name
FROM msdb.dbo.sysschedules;

OPEN schedule_cursor;
FETCH NEXT FROM schedule_cursor INTO @schedule_id, @schedule_name;

	
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC msdb.dbo.sp_delete_schedule @schedule_id = @schedule_id;
        PRINT 'Schedule deleted: ' + @schedule_name + ' (ID: ' + CAST(@schedule_id AS NVARCHAR) + ')';
    END TRY
    BEGIN CATCH
        PRINT 'Error deleting schedule: ' + @schedule_name + ' (ID: ' + CAST(@schedule_id AS NVARCHAR) + ')';
        PRINT ERROR_MESSAGE();
    END CATCH;

    FETCH NEXT FROM schedule_cursor INTO @schedule_id, @schedule_name;
END;

CLOSE schedule_cursor;
DEALLOCATE schedule_cursor;


