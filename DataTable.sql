CREATE PROCEDURE NHANVIEN_G5
AS
BEGIN
    -- Xóa bảng nếu nó tồn tại để tránh lỗi khi tạo mới
    IF OBJECT_ID('NHANVIEN', 'U') IS NOT NULL
    BEGIN
        DROP TABLE NHANVIEN;
    END;

    -- Tạo bảng NHANVIEN mới
    CREATE TABLE NHANVIEN (
        NHAN_VIEN_ID INT PRIMARY KEY IDENTITY(1,1),
        TITLE NVARCHAR(255) UNIQUE,
        HINH_THUC NVARCHAR(255),
        CAP_BAC NVARCHAR(255),
        KINH_NGHIEM NVARCHAR(255),
        LOCATION NVARCHAR(255)
    );

    -- Thêm dữ liệu duy nhất vào NHANVIEN
    ;WITH TempNHANVIEN AS (
        SELECT DISTINCT TITLE, HINH_THUC, CAP_BAC, KINH_NGHIEM, LOCATION,
               ROW_NUMBER() OVER (PARTITION BY TITLE ORDER BY HINH_THUC) AS rn
        FROM Career_3_copy_1
    )

    INSERT INTO NHANVIEN (TITLE, HINH_THUC, CAP_BAC, KINH_NGHIEM, LOCATION)
    SELECT TITLE, HINH_THUC, CAP_BAC, KINH_NGHIEM, LOCATION
    FROM TempNHANVIEN
    WHERE rn = 1;
END;

CREATE PROCEDURE LUONG_G5
AS
BEGIN
    -- Xóa bảng nếu nó tồn tại để tránh lỗi khi tạo mới
    IF OBJECT_ID('LUONG', 'U') IS NOT NULL
    BEGIN
        DROP TABLE LUONG;
    END;

    -- Tạo bảng LUONG mới
    CREATE TABLE LUONG (
        Luong_ID INT IDENTITY(1,1) PRIMARY KEY,
        Location NVARCHAR(255),
        MIN_Salary FLOAT,
        MAX_Salary FLOAT,
        GroupMajor NVARCHAR(255),
        AVR_MinSalary FLOAT,
        AVR_MaxSalary FLOAT
    );

    -- Thêm dữ liệu vào bảng LUONG từ bảng Career_3_copy_1
    ;WITH TempLUONG AS (
        SELECT 
            Location, 
            MIN_Salary, 
            MAX_Salary, 
            GroupMajor,
            AVG(MIN_Salary) OVER (PARTITION BY GroupMajor) AS AVR_MinSalary,
            AVG(MAX_Salary) OVER (PARTITION BY GroupMajor) AS AVR_MaxSalary
        FROM Career_3_copy_1
    )
    INSERT INTO LUONG (Location, MIN_Salary, MAX_Salary, GroupMajor, AVR_MinSalary, AVR_MaxSalary)
    SELECT Location, MIN_Salary, MAX_Salary, GroupMajor, AVR_MinSalary, AVR_MaxSalary
    FROM TempLUONG
    GROUP BY Location, MIN_Salary, MAX_Salary, GroupMajor, AVR_MinSalary, AVR_MaxSalary;
END;

