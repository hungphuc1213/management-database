-- Sao chép dữ liệu từ bảng Career_3 sang bảng Career_3_copy_1

SELECT * into Career_3_copy_1
FROM Career_3
WHERE 1 = 0;

INSERT INTO Career_3_copy_1
SELECT * FROM Career_3

-- Sử dụng thủ tục và hàm để tiền xử lý

/* 1. Title */

CREATE PROCEDURE remove_new_2
AS
BEGIN
    UPDATE Career_3_copy_1
    SET TITLE = REPLACE(TITLE, N'(MỚI)', '');
END;
EXEC remove_new_2

/* Xóa trùng lặp */

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TITLE, SALARY, LOCATION, OPPORTUNITY, UPDATE_DATE, EMPLOYER, MAJOR, HINH_THUC, KINH_NGHIEM, CAP_BAC ORDER BY (SELECT NULL)) AS XOA_TRUNG_LAP
    FROM Career_3_copy_1
)
DELETE FROM CTE
WHERE XOA_TRUNG_LAP > 1;
select * from Career_3_copy_1

/* 2. Salary và Location */

ALTER TABLE Career_3_copy_1
        ADD MIN_SALARY FLOAT,
            MAX_SALARY FLOAT;

CREATE PROCEDURE Career_3_Location_Salaryy
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Career_3_copy_1' AND COLUMN_NAME = 'MIN_SALARY')
    BEGIN
        ALTER TABLE Career_3_copy_1
        ADD MIN_SALARY FLOAT,
            MAX_SALARY FLOAT;
    END

    UPDATE Career_3_copy_1
    SET SALARY = REPLACE(REPLACE(SALARY, N'Lương: ', ''), ',', '.')
    WHERE SALARY LIKE N'%Lương: %' OR SALARY LIKE '%,%';

    UPDATE Career_3_copy_1
    SET 
        MIN_SALARY = CASE 
                        WHEN SALARY LIKE N'Trên % Tr VND' AND CHARINDEX(N' ', SALARY) > 0 THEN 
                            CAST(SUBSTRING(SALARY, CHARINDEX(N' ', SALARY) + 1, 
                                  CHARINDEX(N' Tr', SALARY) - CHARINDEX(N' ', SALARY) - 1) AS FLOAT)
                        WHEN SALARY LIKE N'% - %' AND CHARINDEX(N' ', SALARY) > 0 THEN 
                            CAST(SUBSTRING(SALARY, 1, CHARINDEX(N' ', SALARY) - 1) AS FLOAT)
                        ELSE 
                            NULL 
                     END,

        MAX_SALARY = CASE 
                        WHEN SALARY LIKE N'% - %' AND CHARINDEX(N'-', SALARY) > 0 AND CHARINDEX(N' Tr', SALARY, CHARINDEX(N'-', SALARY)) > 0 THEN 
                            CAST(SUBSTRING(SALARY, CHARINDEX(N'-', SALARY) + 1, 
                                  CHARINDEX(N' Tr', SALARY, CHARINDEX(N'-', SALARY)) - CHARINDEX(N'-', SALARY) - 1) AS FLOAT)
                        ELSE 
                            NULL 
                     END;

    UPDATE Career_3_copy_1
    SET LOCATION = 
        CASE 
            WHEN LOCATION LIKE N'%Hà Nội%' AND LOCATION LIKE N'%Đà Nẵng%' AND LOCATION LIKE N'%Hồ Chí Minh%' THEN N'Hà Nội, Đà Nẵng, Hồ Chí Minh'
            WHEN LOCATION LIKE N'%Hà Nội%' AND LOCATION LIKE N'%Đà Nẵng%' THEN N'Hà Nội, Đà Nẵng'
            WHEN LOCATION LIKE N'%Hà Nội%' AND LOCATION LIKE N'%Hồ Chí Minh%' THEN N'Hà Nội, Hồ Chí Minh'
            WHEN LOCATION LIKE N'%Đà Nẵng%' AND LOCATION LIKE N'%Hồ Chí Minh%' THEN N'Đà Nẵng, Hồ Chí Minh'
            WHEN LOCATION LIKE N'%Hà Nội%' THEN N'Hà Nội'
            WHEN LOCATION LIKE N'%Đà Nẵng%' THEN N'Đà Nẵng'
            WHEN LOCATION LIKE N'%Hồ Chí Minh%' THEN N'Hồ Chí Minh'
            ELSE LOCATION
        END
    WHERE LOCATION LIKE N'%Hà Nội%' OR LOCATION LIKE N'%Đà Nẵng%' OR LOCATION LIKE N'%Hồ Chí Minh%';

    UPDATE Career_3_copy_1
    SET MIN_SALARY = CASE
        WHEN MIN_SALARY IS NULL AND LOCATION LIKE N'%Đà Nẵng%' AND (LOCATION LIKE N'%Hà Nội%' OR LOCATION LIKE N'%Hồ Chí Minh%') THEN 4.41
        WHEN MIN_SALARY IS NULL AND LOCATION LIKE N'%Đà Nẵng%' THEN 4.41
        WHEN MIN_SALARY IS NULL AND (LOCATION LIKE N'%Hà Nội%' OR LOCATION LIKE N'%Hồ Chí Minh%') THEN 4.96
        ELSE MIN_SALARY
    END
    WHERE MIN_SALARY IS NULL;
