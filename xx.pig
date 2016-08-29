a = LOAD '<database1>.<tablename1>' USING org.apache.hive.hcatalog.pig.HCatLoader();
b = LOAD '<database2>.<tablename2>' USING org.apache.hive.hcatalog.pig.HCatLoader();
c = join a by systemid,prtn_num, b by customerid,partn_num;
/* c = join a on systemid,prtn_num, b by customerid,partn_num; */
d = filter c by b.systemcode = 'SALESDEAL'



e = LOAD '<database3>.<tablename3>' USING org.apache.hive.hcatalog.pig.HCatLoader();
f = filter e by e.ihb_data_src_nm = 'TRIP'; 
g = filter f by f.ihb_load_freq_ty_cd = 'D';
