a = LOAD 'wf.employee1' USING org.apache.hive.hcatalog.pig.HCatLoader();
b = LOAD 'wf.customers' USING org.apache.hive.hcatalog.pig.HCatLoader();
c= join a by empid , b by customerid;
d = foreach c generate null,null,$0, $1, $6, $7, CONCAT($4,'--',$5), ToString(CurrentTime(),'yyyy-MM-dd'),CONCAT('','USD',''), ($3 is null ? 'No Value' : $3 );
dump d;
/*store d into '/usr/root/emp1';*/
