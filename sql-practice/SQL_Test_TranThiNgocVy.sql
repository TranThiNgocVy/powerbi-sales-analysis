--CASE STUDY 1 - CÂU HỎI 1: Tính tổng doanh thu (TotalDue) của từng khu vực (Territory) trong năm 2013.
SELECT 
    a.TerritoryID,
    b.Name,
    SUM(a.TotalDue) TotalSales
FROM Sales.SalesOrderHeader a
LEFT JOIN Sales.SalesTerritory b
    ON a.TerritoryID = b.TerritoryID
WHERE YEAR(OrderDate) = 2013
GROUP BY a.TerritoryID, b.Name
ORDER BY TotalSales DESC;

--CASE STUDY 1 - CÂU HỎI 2: Tìm 5 sản phẩm bán chạy nhất trong năm 2013 (dựa trên doanh thu).
SELECT TOP 5 
    a.ProductID,
    c.Name,
    SUM(a.LineTotal) as TotalSales
FROM Sales.SalesOrderDetail a 
LEFT JOIN Sales.SalesOrderHeader b 
    ON a.SalesOrderID = b.SalesOrderID
LEFT JOIN Production.Product c 
    ON a.ProductID = c.ProductID
WHERE YEAR(b.OrderDate) = 2013
GROUP BY a.ProductID, c.Name
ORDER BY TotalSales DESC;


--CASE STUDY 1 - CÂU HỎI 3: Xác định khách hàng nào có tổng chi tiêu cao nhất trong từng tháng của năm 2013.
WITH ctmers_month_sales AS
(
    SELECT 
        a.OrderDate,
        MONTH(a.OrderDate) OrderMonth,
        a.CustomerID,
        CONCAT_WS(' ',FirstName,MiddleName,LastName) FullName,
        SUM(a.TotalDue) as TotalSales,
        ROW_NUMBER() OVER(PARTITION BY MONTH(a.OrderDate) ORDER BY SUM(a.TotalDue) DESC) RN
    FROM Sales.SalesOrderHeader a
    LEFT JOIN Sales.Customer b 
        ON a.CustomerID = b.CustomerID
    LEFT JOIN Person.Person c
        ON b.PersonID = c.BusinessEntityID
    WHERE YEAR(a.OrderDate) = 2013
    GROUP BY 
        a.OrderDate,
        MONTH(a.OrderDate), 
        a.CustomerID,
        CONCAT_WS(' ',FirstName,MiddleName,LastName)
)
SELECT  
    OrderMonth,
    CustomerID,
    FullName,
    TotalSales
FROM ctmers_month_sales
WHERE RN = 1;


--CASE STUDY 1 - CÂU HỎI 4: Tìm tháng nào có doanh thu cao nhất và thấp nhất.
WITH totalsales_year_month AS
(
    SELECT 
        YEAR(OrderDate) OrderYear,
        MONTH(OrderDate) OrderMonth,
        SUM(TotalDue) as TotalSales,
        RANK() OVER(ORDER BY SUM(TotalDue) DESC) rankmax,
        RANK() OVER(ORDER BY SUM(TotalDue)) rankmin
    FROM Sales.SalesOrderHeader
    GROUP BY 
        YEAR(OrderDate),
        MONTH(OrderDate)
)
SELECT 
    OrderYear,
    OrderMonth,
    TotalSales,
    CASE  
        WHEN rankmax = 1 THEN 'DOANH THU CAO NHAT'
        WHEN rankmin = 1 THEN 'DOANH THU THAP  NHAT'
    END as Status
FROM totalsales_year_month
WHERE rankmax = 1 OR rankmin = 1;

--CASE STUDY 1 - CÂU HỎI 5:
-- Tính tỷ trọng doanh thu mà mỗi nhân viên bán hàng (SalesPerson) đóng góp trong năm 2013.
-- Xếp hạng nhân viên theo doanh thu (từ cao xuống thấp).
WITH tts_salesperson AS
(
    SELECT 
        a.SalesPersonID,
        CONCAT_WS(' ',FirstName,MiddleName,LastName) FullName,
        SUM(a.TotalDue) as TotalSales,
        RANK() OVER(ORDER BY SUM(a.TotalDue) DESC) RANK
    FROM Sales.SalesOrderHeader a
    LEFT JOIN Sales.Customer b 
        ON a.CustomerID = b.CustomerID
    LEFT JOIN Person.Person c
        ON a.SalesPersonID = c.BusinessEntityID
    WHERE YEAR(a.OrderDate) = 2013 AND a.SalesPersonID is not null
    GROUP BY 
        a.SalesPersonID,
        CONCAT_WS(' ',FirstName,MiddleName,LastName)
)
SELECT  
    SalesPersonID,
    FullName,
    TotalSales,
    RANK,
    TotalSales * 1.0 / SUM(TotalSales) OVER() * 100 TYTRONG
