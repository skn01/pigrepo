!/bin/bash

read -p "Enter the source database server name : " source_db_server;
read -p "Enter the source database in Mysql database : " db_name;
read -p "Enter the source database port : " db_port;
read -p "Enter the ource db user name  : " db_user;
read -p "Enter the table name : " table_name;
read -p "Enter the target director in HDFS : " hdfs_target_dir;


#To bring the information_schema.table and information_schema.columns data directly to Hive for metadata validation

/usr/bin/hive << EOF
use metadata;
drop table mysql_info_schema_tables;
drop table mysql_info_schema_columns;
EOF

/usr/bin/sqoop import --connect jdbc:mysql://${source_db_server}:${db_port}/information_schema \
--username root -P --table tables -m 1 \
--driver com.mysql.jdbc.Driver --class-name tables --hive-import --hive-table metadata.mysql_info_schema_tables --verbose

/usr/bin/sqoop import --connect jdbc:mysql://${source_db_server}:${db_port}/information_schema \
--username root -P --table columns -m 1 \
--driver com.mysql.jdbc.Driver --class-name columns --hive-import --hive-table metadata.mysql_info_schema_columns --verbose

#sqoop import --connect jdbc:mysql://192.168.1.75:3306/information_schema --username root -P --table tables -m 1 --driver com.mysql.jdbc.Driver --class-name tabless --hive-import --hive-table metadata.tables --verbose

#
# The statement below is for full mport of data from source to target
#

/usr/bin/sqoop import --connect jdbc:mysql://${source_db_server}:${db_port}/${db_name} \
--username ${db_user} -P --table ${table_name} -m 1 --driver com.mysql.jdbc.Driver \
--class-name ${table_name} --target-dir ${hdfs_target_dir}/${table_name} --append --bindir .

#
# The statement below is for incremental data movement
#
#echo "sqoop import --connect jdbc:mysql://${source_db_server}:${db_port}/${db_name} --username ${db_user} -P --table ${table_name} -m 1 --driver com.mysql.jdbc.Driver --class-name ${table_name} --target-dir ${hdfs_target_dir}/${table_name} --incremental append --check-column empid --last-value 3 --bindir ."

#sqoop import --connect jdbc:mysql://${source_db_server}:${db_port}/${db_name} --username ${db_user} -P --table ${table_name} -m 1 --driver com.mysql.jdbc.Driver --class-name ${table_name} --target-dir ${hdfs_target_dir}/${table_name} --incremental append --check-column empid --last-value 3 --bindir .


echo " "
echo "Listing files in HDFS target directory "${hdfs_target_dir}
echo " "
hdfs dfs -ls ${hdfs_target_dir}/${table_name}

#read -p "Enter the datafile to load to Hive : " data_file;
#
#hive << EOF
#use wf;
#load data inpath '${data_file}' into table ${table_name};
#EOF
#
