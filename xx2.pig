a = LOAD '/usr/root/customers' USING PigStorage (',') AS (customerid:int,firstname:chararray,lastname:chararray);
b = filter a by customerid == 1;
c = foreach b generate b.customerid, b.lastname, b.firstname;

a1 = LOAD 'wf.employee1' USING org.apache.hive.hcatalog.pig.HCatLoader();
b1 = LOAD 'wf.customers' USING org.apache.hive.hcatalog.pig.HCatLoader();
c1= join a1 by empid , b by customerid;
d1 = foreach c1 generate c.customerid,null,null,$0, $1, $6, $7, CONCAT($4,'--',$5), ToString(CurrentTime(),'yyyy-MM-dd'),CONCAT('','USD',''), ($3 is null ? 'No Value' : $3 );

dump d1;
--store d1 into '/usr/root/emp1/' overwrite;
