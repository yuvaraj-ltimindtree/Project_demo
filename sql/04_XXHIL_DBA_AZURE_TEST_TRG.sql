-- This is a sample code for ADS demo

CREATE TRIGGER APPS.XXHIL_DBA_AZURE_TEST_TRG
BEFORE INSERT
ON APPS.XXHIL_DBA_AZURE_TEST_TAB FOR EACH ROW
BEGIN
 INSERT INTO  APPS.XXHIL_DBA_AZURE_TEST_TAB
                 (
		srno,
        	name)
values
(
	:NEW.srno,
	SUBSTR(:NEW.name,1,4)
                  );
 EXCEPTION
 WHEN OTHERS THEN
 NULL;
END;
/
exit

