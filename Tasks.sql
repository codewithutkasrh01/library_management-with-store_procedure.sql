select*from books
select*from branch
select*from employees
select*from issued_status
select*from members
select*from return_status
/* ===============================
   TASK 1: Create a New Book Record
   =============================== */
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

/* ===============================
   TASK 2: Update an Existing Member's Address
   =============================== */
UPDATE members
SET member_address = '125 Oak st'
WHERE member_id = 'C103';

/* ===============================
   TASK 3: Delete Record from Issued Status
   =============================== */
DELETE FROM issued_status
WHERE issued_id = 'IS121';

/* ===============================
   TASK 4: Retrieve All Books Issued by Employee E101
   =============================== */
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101';

/* ===============================
   TASK 5: List Members Who Have Issued More Than One Book
   =============================== */
SELECT
    issued_emp_id,
    COUNT(*) AS total_books_issued
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;

/* ===============================
   TASK 6: Create Book Issued Count Table
   =============================== */
CREATE TABLE book_issued_cnt AS
SELECT  
    b.isbn, 
    b.book_title, 
    COUNT(ist.issued_id) AS issue_count
FROM issued_status AS ist
JOIN books AS b
    ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

SELECT * FROM book_issued_cnt;

/* ===============================
   TASK 7: Retrieve All Books in Classic Category
   =============================== */
SELECT * 
FROM books
WHERE category = 'Classic';

/* ===============================
   TASK 8: Find Total Rental Income by Category
   =============================== */
SELECT 
    b.category,
    SUM(b.rental_price) AS total_rental_income,
    COUNT(*) AS total_books
FROM issued_status AS ist
JOIN books AS b
    ON b.isbn = ist.issued_book_isbn
GROUP BY 1;

/* ===============================
   TASK 9: List Members Registered in Last 180 Days
   =============================== */
SELECT * 
FROM members 
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

/* ===============================
   TASK 10: Employees with Branch Manager and Branch Details
   =============================== */
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name AS manager
FROM employees AS e1
JOIN branch AS b
    ON e1.branch_id = b.branch_id
JOIN employees AS e2 
    ON e2.emp_id = b.manager_id;

/* ===============================
   TASK 11: Create Expensive Books Table
   =============================== */
CREATE TABLE expensive_books AS
SELECT * 
FROM books
WHERE rental_price > 7.00;

/* ===============================
   TASK 12: Retrieve List of Books Not Yet Returned
   =============================== */
SELECT * FROM issued_status;
SELECT * FROM return_status;

SELECT * 
FROM issued_status AS ist
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

/* ===============================
   TASK 13: Identify Members with Overdue Books (>30 days)
   =============================== */
SELECT
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    rs.return_date,
    CURRENT_DATE - ist.issued_date AS over_dues
FROM issued_status AS ist
JOIN members AS m
    ON m.member_id = ist.issued_member_id
JOIN books AS bk
    ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND CURRENT_DATE - ist.issued_date > 30
ORDER BY 1;

/* ===============================
   TASK 14: Stored Procedure to Update Book Status on Return
   =============================== */
ALTER TABLE return_status
ADD COLUMN book_quality VARCHAR(115);

CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id VARCHAR(10),
    p_issued_id VARCHAR(10),
    p_book_quality VARCHAR(115)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
BEGIN
    -- Insert return record
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    -- Get book details
    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Update book status
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Show message
    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
END;
$$;

-- Test procedure
CALL add_return_records('RS139','IS135','BAD');
CALL add_return_records('RS148','IS140','GOOD');

/* ===============================
   TASK 15: Branch Performance Report
   =============================== */
CREATE TABLE branch_reports AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS no_of_books_issued,
    COUNT(rs.return_id) AS no_of_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS e 
    ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
    ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
JOIN books AS bk
    ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

SELECT * FROM branch_reports;

/* ===============================
   TASK 16: Active Members in Last 2 Months
   =============================== */
CREATE TABLE active_members AS
SELECT 
    ist.*,
    m.member_name
FROM issued_status AS ist
JOIN members AS m
    ON m.member_id = ist.issued_member_id
WHERE issued_date >= CURRENT_DATE - INTERVAL '24 months';

SELECT * FROM active_members;

/* ===============================
   TASK 17: Employees with Most Book Issues Processed
   =============================== */
SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) AS number_of_books_processed
FROM employees AS e
JOIN issued_status AS ist
    ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
    ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id, b.manager_id, b.branch_name;

/* ===============================
   TASK 18: Stored Procedure to Issue Book
   =============================== */
CREATE OR REPLACE PROCEDURE issue_book(
    p_issued_id VARCHAR(10), 
    p_issued_member_id VARCHAR(30), 
    p_issued_book_isbn VARCHAR(30), 
    p_issued_emp_id VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    -- Check if book is available
    SELECT status 
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        -- Insert issue record
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        -- Update book status
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;
    ELSE
        RAISE NOTICE 'Sorry, the book is unavailable: %', p_issued_book_isbn;
    END IF;
END;
$$;

-- Testing the procedure
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');