CREATE PROCEDURE CONGTY_G5
AS
BEGIN
    -- Xóa bảng nếu nó tồn tại để tránh lỗi khi tạo mới
    IF OBJECT_ID('CONGTY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE CONGTY;
    END;

    -- Tạo bảng CONGTY mới
    CREATE TABLE CONGTY (
        CONG_TY_ID INT PRIMARY KEY IDENTITY(1,1),
        EMPLOYER NVARCHAR(255) UNIQUE,
        LOCATION NVARCHAR(255),
        MAJOR NVARCHAR(255)
    );

    -- Thêm dữ liệu duy nhất vào bảng CONGTY từ bảng Career_3_copy_1
    ;WITH TempCONGTY AS (
        SELECT EMPLOYER, LOCATION, MAJOR
        FROM (
            SELECT EMPLOYER, LOCATION, MAJOR,
                   ROW_NUMBER() OVER (PARTITION BY EMPLOYER ORDER BY EMPLOYER) AS rn
            FROM Career_3_copy_1
        ) AS Temp
        WHERE rn = 1  -- Chỉ lấy bản ghi đầu tiên của mỗi nhóm EMPLOYER
    )
    INSERT INTO CONGTY (EMPLOYER, LOCATION, MAJOR)
    SELECT EMPLOYER, LOCATION, MAJOR
    FROM TempCONGTY;
END;

CREATE PROCEDURE CONGVIEC_G5
AS
BEGIN
    -- Xóa bảng nếu nó tồn tại để tránh lỗi khi tạo mới
    IF OBJECT_ID('CONGVIEC', 'U') IS NOT NULL
    BEGIN
        DROP TABLE CONGVIEC;
    END;

    -- Tạo bảng CONGVIEC mới
    CREATE TABLE CONGVIEC (
        CONG_VIEC_ID INT PRIMARY KEY IDENTITY(1,1),
        MAJOR NVARCHAR(255) UNIQUE,
        TITLE NVARCHAR(255),
        UPDATE_DATE DATE,
        CO_HOI DATE,
        GroupMajor VARCHAR(255)
    );

    -- Thêm dữ liệu vào bảng CONGVIEC từ bảng Career_3_copy_1, chỉ chèn các giá trị duy nhất ở cột MAJOR
    ;WITH TempCONGVIEC AS (
        SELECT 
            MAJOR, 
            TITLE, 
            UPDATE_DATE, 
            CO_HOI,
            GroupMajor,
            ROW_NUMBER() OVER (PARTITION BY MAJOR ORDER BY TITLE) AS RowNum
        FROM Career_3_copy_1
    )
    INSERT INTO CONGVIEC (MAJOR, TITLE, UPDATE_DATE, CO_HOI, GroupMajor)
    SELECT 
        MAJOR, TITLE, UPDATE_DATE, CO_HOI, GroupMajor
    FROM TempCONGVIEC
    WHERE RowNum = 1;  -- Chỉ chèn bản ghi đầu tiên theo từng nhóm MAJOR để tránh trùng lặp
END;

CREATE PROCEDURE NhanVien_Luong_G5
AS
BEGIN
    -- Kiểm tra xem bảng NHANVIEN_LUONG đã tồn tại chưa
    IF OBJECT_ID('NHANVIEN_LUONG', 'U') IS NULL
    BEGIN
        CREATE TABLE NHANVIEN_LUONG (
            NHAN_VIEN_ID INT,
            LUONG_ID INT,
            FOREIGN KEY (NHAN_VIEN_ID) REFERENCES NHANVIEN(NHAN_VIEN_ID),
            FOREIGN KEY (LUONG_ID) REFERENCES LUONG(LUONG_ID)
        );
    END;

    -- Chèn các kết hợp giữa NHANVIEN và LUONG dựa trên điều kiện LOCATION
    INSERT INTO NHANVIEN_LUONG (NHAN_VIEN_ID, LUONG_ID)
    SELECT DISTINCT NV.NHAN_VIEN_ID, L.LUONG_ID
    FROM NHANVIEN NV
    INNER JOIN LUONG L 
        ON NV.LOCATION = L.LOCATION;  -- Sử dụng điều kiện LOCATION phù hợp giữa hai bảng
END;

CREATE PROCEDURE NhanVien_CongViec_G5
AS
BEGIN
    IF OBJECT_ID('NHANVIEN_CONGVIEC', 'U') IS NULL
    BEGIN
        CREATE TABLE NHANVIEN_CONGVIEC (
            NHAN_VIEN_ID INT,
            CONG_VIEC_ID INT,
            PRIMARY KEY (NHAN_VIEN_ID, CONG_VIEC_ID),
            FOREIGN KEY (NHAN_VIEN_ID) REFERENCES NHANVIEN(NHAN_VIEN_ID),
            FOREIGN KEY (CONG_VIEC_ID) REFERENCES CONGVIEC(CONG_VIEC_ID)
        );
    END;

    INSERT INTO NHANVIEN_CONGVIEC (NHAN_VIEN_ID, CONG_VIEC_ID)
    SELECT DISTINCT NV.NHAN_VIEN_ID, CV.CONG_VIEC_ID 
    FROM NHANVIEN NV
    INNER JOIN CONGVIEC CV ON NV.TITLE = CV.TITLE;  -- Điều kiện JOIN được giữ nguyên
END;

CREATE PROCEDURE NhanVien_CongTy_G5
AS
BEGIN
    -- Tạo bảng NHANVIEN_CONGTY nếu chưa tồn tại, với NHAN_VIEN_ID và CONG_TY_ID làm khóa ngoại.
    IF OBJECT_ID('NHANVIEN_CONGTY', 'U') IS NULL
    BEGIN
        CREATE TABLE NHANVIEN_CONGTY (
            NHAN_VIEN_ID INT,
            CONG_TY_ID INT,
            LOCATION NVARCHAR(255),
            PRIMARY KEY (NHAN_VIEN_ID, CONG_TY_ID),
            FOREIGN KEY (NHAN_VIEN_ID) REFERENCES NHANVIEN(NHAN_VIEN_ID),
            FOREIGN KEY (CONG_TY_ID) REFERENCES CONGTY(CONG_TY_ID)
        );
    END;

    -- Thêm dữ liệu vào NHANVIEN_CONGTY từ bảng NHANVIEN và CONGTY nơi có giá trị LOCATION giống nhau.
    INSERT INTO NHANVIEN_CONGTY (NHAN_VIEN_ID, CONG_TY_ID, LOCATION)
    SELECT DISTINCT NV.NHAN_VIEN_ID, CT.CONG_TY_ID, CT.LOCATION
    FROM NHANVIEN NV
    INNER JOIN CONGTY CT ON NV.LOCATION = CT.LOCATION;  -- JOIN dựa trên LOCATION chung
END;

CREATE PROCEDURE CongTy_Luong_G5
AS
BEGIN
    -- Tạo bảng CONGTY_LUONG nếu chưa tồn tại, với CONG_TY_ID và LUONG_ID làm khóa ngoại.
    IF OBJECT_ID('CONGTY_LUONG', 'U') IS NULL
    BEGIN
        CREATE TABLE CONGTY_LUONG (
            CONG_TY_ID INT,
            LUONG_ID INT,
            PRIMARY KEY (CONG_TY_ID, LUONG_ID),
            FOREIGN KEY (CONG_TY_ID) REFERENCES CONGTY(CONG_TY_ID),
            FOREIGN KEY (LUONG_ID) REFERENCES LUONG(LUONG_ID)
        );
    END;

    -- Thêm dữ liệu vào CONGTY_LUONG từ bảng CONGTY và LUONG nơi có giá trị LOCATION giống nhau.
    INSERT INTO CONGTY_LUONG (CONG_TY_ID, LUONG_ID)
    SELECT DISTINCT CT.CONG_TY_ID, L.LUONG_ID
    FROM CONGTY CT
    INNER JOIN LUONG L ON CT.LOCATION = L.LOCATION;  -- Liên kết giữa CONG_TY và LUONG
END;

CREATE PROCEDURE CongTy_CongViec_G5
AS
BEGIN
    -- Tạo bảng CONGTY_CONGVIEC nếu chưa tồn tại, với CONG_TY_ID và CONG_VIEC_ID làm khóa ngoại.
    IF OBJECT_ID('CONGTY_CONGVIEC', 'U') IS NULL
    BEGIN
        CREATE TABLE CONGTY_CONGVIEC (
            CONG_TY_ID INT,
            CONG_VIEC_ID INT,
            PRIMARY KEY (CONG_TY_ID, CONG_VIEC_ID),
            FOREIGN KEY (CONG_TY_ID) REFERENCES CONGTY(CONG_TY_ID),
            FOREIGN KEY (CONG_VIEC_ID) REFERENCES CONGVIEC(CONG_VIEC_ID)
        );
    END;

    -- Thêm dữ liệu vào CONGTY_CONGVIEC từ bảng CONGTY và CONGVIEC nơi có giá trị MAJOR giống nhau.
    INSERT INTO CONGTY_CONGVIEC (CONG_TY_ID, CONG_VIEC_ID)
    SELECT DISTINCT CT.CONG_TY_ID, CV.CONG_VIEC_ID
    FROM CONGTY CT
    INNER JOIN CONGVIEC CV ON CT.MAJOR = CV.MAJOR;  -- Liên kết giữa CONG_TY và CONGVIEC theo MAJOR
END;

CREATE PROCEDURE CongViec_Luong_G5
AS
BEGIN
    -- Kiểm tra và tạo bảng CongViec_Luong nếu chưa tồn tại.
    IF OBJECT_ID('CongViec_Luong', 'U') IS NULL
    BEGIN
        CREATE TABLE CongViec_Luong (
            CONG_VIEC_ID INT,
            LUONG_ID INT,
            GroupMajor VARCHAR(255),
            PRIMARY KEY (CONG_VIEC_ID, LUONG_ID),
            FOREIGN KEY (CONG_VIEC_ID) REFERENCES CONGVIEC(CONG_VIEC_ID),
            FOREIGN KEY (LUONG_ID) REFERENCES LUONG(LUONG_ID)
        );
    END;

    -- Thêm dữ liệu vào CongViec_Luong từ bảng CONGVIEC và LUONG nơi có giá trị GroupMajor giống nhau.
    INSERT INTO CongViec_Luong (CONG_VIEC_ID, LUONG_ID, GroupMajor)
    SELECT DISTINCT CV.CONG_VIEC_ID, L.LUONG_ID, CV.GroupMajor
    FROM CONGVIEC CV
    INNER JOIN LUONG L ON CV.GroupMajor = L.GroupMajor;  -- Liên kết giữa CONGVIEC và LUONG theo GroupMajor
END;

EXEC NHANVIEN_G5
EXEC LUONG_G5;
EXEC CONGTY_G5;
EXEC CONGVIEC_G5;
EXEC NhanVien_Luong_G5;
EXEC NhanVien_CongViec_G5;
EXEC NhanVien_CongTy_G5;
EXEC CongTy_Luong_G5;
EXEC CongTy_CongViec_G5;
EXEC CongViec_Luong_G5