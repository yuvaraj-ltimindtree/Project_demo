CREATE OR REPLACE TRIGGER "APPS"."XXHIL_EAM_MAINT_APP_TRG" AFTER
/***********************************************************************************
* FILE NAME: XXHIL_EAM_MAINT_APP_TRG
*
* HISTORY
* =======
*
* VERSION   DATE          AUTHOR          DESCRIPTION
* ------- -----------  -------------     -------------------------------------------
*   2.0   16-NOV-2023  Venkataiah L      INC218850 - Performance issue fix
************************************************************************************/
    INSERT ON "INV"."MTL_TXN_REQUEST_LINES"
    REFERENCING
            NEW AS new
            OLD AS old
    FOR EACH ROW
DECLARE
    v_area        VARCHAR2(50);
    v_dept_code   VARCHAR2(50);
    v_req_num     VARCHAR2(50);
    v_wip_id      NUMBER := :new.txn_source_id;

--PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    BEGIN

/*select distinct
EWO.OWNING_DEPARTMENT_CODE, ESN.AREA  INTO V_DEPT_CODE ,v_area
from
APPS.EAM_WORK_ORDERS_V EWO,
APPS.mtl_eam_asset_numbers_all_v ESN
WHERE 1=1
AND  EWO.WIP_ENTITY_ID = :NEW.TXN_SOURCE_ID
AND EWO.INSTANCE_NUMBER = ESN.INSTANCE_NUMBER
AND EWO.WIP_ENTITY_ID = V_WIP_ID; */
        SELECT DISTINCT
            bd.department_code,
            esn.area
        INTO
            v_dept_code,
            v_area
        FROM
            wip_discrete_jobs                  wdj,
            bom_departments                    bd,
            csi_item_instances                 cii,
            apps.mtl_eam_asset_numbers_all_v   esn
        WHERE
            1 = 1
            AND wdj.wip_entity_id = :new.txn_source_id
            AND bd.department_id = wdj.owning_department
            AND bd.organization_id = wdj.organization_id
            AND cii.instance_id = wdj.maintenance_object_id
            AND wdj.organization_id = cii.last_vld_organization_id
            AND wdj.maintenance_object_type = 3
            AND esn.instance_number = cii.instance_number
            AND wdj.wip_entity_id = v_wip_id;


/*
select distinct
request_number INTO  V_REQ_NUM
from INV.mtl_txn_request_headers H
WHERE 1=1
AND H.HEADER_ID = :NEW.HEADER_ID
AND H.ATTRIBUTE3 is null
AND H.ATTRIBUTE4 is null;
*/

    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    IF v_dept_code IS NOT NULL AND v_area IS NOT NULL THEN
        UPDATE inv.mtl_txn_request_headers
        SET
            attribute_category = 'Maintenance Approval',
            attribute3 = v_area,
            attribute4 = v_dept_code,
            attribute5 = 'Y'
        WHERE
            1 = 1
            AND header_id = :new.header_id
            AND attribute3 IS NULL
            AND attribute4 IS NULL;

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/ 
SHOW ERROR;
EXIT;