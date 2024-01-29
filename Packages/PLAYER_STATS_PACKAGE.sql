DROP PROCEDURE IF EXISTS PLAYER_STATS_UPDATE_PLAYER_STATS
DROP PROCEDURE IF EXISTS PLAYER_STATS_ADD_PLAYER_STATS
DROP PROCEDURE IF EXISTS PLAYER_STATS_REMOVE_PLAYER_STATS
DROP PROCEDURE IF EXISTS PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS
DROP PROCEDURE IF EXISTS PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS_FROM_MATCH
DROP PROCEDURE IF EXISTS PLAYER_STATS_DISPLAY_PLAYER_STATS
go
----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

-- Procedure to update player stats
CREATE OR ALTER PROCEDURE dbo.PLAYER_STATS_UPDATE_PLAYER_STATS(
    @s_stats_id INT,
    @p_minutes_played INT,
    @p_two_points_goals INT,
    @p_assists INT,
    @p_blocks INT,
    @p_rebounds INT,
    @p_three_points_goal INT
) AS
BEGIN
    UPDATE dbo.PlayerStats
    SET minutes_played = @p_minutes_played,
        two_points_goals = @p_two_points_goals,
        assists = @p_assists,
        blocks = @p_blocks,
        rebounds = @p_rebounds,
        three_points_goal = @p_three_points_goal
    WHERE stats_id = @s_stats_id;
END;
GO


CREATE OR ALTER PROCEDURE dbo.PLAYER_STATS_ADD_PLAYER_STATS(
    @p_match_id INT,
    @p_player_id INT,
    @p_minutes_played INT,
    @p_two_points_goals INT,
    @p_assists INT,
    @p_blocks INT,
    @p_rebounds INT,
    @p_three_points_goal INT
) AS
BEGIN
    DECLARE @v_player_ref INT;
    DECLARE @v_match_ref INT;

    SELECT @v_player_ref = player_id
    FROM dbo.Player
    WHERE player_id = @p_player_id;

    SELECT @v_match_ref = match_id
    FROM dbo.Match
    WHERE match_id = @p_match_id;

    -- Insert new player stats for the given match
    INSERT INTO dbo.PlayerStats (
        player_id,
        match_id,
        minutes_played,
        two_points_goals,
        assists,
        blocks,
        rebounds,
        three_points_goal
    )
    VALUES (
        @v_player_ref,
        @v_match_ref,
        @p_minutes_played,
        @p_two_points_goals,
        @p_assists,
        @p_blocks,
        @p_rebounds,
        @p_three_points_goal
    );
END;
GO


-- Procedure to remove player stats
CREATE OR ALTER PROCEDURE dbo.PLAYER_STATS_REMOVE_PLAYER_STATS(
    @p_match_id INT,
    @p_player_id INT
) AS
BEGIN
    -- Delete player stats for the given match
    DELETE FROM dbo.PlayerStats
    WHERE player_id = @p_player_id
      AND match_id = @p_match_id;
END;
GO

