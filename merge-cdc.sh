# For full import of table to HDFS
/usr/bin/sqoop import --connect jdbc:mysql://192.168.1.75:3306/test --username root -P --table employee -m 1 --driver com.mysql.jdbc.Driver --class-name employee --target-dir /usr/root/employee --append  --bindir .

#for incremental import from source to HDFS
/usr/bin/sqoop import --connect jdbc:mysql://192.168.1.75:3306/test --username root -P --table employee -m 1 --driver com.mysql.jdbc.Driver --class-name employee --target-dir /usr/root/employee_incremental --incremental append --check-column modified_date --last-value {last_import_date} --bindir .

# Create a necessary table in HIVE to hold the base line data

hive> create external table employee_temp (empid int, empname string, role string, national_award string, created_data timestamp, modified_date timestamp) row format delimited fields terminated by ',' stored as textfile location '/usr/root/employee';

# hive> create table employee_base (empid int, empname string, role string, national_award string, created_data date, modified_date date) row format delimited fields terminated by ',' stored as ORC;

hive> insert overwrite table employee_base select * from employee_temp;

#for incremental import from source based on query
/usr/bin/sqoop import --connect jdbc:mysql://192.168.1.75:3306/test --username root -P --table employee -m 1 --driver com.mysql.jdbc.Driver --class-name employee --target-dir /usr/root/employee_incremental -m 1 --query 'select * from employee_table where modified_date > {last_import_date} and $CONDITIONS' 

# create an external table to store incremental data
#hive> create external table employee_incremental (empid int, empname string, role string, national_award string, created_data date, modified_date date) row format delimited fields terminated by ',' stored as textfile location '/usr/root/employee_incremental';

# Create the reconciled view of the table
#hive> create view employee_reconciled as select t1.* from (select * from employee_base UNION ALL select * from employee_incremental) t1 JOIN (select t.empid, max(t.modified_date) max_modified from (select * from employee_base UNION ALL select * from employee_incremental) t group by t.empid) t2 ON t1.empid = t2.empid and t1.modified_date = t2.max_modified;

hibe> drop table employee;
hive> create table employee as select * from employee_reconciled;

hdfs dfs -rm -r /usr/root/employee_incremental/*

hive> drop table employee_base;
hive> create table employee_base (empid int, empname string, role string, national_award string, created_data date, modified_date date) row format delimited fields terminated by ',' stored as ORC;
hive> insert overwrite table employee_temp select * from employee;
hive> insert overwrite table employee_base select * from employee;


steps:
------
incremental import
(select from reconciled view)
drop table employee:
create table employee from reconciled view;
overwrite employee_base from employee
remove /usr/root/employee_incremental/*