FROM tts_salesperson;




--CASE STUDY 2 - CÂU HỎI 1:
-- Tính tổng số lượng nhân viên hiện tại trong từng phòng ban.
-- Xác định phòng ban nào có số lượng nhân viên ít nhất.
WITH slnv AS
(
    SELECT 
        c.Name DepartmentName,
        COUNT(DISTINCT a.BusinessEntityID) SLNV
    FROM HumanResources.Employee a
    LEFT JOIN HumanResources.EmployeeDepartmentHistory b
        ON a.BusinessEntityID = b.BusinessEntityID
    LEFT JOIN HumanResources.Department c
        ON b.DepartmentID = c.DepartmentID
    WHERE b.EndDate is NULL
    GROUP BY c.Name 
)
SELECT 
    DepartmentName,
    SLNV,
    CASE WHEN SLNV = (SELECT MIN(SLNV) FROM slnv) THEN 'PHONG BAN CO SLNV IT NHAT' END AS Status
FROM slnv
ORDER BY SLNV;


--CASE STUDY 2 - CÂU HỎI 2:
-- Liệt kê danh sách 5 nhân viên có thâm niên cao nhất trong từng phòng ban, bao gồm: Tên, Chức danh công việc, Phòng ban, Thâm niên (năm).
WITH thamnien AS
(
    SELECT 
        CONCAT_WS(' ',FirstName,MiddleName,LastName) FullName,
        a.JobTitle,
        c.Name DepartmentName,
        DATEDIFF(YEAR,HireDate,'2015-12-31') THAMNIEN,   
        ROW_NUMBER() OVER(PARTITION BY c.Name ORDER BY DATEDIFF(YEAR,HireDate,'2015-12-31') DESC) RN
    FROM HumanResources.Employee a
    LEFT JOIN HumanResources.EmployeeDepartmentHistory b
        ON a.BusinessEntityID = b.BusinessEntityID
    LEFT JOIN HumanResources.Department c
        ON b.DepartmentID = c.DepartmentID
    LEFT JOIN Person.Person d 
        ON a.BusinessEntityID = d.BusinessEntityID
    WHERE b.EndDate is NULL
)
SELECT  
    FullName,
    JobTitle,
    DepartmentName,
    THAMNIEN
FROM thamnien
WHERE RN <=5;

-- Tạo 1 hàm (Function) có tên fn_EmployeeWorkAge nhận vào BusinessEntityID của nhân viên, và trả về số năm làm việc (tính từ ngày vào làm đến 2015).
-- CREATE FUNCTION dbo.fn_EmployeeWorkAge
-- (
--     @BusinessEntityID INT
-- )
-- RETURNS INT
-- AS 
-- BEGIN
--     DECLARE @sonamlamviec INT
--     SELECT @sonamlamviec = DATEDIFF(YEAR,StartDate,'2015-12-31')
--     FROM HumanResources.EmployeeDepartmentHistory
--     WHERE BusinessEntityID = @BusinessEntityID AND EndDate is null
--     return @sonamlamviec
-- END;

SELECT dbo.fn_EmployeeWorkAge(19) AS SONAMLAMVIEC;


--CASE STUDY 2 - CÂU HỎI 3: Tìm chức danh có nhiều nhân viên nhất và ít nhân viên nhất
WITH slnv_chucdanh AS
(
    SELECT 
        a.Jobtitle,
        COUNT(DISTINCT a.BusinessEntityID) SLNV,
        RANK() OVER(ORDER BY COUNT(DISTINCT a.BusinessEntityID) DESC) rankmax,
        RANK() OVER(ORDER BY COUNT(DISTINCT a.BusinessEntityID)) rankmin
    FROM HumanResources.Employee a
    LEFT JOIN HumanResources.EmployeeDepartmentHistory b
        ON a.BusinessEntityID = b.BusinessEntityID
    WHERE b.EndDate is NULL
    GROUP BY a.Jobtitle
)
SELECT  
    Jobtitle,
    SLNV,
    CASE 
        WHEN rankmax = 1THEN 'SLNV NHIEU NHAT'
        WHEN rankmin = 1 THEN 'SLNV IT NHAT'
    END STATUS
FROM slnv_chucdanh
WHERE rankmax = 1 OR rankmin = 1;