-- Procedure to display player stats
-- Procedure to display player stats
CREATE OR ALTER PROCEDURE dbo.PLAYER_STATS_DISPLAY_PLAYER_STATS(
    @p_player_id INT
) AS
BEGIN
    DECLARE @v_player_minutes INT;
    DECLARE @v_player_two INT;
    DECLARE @v_player_assists INT;
    DECLARE @v_player_blocks INT;
    DECLARE @v_player_rebounds INT;
    DECLARE @v_player_three INT;
    DECLARE @v_player_first_name NVARCHAR(50);
    DECLARE @v_player_last_name NVARCHAR(50);
    DECLARE @v_match_ref INT;
    DECLARE @v_away_team_ref INT;
    DECLARE @v_home_team_ref INT;
    DECLARE @v_home_team_name NVARCHAR(50);
    DECLARE @v_away_team_name NVARCHAR(50);

    SELECT @v_player_first_name = first_name, @v_player_last_name = last_name
    FROM dbo.PLAYER
    WHERE player_id = @p_player_id;

    PRINT 'STATS FOR: ' + @v_player_first_name + ' ' + @v_player_last_name;

    DECLARE cursor_player_stats CURSOR LOCAL FOR
        SELECT
            p.match_id,
            p.minutes_played,
            p.two_points_goals,
            p.assists,
            p.blocks,
            p.rebounds,
            p.three_points_goal
        FROM dbo.PLAYERSTATS p
        WHERE p.player_id = @p_player_id;

    OPEN cursor_player_stats;

    FETCH NEXT FROM cursor_player_stats INTO @v_match_ref, @v_player_minutes, @v_player_two, @v_player_assists, @v_player_blocks, @v_player_rebounds, @v_player_three;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @v_home_team_ref = team_home_id, @v_away_team_ref = team_away_id
        FROM dbo.Match
        WHERE match_id = @v_match_ref;

        SELECT @v_home_team_name = name
        FROM dbo.Team
        WHERE team_id = @v_home_team_ref;

        SELECT @v_away_team_name = name
        FROM dbo.Team
        WHERE team_id = @v_away_team_ref;

        PRINT @v_home_team_name + ' VS ' + @v_away_team_name +
              ' | MINUTES_PLAYED: ' + CAST(@v_player_minutes AS NVARCHAR) +
              ' TWO_POINTS_GOALS: ' + CAST(@v_player_two AS NVARCHAR) +
              ' ASSISTS: ' + CAST(@v_player_assists AS NVARCHAR) +
              ' BLOCKS: ' + CAST(@v_player_blocks AS NVARCHAR) +
              ' REBOUNDS: ' + CAST(@v_player_rebounds AS NVARCHAR) +
              ' THREE_POINTS_GOALS: ' + CAST(@v_player_three AS NVARCHAR);

        FETCH NEXT FROM cursor_player_stats INTO @v_match_ref, @v_player_minutes, @v_player_two, @v_player_assists, @v_player_blocks, @v_player_rebounds, @v_player_three;
    END;

    CLOSE cursor_player_stats;

    SELECT
        @v_player_minutes = SUM(minutes_played),
        @v_player_two = SUM(two_points_goals),
        @v_player_assists = SUM(assists),
        @v_player_blocks = SUM(blocks),
        @v_player_rebounds = SUM(rebounds),
        @v_player_three = SUM(three_points_goal)
    FROM dbo.PLAYERSTATS
    WHERE player_id = @p_player_id;

    PRINT 'SUM | MINUTES PLAYED: ' + CAST(@v_player_minutes AS NVARCHAR) +
          ' ASSISTS: ' + CAST(@v_player_assists AS NVARCHAR) +
          ' BLOCKS: ' + CAST(@v_player_blocks AS NVARCHAR) +
          ' REBOUNDS: ' + CAST(@v_player_rebounds AS NVARCHAR) +
          ' THREE_POINTS: ' + CAST(@v_player_three AS NVARCHAR) +
          ' TWO_POINTS: ' + CAST(@v_player_two AS NVARCHAR);
END;
GO


-- Procedure to display all player stats
-- Procedure to display all player stats

CREATE OR ALTER PROCEDURE dbo.PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS
AS
BEGIN
    DECLARE cursor_all_player_stats CURSOR LOCAL FOR
        SELECT
            pstats.minutes_played,
            pstats.two_points_goals,
            pstats.assists,
            pstats.blocks,
            pstats.rebounds,
            pstats.three_points_goal,
            player.first_name,
            player.last_name,
            home_team.name AS team_home_name,
            away_team.name AS team_away_name
        FROM dbo.PlayerStats pstats
        INNER JOIN dbo.Player player ON pstats.player_id = player.player_id
        INNER JOIN dbo.Match m ON pstats.match_id = m.match_id
        INNER JOIN dbo.Team home_team ON m.team_home_id = home_team.team_id
        INNER JOIN dbo.Team away_team ON m.team_away_id = away_team.team_id;

    DECLARE @p_first_name NVARCHAR(50);
    DECLARE @p_last_name NVARCHAR(50);
    DECLARE @team_home_name NVARCHAR(50);
    DECLARE @team_away_name NVARCHAR(50);
    DECLARE @s_minutes_played INT;
    DECLARE @s_two_points_goals INT;
    DECLARE @s_assists INT;
    DECLARE @s_blocks INT;
    DECLARE @s_rebounds INT;
    DECLARE @s_three_points_goals INT;

    OPEN cursor_all_player_stats;

    FETCH NEXT FROM cursor_all_player_stats INTO @s_minutes_played, @s_two_points_goals, @s_assists, @s_blocks, @s_rebounds, @s_three_points_goals, @p_first_name, @p_last_name, @team_home_name, @team_away_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Use PRINT instead of DBMS_OUTPUT.PUT_LINE
        PRINT @p_first_name + ' ' + @p_last_name +
              ' | ' + @team_home_name + ' VS ' + @team_away_name +
              ' | Minutes played: ' + CAST(@s_minutes_played AS NVARCHAR) +
              ' Two points goals: ' + CAST(@s_two_points_goals AS NVARCHAR) +
              ' Assists: ' + CAST(@s_assists AS NVARCHAR) +
              ' Blocks: ' + CAST(@s_blocks AS NVARCHAR) +
              ' Rebounds: ' + CAST(@s_rebounds AS NVARCHAR) +
              ' Three points goals: ' + CAST(@s_three_points_goals AS NVARCHAR);

        FETCH NEXT FROM cursor_all_player_stats INTO @s_minutes_played, @s_two_points_goals, @s_assists, @s_blocks, @s_rebounds, @s_three_points_goals, @p_first_name, @p_last_name, @team_home_name, @team_away_name;
    END;

    CLOSE cursor_all_player_stats;
