SET DEFINE OFF;

update apps.mtl_system_items_b   msi
set RECEIVING_ROUTING_ID = NULL
, INSPECTION_REQUIRED_FLAG = 'N'
WHERE 1=1
AND ENABLED_FLAG = 'Y'
AND RECEIVING_ROUTING_ID = 2
AND INSPECTION_REQUIRED_FLAG = 'Y'
and inventory_item_status_code = 'Active'
and exists (select 1 from apps.org_organization_definitions ood
            where 1=1
                  and upper( ood.organization_name) like upper( '%Godown%')
                  and ood.organization_id = msi.organization_id );
/
COMMIT;
/
update apps.mtl_system_items_b   msi
set RECEIVING_ROUTING_ID = NULL
, INSPECTION_REQUIRED_FLAG = 'N'
WHERE 1=1
AND ENABLED_FLAG = 'Y'
AND RECEIVING_ROUTING_ID = 2
AND INSPECTION_REQUIRED_FLAG = 'Y'
and inventory_item_status_code = 'Active'
and exists (select 1 from apps.org_organization_definitions ood
            where 1=1
                  and upper( ood.organization_name) like upper( '%Depot%')
                  and ood.organization_id = msi.organization_id );
/
COMMIT;
/	
EXIT			  
