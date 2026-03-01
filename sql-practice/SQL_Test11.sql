-- Case Study 1: Phân Tích Hiệu Quả Quản Lý Nhân Sự
-- Bối cảnh: Công ty muốn phân tích hiệu quả nhân sự, như số lượng nhân viên trong từng phòng ban, thâm niên làm việc của nhân viên, 
--và phân bố nhân viên theo chức danh công việc.
-- Câu hỏi phân tích:
-- 1.	Phân bố số lượng nhân viên trong từng phòng ban.
-- 2.	Tính tuổi nghề (thâm niên) trung bình của nhân viên trong từng phòng ban.
-- 3.	Tìm nhân viên có thâm niên lâu nhất trong mỗi phòng ban.
-- Gợi ý:
-- •	Dữ liệu cần thiết: Sử dụng các bảng HumanResources.Employee, HumanResources.Department, và Person.Person từ AdventureWorks2019.

--1.1
SELECT 
    c.Name,
    COUNT(a.BusinessEntityID) as SLNV
FROM HumanResources.Employee  a
LEFT JOIN HumanResources.EmployeeDepartmentHistory b
    ON a.BusinessEntityID =  b.BusinessEntityID
LEFT JOIN HumanResources.Department c 
    ON b.DepartmentID = c.DepartmentID
GROUP BY c.Name

--1.2
SELECT 
    c.Name,
    COUNT(a.BusinessEntityID) as SLNV,
    AVG(DATEDIFF(YEAR,HireDate,CURRENT_TIMESTAMP)) as THAMNIEN
FROM HumanResources.Employee  a
LEFT JOIN HumanResources.EmployeeDepartmentHistory b
    ON a.BusinessEntityID =  b.BusinessEntityID
LEFT JOIN HumanResources.Department c 
    ON b.DepartmentID = c.DepartmentID
GROUP BY c.Name;

--1.3
WITH emp_thamnien AS
(
    SELECT 
        c.Name as PHONGBAN,
        a.BusinessEntityID,
        CONCAT_WS(' ',FirstName,MiddleName,LastName) as Fullname,
        YEAR(CURRENT_TIMESTAMP) - YEAR(HireDate) as THAMNIEN
    FROM HumanResources.Employee  a
    LEFT JOIN HumanResources.EmployeeDepartmentHistory b
        ON a.BusinessEntityID =  b.BusinessEntityID
    LEFT JOIN HumanResources.Department c 
        ON b.DepartmentID = c.DepartmentID
    LEFT JOIN Person.Person d
        ON a.BusinessEntityID =  d.BusinessEntityID
    GROUP BY c.Name,a.BusinessEntityID,CONCAT_WS(' ',FirstName,MiddleName,LastName),YEAR(CURRENT_TIMESTAMP) - YEAR(HireDate)
)
, rank_thamnien as
(
    SELECT 
        PHONGBAN,
        BusinessEntityID,
        Fullname,
        THAMNIEN,
        ROW_NUMBER() OVER(PARTITION BY PHONGBAN ORDER BY THAMNIEN DESC) RN
    FROM emp_thamnien 
)
SELECT 
    PHONGBAN,
    BusinessEntityID,
    Fullname,
    THAMNIEN
FROM rank_thamnien 
WHERE RN = 1


-- Case Study 2: Phân Tích Hàng Tồn Kho
-- Bối cảnh: Công ty muốn hiểu rõ hơn về tình trạng hàng tồn kho, bao gồm số lượng tồn kho hiện tại, 
--sản phẩm nào đang gần hết hàng, và hiệu quả sử dụng kho.
-- Câu hỏi phân tích:
-- 1.	Sản phẩm nào có lượng tồn kho thấp nhất?
-- 2.	Tính tổng giá trị tồn kho của từng danh mục sản phẩm.
-- 3.	Phân tích sự phân bổ tồn kho theo từng kho chứa hàng.
-- Gợi ý:
-- •	Dữ liệu cần thiết: Sử dụng bảng Production.ProductInventory, Production.Product, Production.ProductCategory, và Production.Location.

--2.1
WITH tonkho_sp AS
(
    SELECT 
        a.ProductID,
        b.Name,
        SUM(Quantity) TONKHO
    FROM Production.ProductInventory a LEFT JOIN Production.Product b
        ON a.ProductID = b.ProductID
    GROUP by a.ProductID,b.Name 
)
SELECT *
FROM tonkho_sp
WHERE TONKHO = 
    (   
        SELECT MIN(TONKHO) FROM tonkho_sp
    )
ORDER BY ProductID

--2.2
SELECT 
    d.Name CategoryName,
    SUM(a.Quantity * b.ListPrice) GIATRITONKHO
FROM Production.ProductInventory a 
LEFT JOIN Production.Product b
    ON a.ProductID = b.ProductID
LEFT JOIN Production.ProductSubcategory c
    ON b.ProductSubcategoryID = c.ProductSubcategoryID