END;
GO


-- Procedure to display all player stats from a match
-- Procedure to display all player stats from a specific match
CREATE OR ALTER PROCEDURE dbo.PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS_FROM_MATCH
    @p_match_id INT
AS
BEGIN
    DECLARE cursor_player_stats_from_match CURSOR  LOCAL FOR
        SELECT
            player.first_name,
            player.last_name,
            home_team.name AS team_home_name,
            away_team.name AS team_away_name,
            pstats.minutes_played,
            pstats.two_points_goals,
            pstats.assists,
            pstats.blocks,
            pstats.rebounds,
            pstats.three_points_goal
        FROM dbo.PlayerStats pstats
        INNER JOIN dbo.Player player ON pstats.player_id = player.player_id
        INNER JOIN dbo.Match m ON pstats.match_id = m.match_id
        INNER JOIN dbo.Team home_team ON m.team_home_id = home_team.team_id
        INNER JOIN dbo.Team away_team ON m.team_away_id = away_team.team_id
        WHERE m.match_id = @p_match_id;

    DECLARE @p_first_name NVARCHAR(50);
    DECLARE @p_last_name NVARCHAR(50);
    DECLARE @team_home_name NVARCHAR(50);
    DECLARE @team_away_name NVARCHAR(50);
    DECLARE @s_minutes_played INT;
    DECLARE @s_two_points_goals INT;
    DECLARE @s_assists INT;
    DECLARE @s_blocks INT;
    DECLARE @s_rebounds INT;
    DECLARE @s_three_points_goals INT;

    OPEN cursor_player_stats_from_match;

    FETCH NEXT FROM cursor_player_stats_from_match INTO @p_first_name, @p_last_name, @team_home_name, @team_away_name, @s_minutes_played, @s_two_points_goals, @s_assists, @s_blocks, @s_rebounds, @s_three_points_goals;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Use PRINT instead of DBMS_OUTPUT.PUT_LINE
        PRINT @p_first_name + ' ' + @p_last_name +
              ' | ' + @team_home_name + ' VS ' + @team_away_name +
              ' | Minutes played: ' + CAST(@s_minutes_played AS NVARCHAR) +
              ' Two points goals: ' + CAST(@s_two_points_goals AS NVARCHAR) +
              ' Assists: ' + CAST(@s_assists AS NVARCHAR) +
              ' Blocks: ' + CAST(@s_blocks AS NVARCHAR) +
              ' Rebounds: ' + CAST(@s_rebounds AS NVARCHAR) +
              ' Three points goals: ' + CAST(@s_three_points_goals AS NVARCHAR);

        FETCH NEXT FROM cursor_player_stats_from_match INTO @p_first_name, @p_last_name, @team_home_name, @team_away_name, @s_minutes_played, @s_two_points_goals, @s_assists, @s_blocks, @s_rebounds, @s_three_points_goals;
    END;

    CLOSE cursor_player_stats_from_match;
END;
GO

