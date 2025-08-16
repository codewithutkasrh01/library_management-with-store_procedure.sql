-----Library_Management_system
----creating branch table
DROP TABLE IF EXISTS branch;
create table branch
(
  branch_id varchar(10) primary key,
  manager_id varchar(10),
  branch_address varchar(55),
  contact_no varchar(10)
);

alter table branch
alter column contact_no type varchar(20);



DROP TABLE IF EXISTS employees;
create table employees
(
  emp_id varchar(10) primary key,
  emp_name varchar(25),
  position varchar(20),
  salary int,
  branch_id varchar (10),
  FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);

DROP TABLE IF EXISTS books;
(
create table books
	isbn varchar(20) primary key,
	book_title varchar(75),
	category varchar(15),
	rental_price float,
	status varchar(10),
	author varchar(25),
	publisher varchar (55)
);
alter table books 
alter column category type varchar(20)

DROP TABLE IF EXISTS members;
create table members

(
	member_id varchar(15) primary key,
	member_name varchar(15),
	member_address varchar(15),
	reg_date date
);

DROP TABLE IF EXISTS issued_status;
create table issued_status
(
	issued_id varchar(10) primary key,
	issued_member_id varchar(10),
	issued_book_name varchar(75),
	issued_date	date,
	issued_book_isbn varchar(25),
	issued_emp_id varchar(15),
	FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);
	

DROP TABLE IF EXISTS return_status;
create table return_status
(
	return_id varchar(10) primary key,
	issued_id varchar(30),
	return_book_name varchar(75),
	return_date date,
	return_book_isbn varchar(50),
	foreign key (return_book_isbn) references books (isbn)
	
);


----inserting the value in the table





