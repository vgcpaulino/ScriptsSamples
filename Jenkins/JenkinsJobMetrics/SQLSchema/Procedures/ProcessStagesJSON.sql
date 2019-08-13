USE [JENKINS]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Vinicius Gabriel Cabral Paulino>
-- Create date: <09 MAR 2019>
-- Description:	<Parse the Stage JSON and insert into the STAGE_RESULTS and STAGE_DETAILS tables>
-- =============================================
CREATE PROCEDURE [dbo].[ProcessStagesJSON]
    @JOB_NAME VARCHAR(100),
    @BUILD_NUMBER INT,
    @JSON VARCHAR(MAX)
AS
BEGIN

    -- GET THE OVERALL PROPERTIES FROM THE STAGES;
    INSERT INTO STAGE_RESULTS (JOB_NAME, BUILD_NUMBER, STARTTIMEMILLIS, ENDTIMEMILLIS, DURATIONMILLIS, QUEUEDURATIONMILLIS, PAUSEDURATIONMILLIS, RESULT)
    SELECT 
        @JOB_NAME, @BUILD_NUMBER, C.*
    FROM OPENJSON(@JSON)
    WITH (
        startTimeMillis			VARCHAR(MAX),
        endTimeMillis			VARCHAR(MAX),
        durationMillis			VARCHAR(MAX),
        queueDurationMillis		VARCHAR(MAX),
        pauseDurationMillis		VARCHAR(MAX),
        status					VARCHAR(100)
    ) AS C
    -- CHECK THE BUILD AS PROCESSED;
    UPDATE STAGE_RESULTS SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

    -- GET THE DETAILED RESULT OF THE STAGES;
    DECLARE @STAGES_JSON NVARCHAR(MAX) = (SELECT VALUE FROM OPENJSON(@JSON) WHERE [KEY] = 'stages');
    INSERT INTO STAGE_DETAILS (JOB_NAME, BUILD_NUMBER, STAGE_ID, STAGE_NAME, STAGE_NODE, STARTTIMEMILLIS, DURATIONMILLIS, PAUSEDURATIONMILLIS, RESULT)
    SELECT 
        @JOB_NAME, @BUILD_NUMBER, C.*
    FROM OPENJSON(@STAGES_JSON)
    WITH (
        id					VARCHAR(MAX)	N'$.id',
        name				    VARCHAR(100)	N'$.name',
        execNode			    VARCHAR(100)	N'$.execNode',
        startTimeMillis		VARCHAR(MAX)	N'$.startTimeMillis',
        durationMillis		VARCHAR(MAX)	N'$.durationMillis',
        pauseDurationMillis	VARCHAR(MAX)	N'$.pauseDurationMillis',
        status				VARCHAR(100)	N'$.status'
    ) AS C
    -- CHECK THE BUILD AS PROCESSED;
    UPDATE STAGE_DETAILS SET PROCESSED = 1 WHERE JOB_NAME = @JOB_NAME AND BUILD_NUMBER = @BUILD_NUMBER;

END

GO
