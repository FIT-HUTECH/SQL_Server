﻿USE MASTER 
IF EXISTS(SELECT * FROM SYS.DATABASES WHERE NAME = 'QLDL')
DROP DATABASE QLDL 
GO 

CREATE DATABASE QLDL
GO 

USE QLDL 

--SET DATEFORMAT DMY
--GO 
CREATE TABLE DUKHACH
(
	MAKH VARCHAR (5) NOT NULL PRIMARY KEY ,
	TENKH NVARCHAR (50) NOT NULL,
	DIACHI NVARCHAR (50) 
)
CREATE TABLE PHIEUDANGKY
(
	SOPHIEU INT NOT NULL PRIMARY KEY ,
	NGAYLAP DATE ,
	MAKH VARCHAR (5),
	TONGTIEN BIGINT,
	FOREIGN KEY (MAKH) REFERENCES DUKHACH(MAKH) 
)
CREATE TABLE TOUR 
(
	MATOUR NVARCHAR (5)NOT NULL PRIMARY KEY, 
	LOTRINH NVARCHAR (30) ,
	HANHTRINH NVARCHAR (50),
	GIATOUR INT
)
CREATE TABLE THONGTINDANGKY
(
	SOPHIEU INT ,
	MATOUR NVARCHAR (5),
	SONGUOI INT 
	PRIMARY KEY (SOPHIEU,MATOUR)
	FOREIGN KEY (SOPHIEU) REFERENCES PHIEUDANGKY (SOPHIEU),
	FOREIGN KEY (MATOUR) REFERENCES TOUR (MATOUR)
)

------INSERT DUKHACH-------
INSERT INTO DUKHACH VALUES 
('KH1',N'CONG TY TOAN THANG','TAN BINH'),
('KH2',N'NGUYEN VAN HUNG','QUAN 1'),
('KH3',N'LE THANH TUAN','QUAN 5'),
('KH4',N'CONG TY HUNG THINH','QUAN 7')
SELECT * FROM DUKHACH
------INSERT PHIEUDKY-------
SET DATEFORMAT DMY
GO 

INSERT INTO PHIEUDANGKY VALUES 
(01,'10/10/2012','KH1',0),
(02,'27/10/2012','KH2',0),
(03,'01/11/2012','KH3',0),
(04,'10/11/2012','KH1',0),
(05,'15/11/2012','KH4',0)
SELECT * FROM PHIEUDANGKY

------INSERT TOUR---------
INSERT INTO TOUR VALUES 
('T1','TP HCM-PHANTHIET','3 NGAY 2 DEM',2500000),
('T2','TP HCM-NHATRANG','4 NGAY 3 DEM',5000000),
('T3','TP HCM-HOIAN','6 NGAY 5 DEM',8500000),
('T4','TP HCM-HALONG','5 NGAY 4 DEM',1000000)
SELECT * FROM TOUR 

------INSERT TTDK-------
INSERT INTO THONGTINDANGKY VALUES 
(01,'T1',25),
(02,'T1',5),
(03,'T2',2),
(04,'T2',20),
(05,'T2',15)
SELECT * FROM THONGTINDANGKY 

--a. Tạo View tên V1 tìm các khách hàng là công ty đăng ký tour với số người trên 20. 
--Thông tin hiển thị gồm : MAKH, TENKH, MATOUR, LOTRINH, SONGUOI 
CREATE VIEW CAU1_VIEW
AS
SELECT D.MAKH, D.TENKH, T.MATOUR, T.LOTRINH, TT.SONGUOI 
FROM DUKHACH D
INNER JOIN PHIEUDANGKY P ON D.MAKH = P.MAKH
INNER JOIN THONGTINDANGKY TT ON P.SOPHIEU = TT.SOPHIEU
INNER JOIN TOUR T ON TT.MATOUR = T.MATOUR
WHERE TT.SONGUOI > 20

SELECT * FROM CAU1_VIEW
--b. Tạo Procedure tên P1 tìm các tour có doanh thu cao nhất. Thông tin hiển thị
--gồm : MATOUR, LOTRINH, HANHTRINH, TỔNG DOANH THU (Tổng doanh thu =Tổng của số người * Giá tour) 
CREATE PROC CAU2_PROC (@X SMALLINT)
AS
	SELECT TOP (@X) T.MATOUR, T.LOTRINH,T.HANHTRINH, (SUM(TT.SONGUOI)*T.GIATOUR) AS [TONG DOANH THU]
	FROM TOUR T
	INNER JOIN THONGTINDANGKY TT ON T. MATOUR = TT.MATOUR
	GROUP BY T.MATOUR, T.LOTRINH, T.HANHTRINH,T.GIATOUR
	ORDER BY [TONG DOANH THU] DESC
EXEC CAU2_PROC 3 

--c. Tạo Function tên F1 trả về tổng số lượng người đăng ký theo từng tour, nếu
--tour nào chưa được đăng ký thì trả về giá trị 0. Tham số là mã tour. 
CREATE FUNCTION CAU3_FUNC (@MT VARCHAR(5) NULL)
RETURNS @TONG_DKY TABLE 
( MATOUR VARCHAR (5) , TONG_DKY BIGINT)
AS
BEGIN 
	IF(@MT IS NULL )INSERT INTO @TONG_DKY
			SELECT T.MATOUR ,CASE 
							WHEN SUM(TT.SONGUOI) > 0 THEN SUM(TT.SONGUOI)
							WHEN SUM(TT.SONGUOI) IS NULL THEN 0
							END
			FROM TOUR T 
			LEFT JOIN THONGTINDANGKY TT ON T.MATOUR = TT.MATOUR 
			GROUP BY T.MATOUR
	ELSE INSERT INTO @TONG_DKY
			SELECT T.MATOUR ,CASE 
							WHEN SUM(TT.SONGUOI) > 0 THEN SUM(TT.SONGUOI)
							WHEN SUM(TT.SONGUOI) IS NULL THEN 0
							END
			FROM TOUR T 
			LEFT JOIN THONGTINDANGKY TT ON T.MATOUR = TT.MATOUR 
			WHERE T.MATOUR = @MT
			GROUP BY T.MATOUR
			
	RETURN;
END
select * from CAU3_FUNC(NULL)

--d. Tạo Trigger tên T1 thực hiện yêu cầu sau : Tự động tính và cập nhật tổng tiền
--vào table PHIEUDANGKY, nếu khách nào chưa đăng ký thì cập nhật giá trị 0 
CREATE TRIGGER CAU4_TRIGGER 
ON PHIEUDANGKY 
FOR UPDATE 
AS 
BEGIN 
	UPDATE PHIEUDANGKY 
	SET PHIEUDANGKY.TONGTIEN = CASE WHEN P.MAKH IS NULL THEN 0
									ELSE TT.SONGUOI*T.GIATOUR
									END 
	FROM TOUR T 
	LEFT JOIN THONGTINDANGKY TT ON TT.MATOUR = T.MATOUR
	INNER JOIN PHIEUDANGKY P ON P.SOPHIEU = TT.SOPHIEU
	LEFT JOIN DUKHACH D ON D.MAKH = P.MAKH
END




