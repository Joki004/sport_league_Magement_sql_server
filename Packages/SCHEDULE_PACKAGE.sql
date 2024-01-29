DROP FUNCTION IF EXISTS SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED;
DROP FUNCTION IF EXISTS SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH;
DROP FUNCTION IF EXISTS SCHEDULE_FIND_DATA_FOR_MATCH;

DROP PROCEDURE IF EXISTS SCHEDULE_ADD_MATCH;
DROP PROCEDURE IF EXISTS SCHEDULE_GENERATE_SCHEDULE;
DROP PROCEDURE IF EXISTS SCHEDULE_PRINT_MATCHES_FOR_TEAM
DROP PROCEDURE IF EXISTS SCHEDULE_PRINT_SCHEDULE
GO

----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------
-- CREATE FUNCTION SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED
CREATE OR ALTER FUNCTION dbo.SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED (
    @date_match DATE
) RETURNS BIT
AS
BEGIN
    DECLARE @match_count INT;
    DECLARE @check BIT;

    SELECT @match_count = COUNT(*)
    FROM MATCH t
    WHERE t.match_date = @date_match;

    IF @match_count = 0
        SET @check = 0;
  
    ELSE
  
        SET @check = 1;


    RETURN @check;
END;
GO

-- CREATE FUNCTION SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH
CREATE FUNCTION dbo.SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH (
    @team_name VARCHAR(50),
    @match_date DATE
) RETURNS BIT
AS
BEGIN
    DECLARE @last_match_date DATE;
    DECLARE @time_difference INT;

    SELECT @last_match_date = MAX(p.MATCH_DATE)
    FROM MATCH p
    WHERE p.TEAM_HOME_ID = (SELECT TEAM_ID FROM Team WHERE NAME = @team_name)
       OR p.TEAM_AWAY_ID = (SELECT TEAM_ID FROM Team WHERE NAME = @team_name);

    IF @last_match_date IS NULL
        RETURN 1; -- TRUE
    ELSE
        SET @time_difference = DATEDIFF(HOUR, @last_match_date, @match_date);
        
        IF @time_difference > 24
            RETURN 1; -- TRUE
        ELSE
            RETURN 0; -- FALSE
    

    -- This RETURN statement is added to comply with SQL Server function requirements
    RETURN 0;
END;
GO


-- CREATE FUNCTION SCHEDULE_FIND_DATA_FOR_MATCH
CREATE FUNCTION dbo.SCHEDULE_FIND_DATA_FOR_MATCH (
    @team_away_name VARCHAR(50),
    @team_home_name VARCHAR(50),
    @start_season_date DATE
) RETURNS DATE
AS
BEGIN
    DECLARE @found_date BIT;
    DECLARE @v_hour INT;
    DECLARE @start_date DATETIME; -- Change to datetime
    
    SET @start_date = CAST(@start_season_date AS DATETIME); -- Convert to datetime
    SET @found_date = 0; -- FALSE

    WHILE 1 = 1
    BEGIN
        IF dbo.SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED(@start_date) = 0
           AND dbo.SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH(@team_home_name, @start_date) = 1
           AND dbo.SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH(@team_away_name, @start_date) = 1
        BEGIN
            SET @found_date = 1; -- TRUE
            RETURN CONVERT(DATE, @start_date); -- Convert back to date
        END;

        SET @start_date = DATEADD(HOUR, 1, @start_date);
        SET @v_hour = DATEPART(HOUR, @start_date);

        IF @v_hour = 23
        BEGIN
            SET @start_date = DATEADD(DAY, 1, @start_date) + '12:00:00';
        END;
    END;

    -- This RETURN statement is added to comply with SQL Server function requirements
    RETURN GETDATE();
END;
GO



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------
-- CREATE PROCEDURE dbo.SCHEDULE_ADD_MATCH
CREATE PROCEDURE dbo.SCHEDULE_ADD_MATCH (
    @team_home INT,
    @team_away INT,
    @match_date DATE,
    @sport_object INT
)
AS
BEGIN
    INSERT INTO MATCH (MATCH_DATE, SPORT_OBJECT_ID, TEAM_HOME_ID, TEAM_AWAY_ID, SCORE_HOME, SCORE_AWAY)
    VALUES (@match_date, @sport_object, @team_home, @team_away, 0, 0);
END;
GO

--CREATE OR ALTER PROCEDURE dbo.SCHEDULE_GENERATE_SCHEDULE

CREATE OR ALTER PROCEDURE dbo.SCHEDULE_GENERATE_SCHEDULE (
    @start_season_date DATE
)
AS
BEGIN
    DECLARE @v_team_home_name VARCHAR(50);
    DECLARE @v_team_away_name VARCHAR(50);
    DECLARE @v_match_date DATE;
    DECLARE @v_team_home INT;
    DECLARE @v_team_away INT;
    DECLARE @v_object_sport INT;

    DECLARE @SCHEDULE TABLE (team_a_name VARCHAR(50), team_b_name VARCHAR(50));

    INSERT INTO @SCHEDULE (team_a_name, team_b_name)
    SELECT A.NAME AS team_a_name, B.NAME AS team_b_name
    FROM TEAM A
    CROSS JOIN TEAM B
    WHERE A.NAME != B.NAME
    ORDER BY NEWID();

    DECLARE schedule_cursor CURSOR FOR
    SELECT team_a_name, team_b_name FROM @SCHEDULE;

    OPEN schedule_cursor;

    FETCH NEXT FROM schedule_cursor INTO @v_team_home_name, @v_team_away_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @v_team_home = TEAM_ID FROM Team WHERE NAME = @v_team_home_name;
        SELECT @v_team_away = TEAM_ID FROM Team WHERE NAME = @v_team_away_name;
        SELECT @v_object_sport = OBJECT_ID FROM SportObject WHERE OWNER_TEAM_ID = @v_team_home;
        
        SELECT @v_match_date = dbo.SCHEDULE_FIND_DATA_FOR_MATCH(@v_team_home_name, @v_team_away_name, @start_season_date);

        EXEC dbo.SCHEDULE_ADD_MATCH @v_team_home, @v_team_away, @v_match_date, @v_object_sport;

        FETCH NEXT FROM schedule_cursor INTO @v_team_home_name, @v_team_away_name;
    END;

    CLOSE schedule_cursor;
    DEALLOCATE schedule_cursor;
