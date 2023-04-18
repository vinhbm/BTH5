USE QLBH
GO
---CAU1
CREATE PROCEDURE spThemMoiNhanVien 
(
    @manv varchar(10),
    @tennv nvarchar(50),
    @gioitinh nvarchar(10),
    @diachi nvarchar(100),
    @sodt varchar(20),
    @email varchar(50),
    @phong varchar(50),
    @flag bit
)
AS
BEGIN
    IF (@gioitinh <> 'Nam' AND @gioitinh <> 'Nữ')
    BEGIN
        RETURN 1 -- Trả về mã lỗi 1 nếu giới tính không hợp lệ
    END

    IF (@flag = 0)
    BEGIN
        INSERT INTO Nhanvien(manv, tennv, gioitinh, diachi, sodt, email, phong)
        VALUES (@manv, @tennv, @gioitinh, @diachi, @sodt, @email, @phong)
    END
    ELSE
    BEGIN
        UPDATE Nhanvien
        SET tennv = @tennv, gioitinh = @gioitinh, diachi = @diachi, sodt = @sodt, email = @email,
            phong = @phong
        WHERE manv = @manv
    END

    RETURN 0 -- Trả về mã lỗi 0 nếu thực hiện thành công
END

EXEC spThemMoiNhanVien 'NV001', N'Nguyễn Văn A', 'Nam', N'123 Đường A', '0987654320', 'nva@gmail.com', 'Kế toán', 0
SELECT*FROM NHANVIEN
-- cau2
drop proc ThemSanPham
CREATE PROCEDURE ThemSanPham 
    @masp VARCHAR(10), 
    @tenhang VARCHAR(50), 
    @tensp NVARCHAR(100), 
    @soluong INT, 
    @mausac NVARCHAR(50), 
    @giaban FLOAT, 
    @donvitinh NVARCHAR(20), 
    @mota NVARCHAR(MAX), 
    @flag INT
AS 
BEGIN 
    IF @flag = 0 -- thêm mới sản phẩm
    BEGIN
        IF NOT EXISTS (SELECT * FROM Hangsx WHERE tenhang = @tenhang)
            RETURN 1 -- trả về mã lỗi 1 nếu tenhang không có trong bảng hangsx
        IF @soluong < 0
            RETURN 2 -- trả về mã lỗi 2 nếu soluong < 0
        INSERT INTO Sanpham (masp, mahangsx, tensp, soluong, mausac, giaban, donvitinh, mota)
        VALUES (@masp, (SELECT mahangsx FROM Hangsx WHERE tenhang = @tenhang), @tensp, @soluong, @mausac, @giaban, @donvitinh, @mota)
    END
    ELSE -- cập nhật sản phẩm
    BEGIN
        IF @soluong < 0
            RETURN 2 -- trả về mã lỗi 2 nếu soluong < 0
        UPDATE Sanpham 
        SET mahangsx = (SELECT mahangsx FROM Hangsx WHERE tenhang = @tenhang), 
            tensp = @tensp, 
            soluong = @soluong, 
            mausac = @mausac, 
            giaban = @giaban, 
            donvitinh = @donvitinh, 
            mota = @mota 
        WHERE masp = @masp
    END 
    RETURN 0 -- trả về mã lỗi 0 nếu không có lỗi 
END

EXEC ThemSanPham 'SP05', 'Iphone', 'iPhone 13', 10, 'Đỏ', 20000000, 'Cái', N'Thế hệ mới', 0
SELECT*FROM SANPHAM
--cau3
CREATE PROCEDURE sp_XoaNhanVien
    @manv char(20),
    @result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra xem mã nhân viên có tồn tại hay không
    IF NOT EXISTS (SELECT 1 FROM Nhanvien WHERE manv = @manv)
    BEGIN
        SET @result = 1;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        -- Xóa các bản ghi trong bảng Nhap
        DELETE FROM Nhap WHERE manv = @manv;
        -- Xóa các bản ghi trong bảng Xuat
        DELETE FROM Xuat WHERE manv = @manv;
        -- Xóa bản ghi trong bảng Nhanvien
        DELETE FROM Nhanvien WHERE manv = @manv;
        SET @result = 0;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @result = ERROR_NUMBER();
        -- Rollback transaction nếu có lỗi xảy ra
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH;
END

DECLARE @result INT;
EXEC sp_XoaNhanVien @manv='NV001', @result = @result OUTPUT;
SELECT @result AS 'Result';
SELECT*FROM NHANVIEN
--cau4
CREATE PROCEDURE xoaSanPham(@masp nchar(20))
AS
BEGIN
    -- kiểm tra sản phẩm có tồn tại trong bảng sản phẩm hay không
    IF NOT EXISTS(SELECT * FROM sanpham WHERE masp = @masp)
    BEGIN
        RETURN 1; -- trả về mã lỗi 1 nếu sản phẩm không tồn tại trong bảng sản phẩm
    END
    
    -- xóa các bản ghi trong bảng nhập và bảng xuất liên quan đến sản phẩm cần xóa
    DELETE FROM nhap WHERE masp = @masp;
    DELETE FROM xuat WHERE masp = @masp;
    
    -- xóa bản ghi trong bảng sản phẩm
    DELETE FROM sanpham WHERE masp = @masp;

    RETURN 0; -- trả về mã lỗi 0 nếu xóa sản phẩm thành công
END

EXEC xoaSanPham SP05; -- ví dụ xóa sản phẩm có mã sp là 05
SELECT*FROM SANPHAM
SELECT*FROM NHAP
SELECT*FROM XUAT
--cau5	
CREATE PROCEDURE ThemHangSX
    @mahangsx nvarchar(50),
    @tenhang nvarchar(50),
    @diachi nvarchar(100),
    @sodt nvarchar(20),
    @email nvarchar(50)
AS
BEGIN
    -- Kiểm tra xem tên hãng đã tồn tại hay chưa
    IF EXISTS (SELECT * FROM HangSX WHERE TenHangSX = @tenhang)
    BEGIN
        SELECT 1 AS 'ErrorCode', 'Tên hãng đã tồn tại' AS 'ErrorMessage'
        RETURN
    END
    
    -- Nếu chưa tồn tại thì thêm mới vào bảng
    INSERT INTO HangSX (MaHangSX, TenHangSX, DiaChi, SoDT, Email)
    VALUES (@mahangsx, @tenhang, @diachi, @sodt, @email)
    
    SELECT 0 AS 'ErrorCode', 'Thêm hãng sản xuất thành công' AS 'ErrorMessage'
END

EXEC ThemHangSX 'HSX001', 'Apple', N'123 Lê Hồng Phong', '012356789', 'contact@apple.com';


