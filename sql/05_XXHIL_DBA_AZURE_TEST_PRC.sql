CREATE PROCEDURE APPS.XXHIL_DBA_AZURE_TEST_PRC (p_name VARCHAR2)
IS
    m_srno        NUMBER(4);
BEGIN
    m_srno := 0;
    SELECT    APPS.XXHIL_DBA_AZURE_TEST_SEQ.NEXTVAL
    INTO    m_srno 
    FROM    DUAL;

   INSERT INTO XXHIL_DBA_AZURE_TEST_TAB
--       (srno, 
--        name)
   VALUES
        (m_srno,
        p_name);
        COMMIT;
END;
/
exit

