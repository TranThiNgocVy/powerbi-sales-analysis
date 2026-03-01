--Bài 1: Xếp thứ tự đơn hàng theo ngày đặt hàng (ROW_NUMBER)
--Yêu cầu: Lấy danh sách đơn hàng cùng thứ tự của chúng dựa trên ngày đặt hàng (OrderDate) cho từng khách hàng (CustomerID).
SELECT 
    CustomerID,
    SalesOrderID,
    OrderDate,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS THUTUDONHANG
FROM Sales.SalesOrderHeader;

-------------------------------------------------------------------------
--MORE: TÌM NHỮNG KHÁCH HÀNG CÓ 2 ĐƠN HÀNG LIÊN TIẾP
WITH rn_order AS
(
    SELECT 
        SalesOrderID,
        OrderDate,
        CustomerID,
        ROW_NUMBER() OVER (ORDER BY OrderDate) AS RN
    FROM Sales.SalesOrderHeader
), lag_rn AS
(
    SELECT
        SalesOrderID,
        OrderDate,
        CustomerID,
        RN,
        LAG(RN) OVER(PARTITION BY CustomerID Order by RN) as lag_order
    FROM rn_order
) SELECT * FROM lag_rn WHERE RN - lag_order = 1

------------------------------------------------------------------------
--Bài 2: Xếp hạng khách hàng theo tổng doanh thu (RANK)
--Yêu cầu: Xếp hạng các khách hàng dựa trên tổng doanh thu (SubTotal) của họ, theo thứ tự từ cao đến thấp.
SELECT 
    b.CustomerID,
    SUM(a.TotalDue) AS DoanhThu,
    RANK() OVER(ORDER BY SUM(a.TotalDue) DESC) AS RANK
FROM Sales.Customer b 
left JOIN Sales.SalesOrderHeader a ON a.CustomerID = b.CustomerID
GROUP BY b.CustomerID;

--Bài 3: Tính doanh thu lũy kế theo ngày (SUM với OVER)
--Yêu cầu: Tính tổng doanh thu từng ngày và doanh thu lũy kế theo thứ tự thời gian.
WITH totalsales AS
(
    SELECT 
        OrderDate,
        SUM(TotalDue) AS TotalSalesbyDAY
    FROM Sales.SalesOrderHeader
    GROUP BY OrderDate
)
SELECT
    OrderDate,
    TotalSalesbyDAY,
    SUM(TotalSalesbyDAY) OVER (ORDER BY OrderDate) AS TotalSalesLUYKE
FROM totalsales;
----------------------------------------------------------------------------------
--MORE:
SELECT
    OrderDate,
    SUM(SUM(TotalDue)) OVER (ORDER BY OrderDate) AccumTotalSales
FROM Sales.SalesOrderHeader
GROUP BY OrderDate;
SELECT
    OrderDate,
    SUM(COUNT(SalesOrderID)) OVER (ORDER BY OrderDate) AccumCountOrder
FROM Sales.SalesOrderHeader
GROUP BY OrderDate
----------------------------------------------------------------------------
--Bài 4: Tìm giá trị đơn hàng trước và sau (LAG, LEAD)
--Yêu cầu: Lấy danh sách các đơn hàng, tính doanh thu của đơn hàng trước đó và sau đó so với đơn hàng hiện tại.
SELECT
    SalesOrderID,
    OrderDate,
    TotalDue AS HIENTAI,

    LAG(TotalDue) OVER(ORDER BY OrderDate) AS TRUOC,
    LEAD(TotalDue) OVER(ORDER BY OrderDate) AS SAU 

FROM Sales.SalesOrderHeader;

