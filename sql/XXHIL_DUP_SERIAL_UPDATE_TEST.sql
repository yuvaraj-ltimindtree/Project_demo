create or replace PROCEDURE      XXHIL_DUP_SERIAL_UPDATE_TEST  (X_ERRBUF              OUT VARCHAR2,
																X_RETCODE             OUT NUMBER) --(p_org_id NUMBER) commented this parameter
AS
----------------------------------------------------------------------------------------
-- File name       : XXHIL_DUPLICATE_SERIAL_UPDATE.sql
-- Object Name     : XXHIL_DUPLICATE_SERIAL_UPDATE
-- Component       : EXT-F_A-AR-664
-- Author          : Naveen
-- Created         : 17-AUG-2022
-- Description     :
----------------------------------------------------------------------------------------
--  Date          Author          Version    Reason
-------------- ---------------   -------- ---------------------------------------------
-- 17-AUG-2022  Naveen               1.0      Initial creation
-- 14-SEP-2023  Ritu                 1.1      #182168,194484- Removing 22 year
-- 09-JAN-2023  Mukit                1.2      Changed on 09-Jan-2023
-- 29-MAR-2024	Dhanashree			 1.3      275971 - Minor changes to improve perforamance (Oracle SR 3-36256549521)
----------------------------------------------------------------------------------------

cursor c1 is select attribute1 from (select org_id,attribute1,count(document_id) from
(select distinct org_id,attribute1,document_id from apps.JAI_RGM_RECOVERY_LINES where processed_date >= '01-APR-2022' and attribute1 IS NOT NULL --and org_id = p_org_id  commented for 275971
) group by org_id,attribute1
having count(document_id) > 1 order by org_id) ;

cursor c2(p_attribute1 varchar2) is select distinct document_id,entity_code,org_id,attribute1
,to_char(processed_date,'YY') yr,to_char(processed_date,'MON') l_month -- Added by Ritu on 14sep23 for #182168,194484
from apps.JAI_RGM_RECOVERY_LINES
        where processed_date >= '01-APR-2022'
        and attribute1 = p_attribute1 OFFSET 1 ROWS;

v_document_id           NUMBER;
v_seq_name              VARCHAR2 (50);
v_myseqnum                NUMBER;
v_new_seq              VARCHAR2 (50);
l_month                VARCHAR2(10);
FY_YR                  VARCHAR2(10);
RECORD_NOT_SAVED		EXCEPTION;

begin

for i in c1
loop
for j in c2(i.attribute1)
loop

BEGIN
      SELECT meaning
        INTO v_seq_name
        FROM fnd_lookup_values_vl
       WHERE lookup_type = 'XXHIL_OFI_PROCESS_CLAIM'
         AND lookup_code = (select name from hr_operating_units where organization_id=j.org_id)
         AND enabled_flag = 'Y'
         AND end_date_active IS NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_seq_name := NULL;
   END;

  BEGIN

  fy_yr := j.yr;
  l_month := j.l_month;

  IF l_month IN ('JAN','FEB','MAR')
      THEN fy_yr := fy_yr - 1;
      END IF;

  SELECT /*+ INDEX (jl XXHIL_JAI_RGM_LINES_ATTRIBUTE11) */ MAX(to_number(substr(attribute1,6))) 
		 INTO   v_myseqnum
         FROM   jai_rgm_recovery_lines jl
        -- WHERE  SUBSTR(attribute1,1,2) = 22
         WHERE  SUBSTR(attribute1,1,2) = fy_yr -- changed by Ritu on 14sep23 for #182168,194484
		 --AND    processed_date >= '01-APR-2022'
         AND    org_id = j.org_id
		/* AND    NOT EXISTS
		                   (SELECT 1
						    FROM   jai_rgm_recovery_lines
						    WHERE  claim_schedule_id = jl.claim_schedule_id
                            AND    attribute1 like '22%'
                            AND    processed_date = '31-MAR-2022'
						   ) */  --removed not exists and added hint for Incident ID - 275971
		 ;
         v_myseqnum := v_myseqnum+1;
      EXCEPTION
	     WHEN NO_DATA_FOUND
		 THEN
		    v_myseqnum :=1;

         WHEN OTHERS
         THEN
            v_myseqnum := 0;
      END;

   -- v_new_seq := TO_CHAR (22) || v_seq_name || TO_CHAR (v_myseqnum);
    v_new_seq := fy_yr || v_seq_name || TO_CHAR (v_myseqnum); -- changed by Ritu on 14sep23 for #182168,194484


		FND_FILE.PUT_LINE (FND_FILE.LOG,'*****Log Starts ******');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'document_id Value=>'||j.document_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'v_seq_name=>'||v_seq_name);
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'v_myseqnum=>'||v_myseqnum);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Newely updated sequence Name =>'||v_new_seq);

        BEGIN
			UPDATE JAI_RGM_RECOVERY_LINES
			SET attribute1 = v_new_seq
			WHERE document_id = j.document_id
			AND entity_code = j.entity_code
			AND org_id = j.org_id;
		EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Error While Updating JAI_RGM_RECOVERY_LINES Table With new HKF Attribute1-'||SQLERRM);
         END;

		 FND_FILE.PUT_LINE (FND_FILE.LOG,'******* Start Records Update History *******');
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'============================================');
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'Old Sequence :- '||j.attribute1);
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'Document Id :- '||j.document_id);
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'Entity Code :- '||j.entity_code);
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'New Sequence :- '||v_new_seq);
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'******* End Records Update History *******');
		 FND_FILE.PUT_LINE (FND_FILE.LOG,'============================================');

        IF (SQL%rowcount = 0) THEN
        RAISE RECORD_NOT_SAVED;
        END IF;

        FND_FILE.PUT_LINE (FND_FILE.LOG,'JAI_RGM_RECOVERY_LINES Number of records updated -'||sql%rowcount);

		BEGIN
			UPDATE xxhil_ap_ofi_sequence
			SET sequence_no = v_new_seq
			WHERE document_id = j.document_id
			AND entity_code = j.entity_code
			AND org_id = j.org_id;
		EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG,'xxhil_ap_ofi_sequence Number of records updated- '||sql%rowcount);
         END;

        IF (SQL%rowcount = 0) THEN
        RAISE RECORD_NOT_SAVED;
        END IF;

        COMMIT;
        FND_FILE.PUT_LINE (FND_FILE.LOG,'xxhil_ap_ofi_sequence Number of records updated -'||sql%rowcount);

		FND_FILE.PUT_LINE (FND_FILE.LOG,'*****Log Ends ******');

        End loop;
 end loop;
exception
WHEN RECORD_NOT_SAVED THEN
ROLLBACK;
when others then
FND_FILE.PUT_LINE (FND_FILE.LOG,'Errro main exception'||SQLERRM);
		X_ERRBUF := 'Error in procedure XXHIL_DUP_SERIAL_UPDATE_TEST'||SQLERRM;
        X_RETCODE := 2;
END XXHIL_DUP_SERIAL_UPDATE_TEST;
/
SHOW ERROR;
EXIT;