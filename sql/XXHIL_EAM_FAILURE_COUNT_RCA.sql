set define off ;
CREATE OR REPLACE FUNCTION APPS.XXHIL_EAM_FAILURE_COUNT_RCA (
   --P_ASSET_NUM    VARCHAR2,
   P_ASSET_ID    NUMBER,
   P_FREQ        NUMBER
)
   RETURN NUMBER
--IS
AS
   /**********************************************************************
   * FILE NAME: XXHIL_EAM_FAILURE_COUNT_RCA
   *
   *
   * OBJECT NAME: XXHIL_EAM_FAILURE_COUNT_RCA
   *
   *
   * DESCRIPTION
   * Function XXXHIL_EAM_FAILURE_COUNT is created to check total number of Failure code against asset number. Workorder which is in 'Complete, Closed' status

   *
   * HISTORY
   * =======
   * NA
   *
   * VERSION DATE        AUTHOR          DESCRIPTION
   * ------- ----------- --------------- ---------------------------------
   * <n.nr>  dd-mon-yyyy <Name author>   <Version description>

   *1.0     21-Aug-2019  Kanchan Chouksey Function to count of Failure code against Asset Number
   **********************************************************************/
   P_WIP_ENTITY   NUMBER;
BEGIN
     /*****************************************Commented by Sarfraz on 15-Jan-2023***********************************************/   
     /*SELECT   MAX (WIP_ENTITY_ID)
       INTO   P_WIP_ENTITY
       FROM   (SELECT   ORGANIZATION_CODE,
                        ASSET_NUMBER,
                        WIP_ENTITY_ID,
                        FAILURE_CODE_CNT
                 FROM   (  SELECT   EWO.WIP_ENTITY_ID,
                                    OOD.ORGANIZATION_CODE,
                                    -- EWO.WIP_ENTITY_NAME,   commented for max condition
                                    EWO.INSTANCE_NUMBER ASSET_NUMBER,
                                    FAILURE_CODE,
                                    EWO.WORK_ORDER_TYPE_DISP,
                                    COUNT(EWO.FAILURE_CODE)
                                       OVER (
                                          PARTITION BY EWO.INSTANCE_NUMBER,
                                                       EWO.FAILURE_CODE
                                          ORDER BY EWO.FAILURE_CODE DESC
                                       )
                                       FAILURE_CODE_CNT
                             FROM   EAM_WORK_ORDERS_V EWO,
                                    EAM_JOB_COMPLETION_TXNS TXN,
                                    ORG_ORGANIZATION_DEFINITIONS OOD
                            WHERE       1 = 1
                                    AND EWO.WIP_ENTITY_ID = TXN.WIP_ENTITY_ID
                                    AND EWO.ORGANIZATION_ID = TXN.ORGANIZATION_ID
                                    AND OOD.ORGANIZATION_ID = EWO.ORGANIZATION_ID
                                    AND TRUNC (TXN.ACTUAL_END_DATE) BETWEEN TO_CHAR (
                                                                               TRUNC (
                                                                                  SYSDATE,
                                                                                  'MM'
                                                                               ),
                                                                               'DD-MON-YYYY'
                                                                            )
                                                                        AND  (LAST_DAY(TRUNC(SYSDATE)))
                                    AND EWO.WORK_ORDER_TYPE_DISP = 'Breakdown'
                                    AND EWO.WORK_ORDER_STATUS IN
                                             ('Complete',
                                              'Complete - No Charges',
                                              'Closed')
                                    AND EWO.INSTANCE_NUMBER = P_ASSET_NUM --    'M4/EN'
                         ORDER BY   EWO.INSTANCE_NUMBER) a
                WHERE   1 = 1 AND FAILURE_CODE_CNT >= P_FREQ)
   GROUP BY   ORGANIZATION_CODE, ASSET_NUMBER;
*/
/*****************************************End Commented by Sarfraz on 15-Jan-2023***********************************************/

/*****************************************Added by Sarfraz on 15-Jan-2023***********************************************/
   BEGIN
      SELECT   MAX (WIP_ENTITY_ID)
        INTO   P_WIP_ENTITY
        FROM   (SELECT   WDJ.WIP_ENTITY_ID,
                         COUNT(EAFC.FAILURE_CODE)
                            OVER (
                               PARTITION BY WDJ.MAINTENANCE_OBJECT_ID,
                                            EAFC.FAILURE_CODE
                               ORDER BY EAFC.FAILURE_CODE DESC
                            )
                            FAILURE_CODE_CNT
                  FROM   WIP_DISCRETE_JOBS WDJ,
                         EAM_JOB_COMPLETION_TXNS TXN,
                         EAM_ASSET_FAILURES EAF,
                         EAM_ASSET_FAILURE_CODES EAFC
                 WHERE       1 = 1
                         AND WDJ.WIP_ENTITY_ID = TXN.WIP_ENTITY_ID
                         AND WDJ.ORGANIZATION_ID = TXN.ORGANIZATION_ID
                         AND WDJ.WIP_ENTITY_ID = EAF.SOURCE_ID
                         AND EAF.FAILURE_ID = EAFC.FAILURE_ID
                         AND TRUNC (TXN.ACTUAL_END_DATE) BETWEEN TRUNC (
                                                                    SYSDATE,
                                                                    'MM'
                                                                 )
                                                             AND  (LAST_DAY(TRUNC(SYSDATE)))
                         AND WDJ.WORK_ORDER_TYPE = 30              --BREAKDOWN
                         AND WDJ.STATUS_TYPE IN (4, 5, 12)
                         AND WDJ.MAINTENANCE_OBJECT_ID = P_ASSET_ID)
               ASSET_COUNT
       WHERE   1 = 1 AND FAILURE_CODE_CNT >= P_FREQ;
   END;

/***************************************** End Added by Sarfraz on 15-Jan-2023***********************************************/
   RETURN P_WIP_ENTITY;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN NULL;
END XXHIL_EAM_FAILURE_COUNT_RCA; 
/
Exit;

