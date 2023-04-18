USE QLBH
GO
---CAU1
CREATE TRIGGER TRG_NHAP
ON NHAP
FOR INSERT
AS
BEGIN
	DECLARE @MASP NVARCHAR(10),@MANV NVARCHAR(10)
	DECLARE @SLN INT, @DGN FLOAT
	SELECT @MASP=MASP, @MANV=MANV,@SLN=soluongN,@DGN= dongiaN
	from inserted
if (not exists(select*from SANPHAM where MASP=@MASP))
		begin
			raiserror(N'Không tồn tại sản phẩm trong danh mục sản phẩm',16,1)
			rollback transaction
		end
	else 
		if(not exists(select*from NHANVIEN where MANV=@MANV))
			begin
				raiserror(N'Không tồn tại nhân viên có mã này',16,1)
				rollback transaction
		end
	else
		if(@SLN<=0 or @DGN<=0)
			begin
				raiserror(N'Nhập sai số lượng hoặc đơn giá',16,1)
				rollback transaction
			end
		else

	update SANPHAM set SOLUONG=SOLUONG+@SLN from SANPHAM where MASP=@MASP
end
select*from SANPHAM
select*from NHANVIEN
select*from NHAP
---CAU2
CREATE TRIGGER KiemSoatNhapXuat
ON Xuat
AFTER INSERT
AS
BEGIN
    DECLARE @masp VARCHAR(10)
    DECLARE @manv VARCHAR(10)
    DECLARE @soluongX INT
    DECLARE @soluongSP INT

    SELECT @masp = masp, @manv = manv, @soluongX = soluongX 
    FROM inserted

    -- Kiểm tra masp có tồn tại trong bảng Sanpham hay không?
    IF NOT EXISTS (SELECT masp FROM Sanpham WHERE masp = @masp)
    BEGIN
        RAISERROR('Mã sản phẩm không tồn tại trong bảng Sanpham', 16, 1)
        ROLLBACK
        RETURN
    END

    -- Kiểm tra manv có tồn tại trong bảng Nhanvien hay không?
    IF NOT EXISTS (SELECT manv FROM Nhanvien WHERE manv = @manv)
    BEGIN
        RAISERROR('Mã nhân viên không tồn tại trong bảng Nhanvien', 16, 1)
        ROLLBACK
        RETURN
    END

    -- Kiểm tra số lượng xuất có nhỏ hơn số lượng trong bảng Sanpham hay không?
    SELECT @soluongSP = soluong FROM Sanpham WHERE masp = @masp

    IF @soluongSP < @soluongX
    BEGIN
        RAISERROR('Số lượng xuất lớn hơn số lượng trong bảng Sanpham', 16, 1)
        ROLLBACK
        RETURN
    END

    -- Cập nhật số lượng sản phẩm sau khi xuất
    UPDATE Sanpham SET soluong = soluong - @soluongX WHERE masp = @masp
END


INSERT INTO Xuat (sohdx, masp, manv, ngayxuat, soluongX)
`VALUES ('HDX001', 'SP001', 'NV001', '2023-04-08', 5)

--cau3
drop trigger tr_XoaPhieuXuat
CREATE TRIGGER tr_XoaPhieuXuat
ON Xuat
AFTER DELETE
AS
BEGIN
    DECLARE @masp nchar(20), @soluong INT
    
    SELECT @masp = deleted.masp, @soluong = deleted.soluongX
    FROM deleted
    
    UPDATE Sanpham
    SET soluong = soluong + @soluong
    WHERE masp = @masp
END

DELETE FROM Xuat WHERE sohdx = N'X01';
SELECT*FROM XUAT
---cau4
CREATE TRIGGER UpdateSoLuongXuat ON Xuat
AFTER UPDATE
AS
BEGIN
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM INSERTED) > 1
BEGIN
    RAISERROR('Chỉ được cập nhật một bản ghi tại một thời điểm', 16, 1)
    ROLLBACK
    RETURN
END

IF EXISTS (SELECT 1 FROM DELETED d INNER JOIN Sanpham s ON d.masp = s.masp WHERE d.soluongX > s.soluong)
BEGIN
    RAISERROR('Số lượng xuất thay đổi không được nhỏ hơn số lượng sản phẩm', 16, 1)
    ROLLBACK
    RETURN
END

UPDATE Sanpham
SET soluong = soluong + d.soluongX - i.soluongX
FROM Sanpham s
INNER JOIN DELETED d ON s.masp = d.masp
INNER JOIN INSERTED i ON s.masp = i.masp
END

-- Thực thi trigger
UPDATE Xuat
SET soluongX = 10
WHERE sohdx = 'X02' AND masp = 'SP01'
--cau5
CREATE TRIGGER tr_UpdateSoluongNhap
ON Nhap
AFTER UPDATE
AS
BEGIN
    IF (SELECT COUNT(*) FROM inserted) > 1
    BEGIN
        RAISERROR('Chỉ được phép cập nhật một bản ghi tại một thời điểm', 16, 1)
        ROLLBACK
        RETURN
    END

    DECLARE @soluongN_old int, @soluongN_new int, @masp int

    SELECT @soluongN_old = soluongN FROM deleted
    SELECT @soluongN_new = soluongN FROM inserted
    SELECT @masp = masp FROM inserted

    IF (@soluongN_new < @soluongN_old)
    BEGIN
        RAISERROR('Số lượng nhập không được giảm', 16, 1)
        ROLLBACK
        RETURN
    END

    UPDATE Sanpham
    SET soluong = soluong + (@soluongN_new - @soluongN_old)
    WHERE masp = @masp
END
--cau6
CREATE TRIGGER update_soluongsanpham
ON Nhap
AFTER DELETE
AS

BEGIN
    
    UPDATE Sanpham
    SET Soluong = Sanpham.Soluong - deleted.soluongN
    FROM Sanpham
    JOIN deleted ON Sanpham.Masp = deleted.Masp
END


