#!/bin/bash

#clear screen
read -p "Enter the source database server name : " source_db_server;
read -p "Enter the source database name (SID) : " db_name;
read -p "Enter the source database port : " db_port;
read -p "Enter the source db user name  : " db_user;
read -p "Enter the table name : " table_name;
read -p "Enter the column of the table to split worker : " column_name;
read -p "Enter the target directory in HDFS : " hdfs_target_dir;

/usr/bin/hive << EOF
use metadata;
insert overwrite table orcl_info_schema_tables select * from orcl_info_schema_tables where object_name != '${table_name}';
insert overwrite table orcl_info_schema_columns select * from orcl_info_schema_columns where table_name != '${table_name}';
EOF

#echo "/usr/bin/sqoop import --connect jdbc:oracle:thin:system/system@${source_db_server}:${db_port}:${db_name} --username ${db_user} -P --table SYS.USER_OBJECTS -m 1 --class-name user_objects --hive-import --hive-table metadata.orcl_info_schema_tables"

/usr/bin/sqoop import --connect jdbc:oracle:thin:system/system@${source_db_server}:${db_port}:${db_name} \
--username ${db_user} -P \
--query "select OBJECT_NAME, SUBOBJECT_NAME, OBJECT_ID, DATA_OBJECT_ID, OBJECT_TYPE, CREATED, \
LAST_DDL_TIME, TIMESTAMP, STATUS, TEMPORARY, GENERATED, SECONDARY, NAMESPACE, EDITION_NAME \
from SYS.USER_OBJECTS where \$CONDITIONS and object_name = '${table_name}'" -m 1 \
--class-name user_objects --hive-import --hive-table metadata.orcl_info_schema_tables --append --target-dir /Pilot/orcl_info_schema_tables

/usr/bin/sqoop import --connect jdbc:oracle:thin:system/system@${source_db_server}:${db_port}:${db_name} \
--username ${db_user} -P \
--query "select TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER, DATA_LENGTH, \
DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID, DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, \
LOW_VALUE, HIGH_VALUE, DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE, CHARACTER_SET_NAME, \
CHAR_COL_DECL_LENGTH, GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED, V80_FMT_IMAGE, DATA_UPGRADED, \
HISTOGRAM from SYS.USER_TAB_COLUMNS where \$CONDITIONS and table_name = '${table_name}'" -m 1 \
--map-column-hive LOW_VALUE=binary,HIGH_VALUE=binary \
--class-name user_objects --hive-import --hive-table metadata.orcl_info_schema_columns --append --target-dir /Pilot/orcl_info_schema_columns

## For Oracle source databases....

/usr/bin/sqoop import --connect jdbc:oracle:thin:system/system@${source_db_server}:${db_port}:${db_name} \
--username ${db_user} -P --table ${table_name} --split-by ${column_name} \
--class-name ${table_name} --target-dir ${hdfs_target_dir}/${table_name} --append --bindir .

/usr/bin/hive << EOF1
use metadata;
insert into table metadata.orcl_metadata_hist
select a.object_name, b.column_name, b.column_id, a.created, a.last_ddl_time, from_unixtime(unix_timestamp())
from metadata.orcl_info_schema_tables a, metadata.orcl_info_schema_columns b
where a.object_name = b.table_name
and a.object_name = '${table_name}';
EOF1