LEFT JOIN Production.ProductCategory d
    ON c.ProductCategoryID = d.ProductCategoryID
GROUP by d.Name
ORDER BY GIATRITONKHO DESC

--2.3
SELECT 
    a.LocationID,
    b.Name TENKHO,
    SUM(Quantity) TONKHO
FROM Production.ProductInventory a LEFT JOIN Production.Location b
    ON a.LocationID = b.LocationID
GROUP by a.LocationID, b.Name
ORDER BY a.LocationID


-- Case Study 3: Phân Tích Vận Chuyển Hàng Hóa
-- Bối cảnh: Công ty muốn phân tích hiệu quả vận chuyển, thời gian giao hàng trung bình và các hãng vận chuyển phổ biến.
-- Câu hỏi phân tích:
-- 1.	Tính thời gian giao hàng trung bình cho từng hãng vận chuyển.
-- 2.	Tìm hãng vận chuyển có số lượng đơn hàng lớn nhất.
-- 3.	Xác định khách hàng có thời gian giao hàng lâu nhất.
-- Gợi ý:
-- •	Dữ liệu cần thiết: Sử dụng bảng Purchasing.ShipMethod, Sales.SalesOrderHeader, và Sales.Customer.

--3.1
SELECT 
    a.ShipMethodID,
    a.Name,
    AVG(DATEDIFF(DAY,OrderDate,ShipDate)) as TIMESDELIVERY
FROM Purchasing.ShipMethod a 
LEFT JOIN Sales.SalesOrderHeader b 
    ON a.ShipMethodID = b.ShipMethodID
GROUP BY a.ShipMethodID,a.Name
ORDER BY a.ShipMethodID

--3.2
WITH max_order AS
(
    SELECT 
        a.ShipMethodID,
        a.Name,
        COUNT(SalesOrderID) SLOrders,
        ROW_NUMBER() OVER(ORDER BY COUNT(SalesOrderID) DESC) RN
    FROM Purchasing.ShipMethod a 
    LEFT JOIN Sales.SalesOrderHeader b 
        ON a.ShipMethodID = b.ShipMethodID
    GROUP BY a.ShipMethodID,a.Name
) 
SELECT 
    ShipMethodID,
    Name,
    SLOrders
FROM max_order
WHERE RN = 1

--3.3
WITH times AS
(
    SELECT 
        b.SalesOrderID,
        b.OrderDate,
        b.ShipDate,
        a.Name DONVIVANCHUYEN,
        DATEDIFF(DAY,OrderDate,ShipDate) as TIMESDELIVERY,
        c.CustomerID
    FROM Purchasing.ShipMethod a 
    LEFT JOIN Sales.SalesOrderHeader b 
        ON a.ShipMethodID = b.ShipMethodID
    LEFT JOIN Sales.Customer c
        ON b.CustomerID = c.CustomerID
    GROUP BY 
        b.SalesOrderID,
        b.OrderDate,
        b.ShipDate,
        a.Name,
        c.CustomerID
) SELECT * FROM times WHERE TIMESDELIVERY = (SELECT MAX(TIMESDELIVERY) FROM times)


-- Case Study 4: Phân Tích Sản Xuất
-- Bối cảnh: Công ty muốn phân tích năng lực sản xuất, bao gồm số lượng sản phẩm được sản xuất, nguyên liệu cần thiết và hiệu suất sản xuất của từng công đoạn.
-- Câu hỏi phân tích:
-- 1.	Tính tổng số lượng sản phẩm được sản xuất theo từng danh mục.
-- 2.	Phân tích các nguyên liệu cần thiết để sản xuất một sản phẩm cụ thể.
-- 3.	Tính thời gian sản xuất trung bình của từng sản phẩm.
-- Gợi ý:
-- •	Dữ liệu cần thiết: Sử dụng bảng Production.WorkOrder, Production.Product, Production.ProductCategory, và Production.BillOfMaterials.

--4.1
SELECT 
    d.Name CategoryName,
    SUM(a.OrderQty) SLSX
FROM Production.WorkOrder a 
LEFT JOIN Production.Product b
    ON a.ProductID = b.ProductID
LEFT JOIN Production.ProductSubcategory c
    ON b.ProductSubcategoryID = c.ProductSubcategoryID
LEFT JOIN Production.ProductCategory d
    ON c.ProductCategoryID = d.ProductCategoryID
GROUP by d.Name;

--4.2


--4.3
SELECT 
    a.ProductID,
    b.Name,
    DATEDIFF(DAY,a.StartDate,a.EndDate) TimesManufacture
FROM Production.WorkOrder a 
LEFT JOIN Production.Product b
    ON a.ProductID = b.ProductID
GROUP by a.ProductID, b.Name, DATEDIFF(DAY,a.StartDate,a.EndDate)


SELECT * FROM Production.WorkOrder;
SELECT * FROM Production.Product;
SELECT * FROM Production.ProductCategory;
SELECT * FROM Production.BillOfMaterials;