END;

exec Career_3_Location_Salaryy

/* 3. Co hoi */
UPDATE Career_3_copy_1
SET OPPORTUNITY = REPLACE(OPPORTUNITY, N'Hạn nộp: ', '');

Alter table Career_3_copy_1
add co_hoi nvarchar(10)

CREATE FUNCTION dbo.Co_Hoi_2(@opportunity NVARCHAR(MAX), @update_date NVARCHAR(10))
RETURNS NVARCHAR(10)
AS
BEGIN
    DECLARE @result NVARCHAR(10)

    IF @opportunity LIKE N'%Cơ hội ứng tuyển chỉ còn:%'
    BEGIN
        SET @result = FORMAT(DATEADD(DAY,
            CASE 
                WHEN TRY_CAST(SUBSTRING(@opportunity, CHARINDEX(':', @opportunity) + 1, 2) AS INT) IS NOT NULL THEN
                    CAST(SUBSTRING(@opportunity, CHARINDEX(':', @opportunity) + 1, 2) AS INT)
                ELSE 
                    0  -- Giá trị mặc định
            END,
            TRY_CONVERT(DATE, @update_date, 105)
        ), 'yyyy-MM-dd')
    END
    ELSE IF @opportunity LIKE N'Cơ hội chỉ còn: Hôm nay'
    BEGIN
        SET @result = FORMAT(TRY_CONVERT(DATE, @update_date, 105), 'yyyy-MM-dd')
    END
    ELSE
    BEGIN
        SET @result = FORMAT(TRY_CONVERT(DATE, @opportunity, 105), 'yyyy-MM-dd')
    END

    RETURN @result
END

UPDATE Career_3_copy_1
SET co_hoi = dbo.Co_Hoi_2(opportunity, update_date)
WHERE 
    TRY_CONVERT(DATE, update_date, 105) IS NOT NULL 
    AND (TRY_CONVERT(DATE, opportunity, 105) IS NOT NULL OR 
         opportunity LIKE N'%Cơ hội ứng tuyển chỉ còn:%' OR 
         opportunity LIKE N'Cơ hội chỉ còn: Hôm nay');
select * from Career_3_copy_1

/* Xóa cột OPPORTUNITY */
Alter table Career_3_copy_1
drop column OPPORTUNITY

/* 4. Cap Bac, Kinh nghiem, Hinh thuc */
CREATE PROCEDURE remove_hethannop_capbac_2
AS
BEGIN
    UPDATE Career_3_copy_1
    SET CAP_BAC = NULL
    WHERE CAP_BAC LIKE N'Hết hạn nộp%';
END;

EXEC remove_hethannop_capbac_2;

