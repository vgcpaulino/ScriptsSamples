USE [JENKINS]
GO

/****** Object:  StoredProcedure [dbo].[ProcessPendingBuilds]    Script Date: 04/25/2019 18:19:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Vinicius Gabriel Cabral Paulino>
-- Create date: <09 MAR 2019>
-- Description:	<Process all the JSONs>
-- =============================================
CREATE PROCEDURE [dbo].[ProcessPendingBuilds]
AS
BEGIN
    
    -- CREATE TEMP TABLE TO STORE THE JOBS THAT NEED BE PROCESSED;
    IF OBJECT_ID('tempdb..#PENDING_JOBS') IS NOT NULL DROP TABLE #PENDING_JOBS;
    CREATE TABLE #PENDING_JOBS (
        ID INT IDENTITY(1, 1),
        JOB_NAME VARCHAR(100),
        BUILD_NUMBER INT
    )
    INSERT INTO #PENDING_JOBS (JOB_NAME, BUILD_NUMBER) SELECT JOB_NAME, BUILD_NUMBER FROM BUILDS WHERE PROCESSED = 0;

    IF ((SELECT COUNT(*) FROM #PENDING_JOBS) != 0)
    BEGIN
        DECLARE @JOB_NAME VARCHAR(100);
        DECLARE @BUILD_NUMBER INT;
        DECLARE @JSON NVARCHAR(MAX);
        DECLARE @ID INT;
        DECLARE @COUNTER INT = 1;
        
        WHILE @COUNTER <= (SELECT COUNT(*) FROM #PENDING_JOBS)
        BEGIN
            -- GET MAIN INFORMATION FROM THE TEMP TABLE;
            SET @JOB_NAME = (SELECT JOB_NAME FROM #PENDING_JOBS WHERE ID = @COUNTER);
            SET @BUILD_NUMBER = (SELECT BUILD_NUMBER FROM #PENDING_JOBS WHERE ID = @COUNTER);
            
            -- PROCESS THE BUILD_JSON TABLE;
            --SET @JSON = (SELECT TOP 1 BUILD_JSON FROM BUILDS_JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER AND PROCESSED = 0 ORDER BY ID DESC);
            SELECT 
                TOP 1
                @JSON = BUILD_JSON,
                @ID = ID
            FROM BUILDS_JSON
            WHERE 
                JOB_NAME = @JOB_NAME 
                AND BUILD_NUMBER = @BUILD_NUMBER 
                AND PROCESSED = 0 
            ORDER BY ID DESC

			/*	TEST THE JSON BEFORE EXECUTE THE STORED PROCEDURE;
				IF THE TEST FAILS SET THE BUILDS.PROCESSED_FAIL = 1 TO IDENTIFY THAT WAS IN THE "BUILD" PROCESSING; */
			IF (ISJSON(@JSON) <= 0)
			BEGIN

				IF (SUBSTRING(@JSON, LEN(@JSON), LEN(@JSON)) = '$')
				BEGIN
					UPDATE BUILDS_JSON SET BUILD_JSON_ORIGINAL = @JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;
					SET @JSON = LEFT(@JSON, LEN(@JSON) - 1);
					UPDATE BUILDS_JSON SET BUILD_JSON = @JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;
				END

				IF (ISJSON(@JSON) <= 0)
				BEGIN
					UPDATE BUILDS SET PROCESSED = 1, PROCESSED_FAIL = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;
					SET @COUNTER = @COUNTER + 1;
					CONTINUE;
				END

			END

            EXEC ProcessBuildJSON @JOB_NAME, @BUILD_NUMBER, @JSON;
            UPDATE BUILDS_JSON SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER AND ID = @ID;
            
            /*	################################
				PROCESS THE STAGES_JSON TABLE
				################################ */
            IF ( (SELECT COUNT(*) FROM STAGES_JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER) > 0)
            BEGIN
                --SET @JSON = (SELECT TOP 1 STAGES_JSON FROM STAGES_JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER AND PROCESSED = 0 ORDER BY ID DESC);
                SELECT
                    TOP 1
                    @JSON = STAGES_JSON,
                    @ID = ID
                FROM STAGES_JSON
                WHERE 
                    JOB_NAME = @JOB_NAME
                    AND BUILD_NUMBER = @BUILD_NUMBER
                    AND PROCESSED = 0
                ORDER BY ID DESC

				/*	TEST THE JSON BEFORE EXECUTE THE STORED PROCEDURE;
					IF THE TEST FAILS SET THE BUILDS.PROCESSED_FAIL = 2 TO IDENTIFY THAT WAS IN THE "STAGES" PROCESSING; */
				IF (ISJSON(@JSON) <= 0)
				BEGIN
					UPDATE BUILDS SET PROCESSED = 1, PROCESSED_FAIL = 2 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;
					SET @COUNTER = @COUNTER + 1;
					CONTINUE;
				END
				ELSE
				BEGIN
					EXEC ProcessStagesJSON @JOB_NAME, @BUILD_NUMBER, @JSON;
				END

                
            END
            UPDATE STAGES_JSON SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER AND ID = @ID;

            /*	################################
				PROCESS THE TESTS_JSON TABLE
				################################ */
            IF ( (SELECT COUNT(*) FROM TESTS_JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER) > 0)
            BEGIN
                --SET @JSON = (SELECT TOP 1 TESTS_JSON FROM TESTS_JSON WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER AND PROCESSED = 0 ORDER BY ID DESC);
                SELECT
                    TOP 1
                    @JSON = TESTS_JSON,
                    @ID = ID
                FROM TESTS_JSON
                WHERE 
                    JOB_NAME = @JOB_NAME
                    AND BUILD_NUMBER = @BUILD_NUMBER
                    AND PROCESSED = 0
                ORDER BY ID DESC
				
				/*	TEST THE JSON BEFORE EXECUTE THE STORED PROCEDURE;
					IF THE TEST FAILS SET THE BUILDS.PROCESSED_FAIL = 3 TO IDENTIFY THAT WAS IN THE "TEST" PROCESSING; */
				IF (ISJSON(@JSON) <= 0)
				BEGIN
					UPDATE BUILDS SET PROCESSED = 1, PROCESSED_FAIL = 3 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;
					SET @COUNTER = @COUNTER + 1;
					CONTINUE;
				END
				ELSE
				BEGIN
					EXEC ProcessTestJSON @JOB_NAME, @BUILD_NUMBER, @JSON
				END

            END
            UPDATE TESTS_JSON SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER AND ID = @ID;

            -- CHECK THE BUILD AS PROCESSED;
            UPDATE BUILDS SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

            SET @COUNTER = @COUNTER + 1;
        END

    END

END


GO


