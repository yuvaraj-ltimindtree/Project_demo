CREATE OR REPLACE PACKAGE APPS.XXHIL_O2CL_UDA_WF_DS_PKG
AS
 /**********************************************************************************

  * FILE NAME: XXHIL_O2CL_UDA_WF_PKG.pks
  *
  *
  * OBJECT NAME: (WFL-PL2P-5243)- O2CL UDA Workflow
  *
  *
  * DESCRIPTION:  This Package will be used for O2CL UDA Workflow.
  *
  * HISTORY
  * =======
  *
  * VERSION DATE        AUTHOR          DESCRIPTION
  * ------- ----------- --------------- ------------------------------------------- *
  * 1.0     25-AUG-2021 Ninad Pimpale    XXHIL_O2CL_UDA_WF_DS_PKG (FRICEW: WFL-PL2P-5243)
  ***********************************************************************************/
   PROCEDURE START_WORKFLOW (P_SO_NUMBER    NUMBER,
                             P_SO_LINE      NUMBER,
                             P_CSR_NO       VARCHAR2);

   PROCEDURE SET_ITEM_ATTRIBUTES (P_ITEMTYPE    IN     VARCHAR2,
                                  P_ITEMKEY     IN     VARCHAR2,
                                  P_ACTID       IN     NUMBER,
                                  P_FUNCMODE    IN     VARCHAR2,
                                  X_RESULTOUT      OUT VARCHAR2);

   PROCEDURE GET_NEXT_APPROVER (P_ITEMTYPE    IN     VARCHAR2,
                                P_ITEMKEY     IN     VARCHAR2,
                                P_ACTID       IN     NUMBER,
                                P_FUNCMODE    IN     VARCHAR2,
                                X_RESULTOUT      OUT VARCHAR2);

   PROCEDURE RELEASE_WORKFLOW (P_UDA_REF_NO IN VARCHAR2);

   PROCEDURE INSERT_HISTORY (P_REQUEST_NO      IN VARCHAR2,
                             P_ACTION          IN VARCHAR2,
                             P_APPR_COMMENTS   IN VARCHAR2,
                             P_REF_NO          IN VARCHAR2,
                             P_STATUS          IN VARCHAR2,
                             P_ITEM_KEY        IN VARCHAR2,
                             P_DIST_LIST       IN VARCHAR2 );

   FUNCTION GET_URL (P_FUNC_NAME    IN VARCHAR2,
                     P_RESP_NAME    IN VARCHAR2,
                     P_PARAMETERS   IN VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE VALIDATE_RESPONSE (P_ITEMTYPE    IN            VARCHAR2,
                                P_ITEMKEY     IN            VARCHAR2,
                                P_ACTID       IN            NUMBER,
                                P_FUNCMODE    IN            VARCHAR2,
                                X_RESULTOUT      OUT NOCOPY VARCHAR2);

   PROCEDURE UPDATE_APPROVED_WORKFLLOW (P_ITEMTYPE    IN     VARCHAR2,
                                        P_ITEMKEY     IN     VARCHAR2,
                                        P_ACTID       IN     NUMBER,
                                        P_FUNCMODE    IN     VARCHAR2,
                                        X_RESULTOUT      OUT VARCHAR2);

   PROCEDURE SEND_PLANNEDTEAM_NTF (P_ITEMTYPE    IN     VARCHAR2,
                                   P_ITEMKEY     IN     VARCHAR2,
                                   P_ACTID       IN     NUMBER,
                                   P_FUNCMODE    IN     VARCHAR2,
                                   X_RESULTOUT      OUT VARCHAR2);

   PROCEDURE GET_DOCUMENT_DETAILS ( DOCUMENT_ID     IN              VARCHAR2,
                                    DISPLAY_TYPE    IN              VARCHAR2,
                                    DOCUMENT        IN OUT NOCOPY   CLOB,
                                    DOCUMENT_TYPE   IN OUT NOCOPY   VARCHAR2
                                   );
END XXHIL_O2CL_UDA_WF_DS_PKG;
/
SHOW ERROR;
EXIT;