END;
GO


-- Procedure to print the schedule
CREATE OR ALTER PROCEDURE SCHEDULE_PRINT_SCHEDULE
AS
BEGIN
    DECLARE @v_match_date DATETIME;
    DECLARE @team_home_name NVARCHAR(50);
    DECLARE @team_away_name NVARCHAR(50);
    DECLARE @sport_object_name NVARCHAR(50);
    DECLARE @v_score_away INT;
    DECLARE @v_score_home INT;

    DECLARE SCHEDULE_CURSOR CURSOR FOR
    SELECT 
        m.match_date,
        th.name AS team_home_name,
        ta.name AS team_away_name,
        so.object_name AS sport_object_name,
        m.score_home,
        m.score_away
    FROM match m
    INNER JOIN Team th ON m.team_home_id = th.team_id
    INNER JOIN Team ta ON m.team_away_id = ta.team_id
    INNER JOIN SportObject so ON m.sport_object_id = so.object_id;

    OPEN SCHEDULE_CURSOR;
    FETCH NEXT FROM SCHEDULE_CURSOR INTO @v_match_date, @team_home_name, @team_away_name, @sport_object_name, @v_score_away, @v_score_home;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @v_score_home = 0 AND @v_score_away = 0
        BEGIN
            PRINT CONVERT(NVARCHAR, @v_match_date, 103) + ' ' + CONVERT(NVARCHAR, @v_match_date, 108) + ' | ' + @team_home_name + ' vs ' + @team_away_name + ' | ' + @sport_object_name + ' | MATCH NOT PLAYED YET';
        END
        ELSE
        BEGIN
            PRINT CONVERT(NVARCHAR, @v_match_date, 103) + ' ' + CONVERT(NVARCHAR, @v_match_date, 108) + ' | ' + @team_home_name + ' vs ' + @team_away_name + ' | ' + CAST(@v_score_home AS NVARCHAR) + ' : ' + CAST(@v_score_away AS NVARCHAR);
        END;

        FETCH NEXT FROM SCHEDULE_CURSOR INTO @v_match_date, @team_home_name, @team_away_name, @sport_object_name, @v_score_away, @v_score_home;
    END

    CLOSE SCHEDULE_CURSOR;
    DEALLOCATE SCHEDULE_CURSOR;
END;
GO
-- Procedure to print matches for a specific team
CREATE OR ALTER PROCEDURE SCHEDULE_PRINT_MATCHES_FOR_TEAM
    @v_team_id INT
AS
BEGIN
    DECLARE @v_match_date DATETIME;
    DECLARE @team_home_name NVARCHAR(50);
    DECLARE @team_away_name NVARCHAR(50);
    DECLARE @sport_object_name NVARCHAR(50);
    DECLARE @v_score_away INT;
    DECLARE @v_score_home INT;

    DECLARE @v_team_ref INT;
    SELECT @v_team_ref = t.team_id FROM Team t WHERE t.team_id = @v_team_id;

    DECLARE SCHEDULE_CURSOR CURSOR FOR
    SELECT 
        m.match_date,
        th.name AS team_home_name,
        ta.name AS team_away_name,
        so.object_name AS sport_object_name,
        m.score_home,
        m.score_away
    FROM match m
    INNER JOIN Team th ON m.team_home_id = th.team_id
    INNER JOIN Team ta ON m.team_away_id = ta.team_id
    INNER JOIN SportObject so ON m.sport_object_id = so.object_id
    WHERE m.team_home_id = @v_team_ref OR m.team_away_id = @v_team_ref;

    OPEN SCHEDULE_CURSOR;
    FETCH NEXT FROM SCHEDULE_CURSOR INTO @v_match_date, @team_home_name, @team_away_name, @sport_object_name, @v_score_away, @v_score_home;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @v_score_home = 0 AND @v_score_away = 0
        BEGIN
            PRINT CONVERT(NVARCHAR, @v_match_date, 103) + ' ' + CONVERT(NVARCHAR, @v_match_date, 108) + ' | ' + @team_home_name + ' vs ' + @team_away_name + ' | ' + @sport_object_name + ' | MATCH NOT PLAYED YET';
        END
        ELSE
        BEGIN
            PRINT CONVERT(NVARCHAR, @v_match_date, 103) + ' ' + CONVERT(NVARCHAR, @v_match_date, 108) + ' | ' + @team_home_name + ' vs ' + @team_away_name + ' | ' + CAST(@v_score_home AS NVARCHAR) + ' : ' + CAST(@v_score_away AS NVARCHAR);
        END;

        FETCH NEXT FROM SCHEDULE_CURSOR INTO @v_match_date, @team_home_name, @team_away_name, @sport_object_name, @v_score_away, @v_score_home;
    END

    CLOSE SCHEDULE_CURSOR;
    DEALLOCATE SCHEDULE_CURSOR;
END;
GO

