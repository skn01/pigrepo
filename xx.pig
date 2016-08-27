a = LOAD 'TRIP.TRIPDEALINFO' USING org.apache.hive.hcatalog.pig.HCatLoader();
b = LOAD 'IHUBI.ICIS_SYSTEMLINKSALL' USING org.apache.hive.hcatalog.pig.HCatLoader();
c = join a by systemid,prtn_num, b by customerid,partn_num;
/* c = join a on systemid,prtn_num, b by customerid,partn_num; */
d = filter c by b.systemcode = 'DEALTRACK'



e = LOAD 'IHUB.IHB_DATA_SRC' USING org.apache.hive.hcatalog.pig.HCatLoader();
f = filter e by e.ihb_data_src_nm = 'TRIP'; 
g = filter f by f.ihb_load_freq_ty_cd = 'D';