--Bài 5: Phân nhóm khách hàng thành 4 nhóm dựa trên doanh thu (NTILE)
--Yêu cầu: Chia khách hàng thành 4 nhóm (quartiles) dựa trên tổng doanh thu (SubTotal), nhóm 1 là những khách hàng có doanh thu cao nhất.
WITH totalsales AS
(
    SELECT 
        CustomerID,
        SUM(TotalDue) AS ToatalSales
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT 
    a.CustomerID,
    b.ToatalSales,
    NTILE(4) OVER(ORDER BY b.ToatalSales DESC) as NHOM
FROM  Sales.Customer a LEFT JOIN totalsales b ON a.CustomerID = b.CustomerID;

--Bài tập 6: Tìm sản phẩm bán chạy nhất trong từng nhóm sản phẩm (ROW_NUMBER)
--Yêu cầu: Trong mỗi nhóm sản phẩm (ProductCategoryID), tìm sản phẩm có số lượng bán nhiều nhất. 
--Sử dụng hàm ROW_NUMBER() để xếp hạng các sản phẩm theo số lượng bán trong từng nhóm, chỉ hiển thị sản phẩm đứng đầu mỗi nhóm.
WITH Result AS
(
    SELECT
        ProductCategory.Name AS ProductCategoryName, 
        Product.Name AS ProductName,
        SUM(OrderQty) Total_Quantity,
        ROW_NUMBER() OVER (PARTITION BY ProductCategory.Name ORDER BY SUM(OrderQty) DESC) RN
    FROM Sales.SalesOrderDetail SOD
    LEFT JOIN Production.Product
        ON SOD.ProductID = Product.ProductID
    LEFT JOIN Production.ProductSubcategory
        ON Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory
        ON ProductSubcategory.ProductCategoryID = ProductCategory.ProductCategoryID
    GROUP BY 
        ProductCategory.Name,
        Product.Name
)
SELECT * 
FROM Result
WHERE RN = 1;


--Bài tập 7: Tính tổng số ngày và tuần từ khi đơn hàng được tạo tới khi đơn hàng được giao
--Trong bảng Sales.SalesOrderHeader, tính số ngày và số tuần kể từ ngày đơn hàng (OrderDate) đến thời điểm đơn hàng được giao (ShipDate)
SELECT 
    SalesOrderID,
    OrderDate,
    ShipDate,
    DATEDIFF(DAY, OrderDate, ShipDate) AS NGAY,
    DATEDIFF(WEEK, OrderDate, ShipDate) AS TUAN
FROM Sales.SalesOrderHeader
WHERE ShipDate IS NOT NULL


--Bài tập 8: Tìm đơn hàng có ngày tạo là ngày cuối cùng của tháng
--Lọc ra các đơn hàng trong bảng Sales.SalesOrderHeader có ngày đơn hàng (OrderDate) rơi vào ngày cuối cùng của tháng.
SELECT 
    SalesOrderID,
    OrderDate
FROM Sales.SalesOrderHeader
WHERE CAST(OrderDate AS DATE) = EOMONTH(OrderDate);

--Bài tập 9: Tìm ngày có tổng doanh thu cao nhất trong từng quý của năm 2013
--Từ bảng Sales.SalesOrderHeader, tìm ngày có tổng doanh thu (TotalDue) cao nhất trong từng quý của năm 2013.
WITH DailyRevenue AS (
    SELECT 
        CAST(OrderDate AS DATE) AS OrderDate,
        DATEPART(QUARTER, OrderDate) AS Quy,
        SUM(TotalDue) AS DoanhThuNgay
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2013
    GROUP BY 
        CAST(OrderDate AS DATE),
        DATEPART(QUARTER, OrderDate)
),
RankedRevenue AS (
    SELECT 
        OrderDate,
        Quy,
        DoanhThuNgay,
        ROW_NUMBER() OVER (
            PARTITION BY Quy
            ORDER BY DoanhThuNgay DESC
        ) AS RN
    FROM DailyRevenue
)
SELECT 
    Quy,
    OrderDate,
    DoanhThuNgay
FROM RankedRevenue
WHERE RN = 1
ORDER BY Quy;

----------------------------------------------------------------------------
WITH customer_sales AS
(
    SELECT
        CustomerID,
        SUM(TotalDue) TotalSales
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
, M_point AS
(
    SELECT
        CustomerID,
        TotalSales,
        NTILE(5) OVER(ORDER BY TotalSales) M_point
    FROM customer_sales
)
-- Frequency
, customer_trans_count AS
(
    SELECT
        CustomerID,
        COUNT(SalesOrderID) OrderCount
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
, F_point AS
(
    SELECT
        CustomerID,
        OrderCount,
        NTILE(5) OVER(ORDER BY OrderCount) F_Point
    FROM customer_trans_count
)
SELECT
    M_point.CustomerID,
    M_point.M_point,
    F_Point.F_Point
FROM M_point
LEFT JOIN F_point
    ON M_point.CustomerID = F_Point.CustomerID