/* Chuyển nội dung từ cột cấp bậc sang kinh nghiệm */
CREATE PROCEDURE UpdateCapBacFromKinhNghiem
AS
BEGIN
    -- Cập nhật cột CAP_BAC với giá trị từ KINH_NGHIEM nếu bắt đầu bằng 'Cấp bậc'
    UPDATE Career_3_copy_1
    SET CAP_BAC = CASE 
                    WHEN KINH_NGHIEM LIKE N'Cấp bậc%' THEN KINH_NGHIEM
                    ELSE CAP_BAC
                  END,
        KINH_NGHIEM = CASE 
                        WHEN KINH_NGHIEM LIKE N'Cấp bậc%' THEN NULL
                        ELSE KINH_NGHIEM
                      END
    WHERE KINH_NGHIEM LIKE N'Cấp bậc%';
END;
EXEC UpdateCapBacFromKinhNghiem;

/* 5. Clean toàn bộ những cột còn lại */ 

CREATE PROCEDURE Clean_Career_Data
AS
BEGIN
    -- CLEAN KINH NGHIỆM
    UPDATE Career_3_copy_1
    SET KINH_NGHIEM = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(KINH_NGHIEM, CHAR(13), ''), CHAR(10), ''), N'Kinh nghiệm', '')));
    
    -- CLEAN CẤP BẬC
    UPDATE Career_3_copy_1
    SET CAP_BAC = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(CAP_BAC, CHAR(13), ''), CHAR(10), ''), N'Cấp bậc', '')));
    
    -- CLEAN HÌNH THỨC
    UPDATE Career_3_copy_1
    SET HINH_THUC = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(HINH_THUC, CHAR(13), ''), CHAR(10), ''), N'Hình thức', '')));
    
    UPDATE Career_3_copy_1
    SET HINH_THUC = REPLACE(HINH_THUC, N'Hình thức', '');
    
    -- CLEAN MAJOR
    UPDATE Career_3_copy_1
    SET Major = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(Major, CHAR(13), ''), CHAR(10), ''), N'Ngành nghề', '')));
    
    -- CHUYỂN KIỂU DỮ LIỆU UPDATE_DATE
    UPDATE Career_3_copy_1
    SET UPDATE_DATE = CONVERT(DATE, UPDATE_DATE, 105);
END;
GO

/* 6. Thêm cột GroupMajor */

ALTER TABLE Career_3_copy_1
ADD GroupMajor VARCHAR(255);

