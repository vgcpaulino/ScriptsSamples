USE [JENKINS]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Vinicius Gabriel Cabral Paulino>
-- Create date: <09 MAR 2019>
-- Description:	<Parse the Build JSON and insert into the BUILD_RESULTS, BUILD_CAUSES, BUILD_VARIABLES and BUILD_TEST_SUMMARY tables>
-- =============================================
CREATE PROCEDURE [dbo].[ProcessBuildJSON]
    @JOB_NAME VARCHAR(100),
    @BUILD_NUMBER INT,
    @JSON VARCHAR(MAX)
AS
BEGIN

    -- GET THE OVERALL PROPERTIES FROM THE BUILD;
    INSERT INTO BUILD_RESULTS (JOB_NAME, BUILD_NUMBER, DURATION, DURATION_ESTIMATED, FULL_DISPLAY_NAME, PREVIOUS_BUILD, RESULT, DESCRIPTION)
    SELECT
        @JOB_NAME, @BUILD_NUMBER, C.DURATION, C.ESTIMATEDDURATION, C.FULLDISPLAYNAME, P.NUMBER, C.RESULT, REPLACE(REPLACE(REPLACE(C.DESCRIPTION, '<B>', ''), '</B>', ''), 'N++', '')
    FROM OPENJSON(@JSON)
    WITH (
        duration            INT,
        estimatedDuration	INT,
        fullDisplayName     VARCHAR(50),
        previousBuild		NVARCHAR(MAX) AS JSON,
        result				VARCHAR(50),
        description         VARCHAR(MAX)
    ) AS C
    OUTER APPLY OPENJSON(previousBuild)
    WITH (
        number        INT
    ) AS P
    -- CHECK THE BUILD AS PROCESSED;
    UPDATE BUILD_RESULTS SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

    -- CHECK IF THE JSON FILE PRESENT THE ACTIONS COLLECTION AND EXTRACT: CAUSES,  PARAMETERS AND TEST SUMMARY;
    DECLARE @HasActions INT;
    DECLARE @QtyActions INT;
    SET @HasActions = ISNULL( (SELECT COUNT(*) FROM OPENJSON(@JSON) WHERE [KEY] = 'actions'), 0);
    IF (@HasActions = 1)
    BEGIN
        SET @QtyActions = (SELECT COUNT(*) FROM OPENJSON(@JSON, N'lax $.actions'));
        DECLARE @AUX_ACTIONS INT = 0;
        WHILE(@AUX_ACTIONS < @QtyActions)
        BEGIN
            DECLARE @KEY_JSON NVARCHAR(MAX) = (SELECT VALUE FROM OPENJSON(@JSON, N'lax $.actions') WHERE [KEY] = @AUX_ACTIONS);
            IF ( (SELECT COUNT(*) FROM OPENJSON(@KEY_JSON)) != 0)
            BEGIN

                -- EXTRACT DATA FROM CAUSEACTION CLASS;
                IF ( (SELECT VALUE FROM OPENJSON(@KEY_JSON) WHERE [KEY] = '_class') = 'hudson.model.CauseAction')
                BEGIN
                    DECLARE @CAUSES NVARCHAR(MAX) = (SELECT VALUE FROM OPENJSON(@KEY_JSON) WHERE [KEY] = 'causes');
                    INSERT INTO BUILD_CAUSES (JOB_NAME, BUILD_NUMBER, CLASS, CAUSE_DESCRIPTION, UPSTREAM_JOB, UPSTREAM_BUILD, USER_ID, USER_NAME)
                    SELECT
                        @JOB_NAME, @BUILD_NUMBER, C.*
                    FROM OPENJSON(@CAUSES)
                    WITH (
                        CLASS	    		VARCHAR(100)	N'$._class',
                        CAUSE_DESCRIPTION	VARCHAR(100)	N'$.shortDescription',
                        UPSTREAM_JOB		VARCHAR(100)	N'$.upstreamProject',
                        UPSTREAM_BUILD		VARCHAR(100)	N'$.upstreamBuild',
                        USER_ID 			VARCHAR(100)	N'$.userId',
                        USER_NAME 			VARCHAR(100)	N'$.userName'
                    ) AS C
                END
                -- CHECK THE BUILD AS PROCESSED;
                UPDATE BUILD_CAUSES SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

                -- EXTRACT DATA FROM PARAMETERACTION CLASS;
                IF ( (SELECT VALUE FROM OPENJSON(@KEY_JSON) WHERE [KEY] = '_class') = 'hudson.model.ParametersAction')
                BEGIN
                    DECLARE @PARAM NVARCHAR(MAX) = (SELECT VALUE FROM OPENJSON(@KEY_JSON) WHERE [KEY] = 'parameters');
                    INSERT INTO BUILD_VARIABLES (JOB_NAME, BUILD_NUMBER, CLASS, VARIABLE_NAME, VARIABLE_VALUE)
                    SELECT 
                        @JOB_NAME, @BUILD_NUMBER, C.* 
                    FROM OPENJSON(@PARAM)
                    WITH (
                        CLASS				VARCHAR(100)	N'$._class',
                        VARIABLE_NAME	    VARCHAR(100)	N'$.name',
                        VARIABLE_VALIE		VARCHAR(100)	N'$.value'
                    ) AS C
                END
                -- CHECK THE BUILD AS PROCESSED;
                UPDATE BUILD_VARIABLES SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

                -- EXTRACT DATA FROM TESTRESULTACTION CLASS;
                IF ( (SELECT VALUE FROM OPENJSON(@KEY_JSON) WHERE [KEY] = '_class') = 'hudson.tasks.junit.TestResultAction')
                BEGIN
                    INSERT INTO BUILD_TEST_SUMMARY (JOB_NAME, BUILD_NUMBER, CLASS, FAIL_COUNT, SKIP_COUNT, TOTAL_COUNT)
                    SELECT
                        @JOB_NAME, @BUILD_NUMBER, C.* 
                    FROM OPENJSON(@KEY_JSON)
                    WITH (
                        CLASS				VARCHAR(100)	N'$._class',
                        FAIL_COUNT			INT				N'$.failCount',
                        SKIP_COUNT			INT				N'$.skipCount',
                        TOTAL_COUNT			INT				N'$.totalCount'
                    ) AS C
                END
                -- CHECK THE BUILD AS PROCESSED;
                UPDATE BUILD_TEST_SUMMARY SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

            END
            SET @AUX_ACTIONS = @AUX_ACTIONS + 1;
        END
    END 

END

GO
