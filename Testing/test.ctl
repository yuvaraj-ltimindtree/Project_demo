--***********************************************************************************
--* FILE NAME: XXHIL_OM_PRICELIST_UPLD.ctl
--*
--*
--* OBJECT NAME: CNV-O2C-3
--*
--*
--* DESCRIPTION: SQL Loader Control file to handle Prize list conversion
--*
--* HISTORY
--* =======
--*
--* VERSION   DATE          AUTHOR          DESCRIPTION
--* ------- -----------  -------------     -------------------------------------------
--*   1.0   18-03-2024   Yuvaraj            Testing1
--*
--*
--* This is some code added by Dev1
--* New comment1
--*
--*
--************************************************************************************

OPTIONS(SKIP=1, errors=10000)
LOAD DATA
APPEND INTO TABLE APPS.XXHIL_OM_PRICE_LIST_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS 
                    (
                    NAME                    "TRIM(:NAME)",
                    DESCRIPTION             "TRIM(:DESCRIPTION)",
                    CURRENCY                "TRIM(:CURRENCY)",    
                    EFFECTIVE_DATE_FROM     "TRIM(:EFFECTIVE_DATE_FROM)",
                    EFFECTIVE_DATE_TO       "TRIM(:EFFECTIVE_DATE_TO)",
                    GLOBAL                  "TRIM(:GLOBAL)",    
                    OPERATING_UNIT          "TRIM(:OPERATING_UNIT)",
                    ROUND_TO                "TRIM(:ROUND_TO)",    
                    PRODUCT_CONTEXT         "TRIM(:PRODUCT_CONTEXT)",
                    PRODUCT_ATTRIBUTE       "TRIM(:PRODUCT_ATTRIBUTE)",
                    PRODUCT_VALUE           "TRIM(:PRODUCT_VALUE)",
                    UOM                     "TRIM(:UOM)",
                    PRIMARY_UOM             "TRIM(:PRIMARY_UOM)",      
                    VALUE                   "TRIM(:VALUE)",
                    FORMULA                 "TRIM(:FORMULA)",
                    START_DATE              "TRIM(:START_DATE)",    
                    END_DATE                "TRIM(:END_DATE)",
					LINE_PRECEDENCE         "TRIM(:LINE_PRECEDENCE)",
                    PRICING_CONTEXT         "TRIM(:PRICING_CONTEXT)",
                    PRICING_ATTRIBUTE       "TRIM(:PRICING_ATTRIBUTE)",
                    OPERATOR                "TRIM(:OPERATOR)",
                    PRICING_VALUE_FROM      "TRIM(:PRICING_VALUE_FROM)",
                    PRICING_VALUE_TO        "TRIM(:PRICING_VALUE_TO)",
                    GROUPING_NUMBER         "TRIM(:GROUPING_NUMBER)",
                    QULIFIER_CONTEXT        "TRIM(:QULIFIER_CONTEXT)",
                    QULIFIER_ATTRIBUTE      "TRIM(:QULIFIER_ATTRIBUTE)",
                    PRECEDENCE              "TRIM(:PRECEDENCE)",
					QUALIFIER_OPERATOR      "TRIM(:QUALIFIER_OPERATOR)",
                    QUALIFIER_VALUE_FROM    "TRIM(:QUALIFIER_VALUE_FROM)",
					QUALIFIER_VALUE_TO      "TRIM(:QUALIFIER_VALUE_TO)",
					QUALIFIER_START_DATE    "TRIM(:QUALIFIER_START_DATE)",
					QUALIFIER_END_DATE      "TRIM(:QUALIFIER_END_DATE)",
                    SECONDARY_PRICELIST     "TRIM(:SECONDARY_PRICELIST)",
                    SECONDARY_PRECEDENCE    "TRIM(:SECONDARY_PRECEDENCE)",
					CREATION_DATE                 "SYSDATE",
					CREATED_BY				    "-1",
					LAST_UPDATE_LOGIN           "-1",
					LAST_UPDATE_DATE			"SYSDATE",
					LAST_UPDATED_BY				"-1"  
                    )