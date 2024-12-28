-- Xóa thành viên khỏi db_owner role
EXEC sp_droprolemember 'db_owner', 'Thy';

-- Xóa thành viên khỏi data_entry role
EXEC sp_droprolemember 'DE', 'Phuc';

-- Xóa thành viên khỏi read_only role
EXEC sp_droprolemember 'DA', 'Sang';

-- Xóa role db_owner (admin)
DROP ROLE Admin_Thy;

-- Xóa role data_entry
DROP ROLE DE;
drop role DA

-- Xóa user Phuc
DROP USER Phuc;

-- Xóa user Thy
DROP USER Thy;

-- Xóa user Sang
DROP USER Sang;

-- Xóa login Phuc
DROP LOGIN Phuc;

-- Xóa login Thy
DROP LOGIN Thy;

-- Xóa login Sang
DROP LOGIN Sang;
--Phuc
CREATE LOGIN Phuc WITH PASSWORD = '123';
CREATE USER Phuc FOR LOGIN Phuc;

CREATE ROLE DE;
EXEC sp_addrolemember 'DE', 'Phuc';


GRANT CREATE FUNCTION TO DE;
GRANT CREATE PROCEDURE TO DE;
GRANT ALTER TO DE;
GRANT CONTROL TO DE;
GRANT DELETE TO DE;
GRANT EXECUTE TO DE;
GRANT INSERT TO DE;
GRANT SELECT TO DE;
GRANT UPDATE TO DE;
GRANT CONNECT TO DE;


--Thy
create LOGIN Thy WITH PASSWORD = '123';
CREATE USER Thy FOR LOGIN Thy;

CREATE ROLE Admin_owner;
EXEC sp_addrolemember @rolename = 'db_owner', @membername = 'Thy';
EXEC sp_addrolemember 'db_backupoperator', 'Admin_owner';
EXEC sp_addrolemember 'db_owner', 'Admin_owner';

-- Quyền trên các chức năng, thủ tục, và đối tượng
GRANT CREATE FUNCTION TO Admin_owner;
GRANT CREATE PROCEDURE TO Admin_owner;
GRANT ALTER TO Admin_owner;
GRANT CONTROL TO Admin_owner;
GRANT DELETE TO Admin_owner;
GRANT EXECUTE TO Admin_owner;
GRANT INSERT TO Admin_owner;
GRANT SELECT TO Admin_owner;
GRANT UPDATE TO Admin_owner;
GRANT CONNECT TO Admin_owner;

-- Quyền quản lý người dùng
GRANT CREATE USER TO Admin_owner;
GRANT ALTER ANY USER TO Admin_owner;
GRANT DROP USER TO Admin_owner;



-- Quyền quản lý đối tượng trong cơ sở dữ liệu
GRANT CREATE TABLE TO Admin_owner; -- Tạo bảng
GRANT ALTER TO Admin_owner;       -- Sửa đổi bảng hoặc các đối tượng khác
GRANT CONTROL TO Admin_owner;     -- Bao gồm quyền DROP TABLE

GRANT CREATE VIEW TO Admin_owner; -- Tạo view
GRANT ALTER TO Admin_owner;       -- Sửa đổi view
GRANT CONTROL TO Admin_owner;     -- Bao gồm quyền DROP VIEW

GRANT ALTER ANY SCHEMA TO Admin_owner; -- Sửa đổi bất kỳ schema nào
GRANT CONTROL TO Admin_owner;         -- Quyền kiểm soát toàn bộ schema

-- Quyền sao lưu và phục hồi
GRANT BACKUP DATABASE TO Admin_owner;
GRANT RESTORE DATABASE TO Admin_owner;

-- Cấp quyền CONTROL trên schema dbo cho admin_owner
GRANT CONTROL ON SCHEMA::dbo TO Admin_owner;




BACKUP DATABASE DatabaseofGroup5 TO DISK = 'D:\BACKUP\admin_g5.bak';


--Sang
create LOGIN Sang WITH PASSWORD = '123';
CREATE USER Sang FOR LOGIN Sang;
-- Tạo role DA
CREATE ROLE DA;
EXEC sp_addrolemember 'DA', 'Sang';

GRANT SELECT TO DA;
GRANT CONNECT TO DA;

--kiểm tra admin
SELECT dp.permission_name, dp.state_desc, dp.class_desc, dp.major_id, 
       p.name AS PrincipalName, o.name AS ObjectName
FROM sys.database_permissions dp
JOIN sys.database_principals p ON dp.grantee_principal_id = p.principal_id
LEFT JOIN sys.objects o ON dp.major_id = o.object_id
WHERE p.name = 'admin_owner'

--kiểm tra data_entry
SELECT dp.permission_name, dp.state_desc, dp.class_desc, dp.major_id, 
       p.name AS PrincipalName, o.name AS ObjectName
FROM sys.database_permissions dp
JOIN sys.database_principals p ON dp.grantee_principal_id = p.principal_id
LEFT JOIN sys.objects o ON dp.major_id = o.object_id
WHERE p.name = 'DE'

--kiểm tra read_only
SELECT dp.permission_name, dp.state_desc, dp.class_desc, dp.major_id, 
       p.name AS PrincipalName, o.name AS ObjectName
FROM sys.database_permissions dp
JOIN sys.database_principals p ON dp.grantee_principal_id = p.principal_id
LEFT JOIN sys.objects o ON dp.major_id = o.object_id
WHERE p.name='DA'

SELECT r.name AS RoleName, m.name AS MemberName
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id;


--thu hồi
ALTER ROLE db_owner DROP MEMBER Thy;

ALTER ROLE data_entry DROP MEMBER Phuc;

ALTER ROLE read_only DROP MEMBER Sang;


WITH PermissionData AS (
    -- Lấy tất cả quyền của AdminRole
    SELECT DISTINCT
        dp1.permission_name,
        p1.name AS PrincipalName
    FROM 
        sys.database_permissions dp1
    JOIN 
        sys.database_principals p1 
        ON dp1.grantee_principal_id = p1.principal_id
    WHERE 
        p1.name = 'admin_owner'
    
    UNION ALL  -- Gộp dữ liệu của DE và DA

    -- Lấy quyền của DE và DA
    SELECT DISTINCT
        dp1.permission_name,
        p1.name AS PrincipalName
    FROM 
        sys.database_permissions dp1
    JOIN 
        sys.database_principals p1 
        ON dp1.grantee_principal_id = p1.principal_id
    WHERE 
        p1.name IN ('DE', 'DA')
)

-- Pivot để hiển thị quyền trong bảng
SELECT 
    permission_name,
    MAX(CASE WHEN PrincipalName = 'admin_owner' THEN 'X' ELSE '' END) AS AdminRole,
    MAX(CASE WHEN PrincipalName = 'DE' THEN 'X' ELSE '' END) AS DE,
    MAX(CASE WHEN PrincipalName = 'DA' THEN 'X' ELSE '' END) AS DA
FROM 
    PermissionData
GROUP BY 
    permission_name
-- Sắp xếp theo số lượng 'X' giảm dần và tên quyền
ORDER BY 
    -- Tính số lượng dấu 'X' trong ORDER BY, không thêm cột mới
    (CASE WHEN MAX(CASE WHEN PrincipalName = 'admin_owner' THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END +
     CASE WHEN MAX(CASE WHEN PrincipalName = 'DE' THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END +
     CASE WHEN MAX(CASE WHEN PrincipalName = 'DA' THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END) DESC,
    permission_name;  -- Thứ tự phụ theo tên quyền