CREATE PROCEDURE Update_GroupMajor
AS
BEGIN
    -- Bước 1: Cập nhật giá trị cho GroupMajor từ phần đầu tiên của MAJOR (trước dấu phẩy hoặc dấu gạch chéo)
    UPDATE Career_3_copy_1
    SET GroupMajor = CASE
        WHEN CHARINDEX(',', MAJOR) > 0 THEN LEFT(MAJOR, CHARINDEX(',', MAJOR) - 1)
        WHEN CHARINDEX('/', MAJOR) > 0 THEN LEFT(MAJOR, CHARINDEX('/', MAJOR) - 1)
        ELSE MAJOR
    END;

    -- Bước 2: Gắn nhãn các nhóm GroupMajor
    UPDATE Career_3_copy_1
    SET GroupMajor = CASE
        WHEN GroupMajor LIKE '%Dịch vụ khách hàng%' OR GroupMajor LIKE '%An Ninh / Bảo Vệ%' OR GroupMajor LIKE '%Bảo hiểm%' THEN 'Customer Service'
        WHEN GroupMajor LIKE '%Tiếp thị / Marketing%' OR GroupMajor LIKE '%Tiếp thị trực tuyến%' OR GroupMajor LIKE '%Quảng cáo / Đối ngoại / Truyền Thông%' THEN 'Marketing'
        WHEN GroupMajor LIKE '%Bán hàng / Kinh doanh%' OR GroupMajor LIKE '%Bán lẻ / Bán sỉ%' THEN 'Sales'
        WHEN GroupMajor LIKE '%CNTT - Phần mềm%' OR GroupMajor LIKE '%CNTT - Phần cứng / Mạng%' OR GroupMajor LIKE '%Bưu chính viễn thông%' THEN 'IT'
        WHEN GroupMajor LIKE '%Nhân sự%' OR GroupMajor LIKE '%Hành chính / Thư ký%' THEN 'Human Resources'
        WHEN GroupMajor LIKE '%Kế toán / Kiểm toán%' OR GroupMajor LIKE '%Tài chính / Đầu tư%' OR GroupMajor LIKE '%Ngân hàng%' THEN 'Finance'
        WHEN GroupMajor LIKE '%Cơ khí / Ô tô / Tự động hóa%' OR GroupMajor LIKE '%Điện / Điện tử / Điện lạnh%' THEN 'Engineering'
        WHEN GroupMajor LIKE '%Y tế / Chăm sóc sức khỏe%' OR GroupMajor LIKE '%Dược phẩm%' THEN 'Healthcare'
        WHEN GroupMajor LIKE '%Giáo dục / Đào tạo%' OR GroupMajor LIKE '%Mới tốt nghiệp / Thực tập%' THEN 'Education'
        WHEN GroupMajor LIKE '%Vận chuyển / Giao nhận / Kho vận%' OR GroupMajor LIKE '%Xuất nhập khẩu%' THEN 'Logistics'
        WHEN GroupMajor LIKE '%Xây dựng%' OR GroupMajor LIKE '%Kiến trúc%' THEN 'Construction'
        WHEN GroupMajor LIKE '%Sản xuất / Vận hành sản xuất%' OR GroupMajor LIKE '%Quản lý chất lượng (QA/QC)%' THEN 'Manufacturing'
        WHEN GroupMajor LIKE '%Luật / Pháp lý%' THEN 'Legal'
        WHEN GroupMajor LIKE '%Tư vấn%' THEN 'Consulting'
        WHEN GroupMajor LIKE '%Thực phẩm & Đồ uống%' OR GroupMajor LIKE '%Công nghệ thực phẩm / Dinh dưỡng%' THEN 'Food & Beverage'
        WHEN GroupMajor LIKE '%Mỹ thuật / Nghệ thuật / Thiết kế%' OR GroupMajor LIKE '%Giải trí%' THEN 'Creative Arts'
        WHEN GroupMajor LIKE '%Bất động sản%' THEN 'Real Estate'
        WHEN GroupMajor LIKE '%Môi trường%' THEN 'Environmental'
        WHEN GroupMajor LIKE '%Nông nghiệp%' OR GroupMajor LIKE '%Chăn nuôi / Thú y%' THEN 'Agriculture'
        WHEN GroupMajor LIKE '%Truyền hình / Báo chí / Biên tập%' THEN 'Media'
        WHEN GroupMajor LIKE '%Dệt may / Da giày / Thời trang%' THEN 'Textile & Fashion'
        WHEN GroupMajor LIKE '%Nhà hàng / Khách sạn%' OR GroupMajor LIKE '%Du lịch%' THEN 'Hospitality & Tourism'
        WHEN GroupMajor LIKE '%Biên phiên dịch%' THEN 'Translation & Interpretation'
        ELSE 'Other'
    END;
END;
GO

exec Update_GroupMajor

/* 7. Thêm cột AVR_MinSalary và AVR_MaxSalary */
ALTER TABLE Career_3_copy_1
ADD AVR_MinSalary float;
add AVR_MaxSalary float

CREATE PROCEDURE Update_AverageSalary
AS
BEGIN
    -- Cập nhật cột AVR_MinSalary với giá trị trung bình của MIN_SALARY nhóm theo GroupMajor
    UPDATE Career_3_copy_1
    SET AVR_MinSalary = (
        SELECT AVG(MIN_SALARY)
        FROM Career_3_copy_1 AS sub
        WHERE sub.GroupMajor = Career_3_copy_1.GroupMajor
    );

    -- Cập nhật cột AVR_MaxSalary với giá trị trung bình của MAX_SALARY nhóm theo GroupMajor
    UPDATE Career_3_copy_1
    SET AVR_MaxSalary = (
        SELECT AVG(MAX_SALARY)
        FROM Career_3_copy_1 AS sub
        WHERE sub.GroupMajor = Career_3_copy_1.GroupMajor
    );
END;
GO

EXEC Update_AverageSalary






