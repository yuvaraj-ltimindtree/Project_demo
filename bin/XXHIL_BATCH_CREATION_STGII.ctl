-- +==============================================================================+
-- |Table Name                : XXHIL.XXHIL_BATCH_CREATION_STGII 
-- |Description               : control file move data from csv file to staging table
-- | 
-- |Purpose                   : Batch creation
-- |
-- |Change Record:
-- |=============================================================================================
-- |Version                Date               Author                           Remarks
-- |=======            ==========          =============                ==========================
-- | 1.0               31-07-2020         Arti Waghchaure            This control file is used to  move data from csv file to staging table
-- +============================================================================================+
OPTIONS(SKIP=1)
LOAD DATA
INFILE '$XXHIL_TOP/bin/XXHIL_BATCH_CREATION_STGII.csv'
BADFILE '$XXHIL_TOP/bin/XXHIL_BATCH_CREATION_STGII.bad'
DISCARDFILE '$XXHIL_TOP/bin/XXHIL_BATCH_CREATION_STGII.dsc'
APPEND INTO TABLE "XXHIL_BATCH_CREATION_STGII"
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS 
(
   BATCH_NO        		"TRIM(:BATCH_NO)",
   BATCH_QTY       		"TRIM(:BATCH_QTY)",
   ORGN_CODE	   		"TRIM(:ORGN_CODE)",
   PLAN_START_DATE  		"TRIM(:PLAN_START_DATE)",
   PLAN_CMPLT_DATE	        "TRIM(:PLAN_CMPLT_DATE)",
   PLAN_DUE_DATE		"TRIM(:PLAN_DUE_DATE)",
   ACTUAL_START_DATE 	        "TRIM(:ACTUAL_START_DATE)",
   PRODUCT_LINE_NO			"TRIM(:PRODUCT_LINE_NO)",
   PRODUCT_NO			"TRIM(:PRODUCT_NO)",
   RECIPE_NO			"TRIM(:RECIPE_NO)",
   RECIPE_VERSION		"TRIM(:RECIPE_VERSION)",
   STATUS			"TRIM(:STATUS)",
   LOT_TICKET			"TRIM(:LOT_TICKET)",
   LOT_NO			"TRIM(:LOT_NO)",
   QTY				"TRIM(:QTY)",
   UOM1				"TRIM(:UOM1)",
   UOM2				"TRIM(:UOM2)",
   SALES_ORDER			"TRIM(:SALES_ORDER)",
   LINE_NO			"TRIM(:LINE_NO)",
    BATCH_TYPE 			"TRIM(:BATCH_TYPE)",
	PRIORITY 			"TRIM(:PRIORITY)",
	CAST_TYPE 			"TRIM(:CAST_TYPE)",
	BATCH_PERIOD 		"TRIM(:BATCH_PERIOD)",
	HEEL 				"TRIM(:HEEL)",
	TARGET_GAUGE 		"TRIM(:TARGET_GAUGE)",
   PROCESSED_FLAG		 CONSTANT 'N',
   CREATION_DATE   		 "SYSDATE",
   CREATED_BY	    		 "fnd_global.user_id"
   		
)