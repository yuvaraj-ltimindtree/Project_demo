--***********************************************************************************
--* FILE NAME: XXHIL_INV_DIRECT_ORG_TRANS_STG.ctl
--*
--*
--* OBJECT NAME: INT-FA-AP-
--*
--*
--* DESCRIPTION: SQL Loader Control file to handle Reverse feed for AR Upload Transactions
--*
--*
--* HISTORY
--* =======
--*
--* VERSION   DATE          AUTHOR          DESCRIPTION
--* ------- -----------  -------------     -------------------------------------------
--*   1.0   01-JAN-2021  Rajesh Kumar Singh      Initial Creation
--*
--*
--************************************************************************************
OPTIONS (SKIP = 1)
LOAD DATA
APPEND 
INTO TABLE "XXHIL_INV_DIRECT_ORG_TRANS_STG"
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS 
    (    
    ITEM_CODE				"TRIM(:ITEM_CODE)",
	FROM_ORGANIZATION_CODE				"TRIM(:FROM_ORGANIZATION_CODE)",
	FROM_SUBINVENTORY				"TRIM(:FROM_SUBINVENTORY)",
	TO_ORGANIZATION_CODE				"TRIM(:TO_ORGANIZATION_CODE)",
	TO_SUBINVENTORY				"TRIM(:TO_SUBINVENTORY)",
	LOT_NUMBER				"TRIM(:LOT_NUMBER)",
	PRIMARY_UOM_CODE				"TRIM(:PRIMARY_UOM_CODE)",
	PRIMARY_QUANTITY				"TRIM(:PRIMARY_QUANTITY)",
	SECONDARY_UOM_CODE				"TRIM(:SECONDARY_UOM_CODE)",
	SECONDARY_QUANTITY				"TRIM(:SECONDARY_QUANTITY)",
    REQUEST_ID                    CONSTANT CP_REQUEST_ID,
    FILE_NAME                        CONSTANT 'FILE',    
    UPLOAD_ID               "XXHIL_INV_DIRECT_ORG_TRANS_STG_S.NEXTVAL",    
    CREATED_BY                    CONSTANT USER_ID,
    CREATION_DATE                "SYSDATE",
    LAST_UPDATED_BY                CONSTANT USER_ID,
    LAST_UPDATE_DATE             "SYSDATE"       
)