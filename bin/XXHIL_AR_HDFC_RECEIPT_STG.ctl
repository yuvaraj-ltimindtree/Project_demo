--***********************************************************************************
--* FILE NAME: XXHIL_AR_SCB_RECEIPT.ctl
--*
--*
--* OBJECT NAME: INT-FA-AP-
--*
--*
--* DESCRIPTION: SQL Loader Control file to handle feed for HDFC payment
--*
--*
--* HISTORY
--* =======
--*
--* VERSION   DATE          AUTHOR          DESCRIPTION
--* ------- -----------  -------------     -------------------------------------------
--*   1.0   24-APR-2023  Rajesh Kumar Singh      Initial Creation
--*
--*
--************************************************************************************
OPTIONS (SKIP = 1)
LOAD DATA
APPEND 
INTO TABLE "XXHIL_AR_BANK_RECEIPTS_STG"
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS 
	(
		RECEIPT_TRANS_TYPE 			"TRIM(:RECEIPT_TRANS_TYPE)",
		ENTRY_AMOUNT 			"TRIM(:ENTRY_AMOUNT)",
		VALUE_DATE 			"TRIM(:VALUE_DATE)",
		PARTY_CODE 			"TRIM(:PARTY_CODE)",
		PARTY_NAME				"TRIM(:PARTY_NAME)",
		VIRTUAL_ACCOUNT_NUMBER  "TRIM(:VIRTUAL_ACCOUNT_NUMBER)",
		LOCATION_NAME  "TRIM(:LOCATION_NAME)",
		REMITTING_BANK  "TRIM(:REMITTING_BANK)",
		UTR_NUMBER				"TRIM(:UTR_NUMBER)",
		ACCOUNT_NUMBER				"TRIM(:ACCOUNT_NUMBER)",
		CHEQUE_NUMBER			"TRIM(:CHEQUE_NUMBER)",	   
		REQUEST_ID                    CONSTANT CP_REQUEST_ID, 
		UPLOAD_ID               "XXHIL_AR_BANK_RECEIPTS_STG_S.NEXTVAL",    
		CREATED_BY                    CONSTANT USER_ID,
		CREATION_DATE                "SYSDATE",
		LAST_UPDATED_BY                CONSTANT USER_ID,
		LAST_UPDATE_DATE             "SYSDATE" 
    )