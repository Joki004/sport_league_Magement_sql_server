DROP FUNCTION IF EXISTS MATCH_GET_TEAM_RANKING
DROP FUNCTION IF EXISTS MATCH_GET_MATCH_ID
DROP PROCEDURE IF EXISTS MATCH_UPDATE_SCORE_WITH__TEAMS
DROP PROCEDURE IF EXISTS MATCH_UPDATE_SCORE_WITH_MATCH_ID
DROP PROCEDURE IF EXISTS MATCH_UPDATE_TEAM_STATS
DROP PROCEDURE IF EXISTS MATCH_UPDATE_TEAM_RANKING
DROP PROCEDURE IF EXISTS MATCH_DISPLAY_TEAM_RANKING
GO
----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------
-- Function to get team ranking
CREATE OR ALTER FUNCTION MATCH_GET_TEAM_RANKING()
RETURNS @Result TABLE (
    team_id INT,
    name VARCHAR(50),
    wins INT,
    loses INT,
    win_percentage FLOAT,
    team_rank INT
)
AS
BEGIN
    INSERT INTO @Result
    SELECT
        team_id,
        name,
        wins,
        loses,
        win_percentage,
        RANK() OVER (ORDER BY wins DESC, win_percentage DESC) AS team_rank
    FROM team;

    RETURN;
END;
GO

-- Function to get match ID
CREATE OR ALTER FUNCTION MATCH_GET_MATCH_ID
(
    @p_match_date DATE,
    @p_sport_object_name NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @v_match_id INT;

    SELECT TOP 1
        @v_match_id = m.match_id
    FROM
        [MATCH] m
    JOIN
        SportObject s ON s.object_id = m.sport_object_id  -- Assuming sport_object_id is a foreign key
    WHERE
        m.match_date = @p_match_date
        AND s.object_name = @p_sport_object_name;

    RETURN @v_match_id;
END;
GO

----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

-- Procedure to update team stats
CREATE OR ALTER PROCEDURE MATCH_UPDATE_TEAM_STATS
    @p_match_date DATE,
    @p_sport_object_name NVARCHAR(50)
AS
BEGIN
    DECLARE @v_match_id INT;
    DECLARE @v_team_home_id INT;
    DECLARE @v_team_away_id INT;
    DECLARE @v_score_home INT;
    DECLARE @v_score_away INT;
    DECLARE @v_wins_home INT;
    DECLARE @v_loses_home INT;
    DECLARE @v_win_percentage_home FLOAT;
    DECLARE @v_points_conceded_home INT;
    DECLARE @v_points_scored_home INT;
    DECLARE @v_wins_away INT;
    DECLARE @v_loses_away INT;
    DECLARE @v_win_percentage_away FLOAT;
    DECLARE @v_points_conceded_away INT;
    DECLARE @v_points_scored_away INT;

    -- Step a: Get the match ID
    SET @v_match_id = dbo.MATCH_GET_MATCH_ID(@p_match_date, @p_sport_object_name);

    -- Step b: Check if points scored and conceded are not 0
    SELECT @v_score_home = m.score_home,
           @v_score_away = m.score_away
    FROM match m
    WHERE m.match_id = @v_match_id;

    IF @v_score_home = 0 AND @v_score_away = 0
    BEGIN
        PRINT 'Points scored and conceded are both 0. No update needed.';
        RETURN;
    END;

    -- Step c: Update team stats for the home team
    SELECT TOP 1
        @v_team_home_id = t.team_id,
        @v_wins_home = t.wins,
        @v_loses_home = t.loses,
        @v_win_percentage_home = t.win_percentage,
        @v_points_conceded_home = t.points_conceded,
        @v_points_scored_home = t.points_scored
    FROM team t
    INNER JOIN match m ON t.team_id = m.team_home_id
    WHERE m.match_id = @v_match_id;

    IF @v_score_home > @v_score_away
    BEGIN
        -- Home team wins
        UPDATE team
        SET wins = wins + 1,
            points_scored = points_scored + @v_score_home,
            points_conceded = points_conceded + @v_score_away
        WHERE team_id = @v_team_home_id;
    END
    ELSE
    BEGIN
        -- Home team loses
        UPDATE team
        SET loses = loses + 1,
            points_scored = points_scored + @v_score_home,
            points_conceded = points_conceded + @v_score_away
        WHERE team_id = @v_team_home_id;
    END;

    -- Step d: Update team stats for the away team
    SELECT TOP 1
        @v_team_away_id = t.team_id,
        @v_wins_away = t.wins,
        @v_loses_away = t.loses,
        @v_win_percentage_away = t.win_percentage,
        @v_points_conceded_away = t.points_conceded,
        @v_points_scored_away = t.points_scored
    FROM team t
    INNER JOIN match m ON t.team_id = m.team_away_id
    WHERE m.match_id = @v_match_id;

    IF @v_score_away > @v_score_home
    BEGIN
        -- Away team wins
        UPDATE team
        SET wins = wins + 1,
            points_scored = points_scored + @v_score_away,
            points_conceded = points_conceded + @v_score_home
        WHERE team_id = @v_team_away_id;
    END
    ELSE
    BEGIN
        -- Away team loses
        UPDATE team
        SET loses = loses + 1,
            points_scored = points_scored + @v_score_away,
            points_conceded = points_conceded + @v_score_home
        WHERE team_id = @v_team_away_id;
    END;

    --PRINT 'Team stats updated successfully.';
    -- Consider using RAISEERROR or returning a result code instead of PRINT
END;
GO

-- Procedure to update score with match ID
CREATE OR ALTER PROCEDURE MATCH_UPDATE_SCORE_WITH_MATCH_ID
    @m_match_id INT,
    @p_score_home INT,
    @p_score_away INT
AS
BEGIN
    DECLARE @v_score_home INT;
    DECLARE @v_score_away INT;
    DECLARE @v_arena NVARCHAR(50);
    DECLARE @v_date DATE;
    DECLARE @v_team_home INT;
    DECLARE @v_team_away INT;
    DECLARE @v_players NVARCHAR(MAX);  -- Assuming 'players' is a JSON-formatted string
    DECLARE @v_player_id INT;

    -- Step 1: Retrieve necessary data
    SELECT
        @v_date = m.match_date,
        @v_arena = so.object_name,
        @v_team_home = m.TEAM_HOME_ID,
        @v_team_away = m.TEAM_AWAY_ID,
        @v_players = t.players
    FROM
        [MATCH] m
    INNER JOIN
        SportObject so ON m.sport_object_id = so.object_id
    INNER JOIN
        Team t ON m.TEAM_HOME_ID = t.team_id
    WHERE
        m.match_id = @m_match_id;

    PRINT CONVERT(NVARCHAR, @v_date) + ' ' + CONVERT(NVARCHAR, @p_score_home);

    -- Step 2: Update match scores
    UPDATE [MATCH]
    SET
        score_home = @p_score_home,
        score_away = @p_score_away
    WHERE
        match_id = @m_match_id;

    -- Step 3: Process players JSON
	DECLARE @jsonPlayers TABLE
	(
		[id] INT,
		[last_name] VARCHAR(60),
		[first_name] VARCHAR(60)
	);

	INSERT INTO @jsonPlayers
	SELECT 
		[id],
		[last_name],
		[first_name]
	FROM OPENJSON(@v_players, '$.players.datas')
	WITH  
	(
    [id] INT,  
    [last_name] VARCHAR(60), 
    [first_name] VARCHAR(60)
	);
	SELECT
        @v_date = m.match_date,
        @v_arena = so.object_name,
        @v_team_home = m.TEAM_HOME_ID,
        @v_team_away = m.TEAM_AWAY_ID,
        @v_players = t.players
    FROM
        [MATCH] m
    INNER JOIN
        SportObject so ON m.sport_object_id = so.object_id
    INNER JOIN
        Team t ON m.TEAM_AWAY_ID = t.team_id
    WHERE
        m.match_id = @m_match_id;
	INSERT INTO @jsonPlayers
	SELECT 
    [id],
    [last_name],
    [first_name]
	FROM OPENJSON(@v_players, '$.players.datas')
	WITH  
	(
		[id] INT,  
		[last_name] VARCHAR(60), 
		[first_name] VARCHAR(60)
	);
    -- Iterate over players
	DECLARE @id INT;
	DECLARE @last_name VARCHAR(60);
	DECLARE @first_name VARCHAR(60);

	DECLARE player_cursor CURSOR FOR
	SELECT [id], [last_name], [first_name]
	FROM @jsonPlayers;

	OPEN player_cursor;

	FETCH NEXT FROM player_cursor INTO @id, @last_name, @first_name;

	WHILE @@FETCH_STATUS = 0
	BEGIN
    -- Do something with the current record
    PRINT 'ID: ' + CAST(@id AS VARCHAR(10)) + ', Last Name: ' + @last_name + ', First Name: ' + @first_name;
	EXEC dbo.PLAYER_STATS_ADD_PLAYER_STATS @m_match_id, @id, 0, 0, 0, 0, 0, 0;
    -- Fetch the next record
    FETCH NEXT FROM player_cursor INTO @id, @last_name, @first_name;
	END

	CLOSE player_cursor;
	DEALLOCATE player_cursor;

	

    -- Step 4: Update team stats
    EXEC dbo.MATCH_UPDATE_TEAM_STATS @v_date, @v_arena;

    PRINT 'Team stats updated successfully.';
END;
GO


-- Procedure to update score with teams
CREATE OR ALTER PROCEDURE MATCH_UPDATE_SCORE_WITH__TEAMS
    @date_match DATE,
    @home_team NVARCHAR(50),
    @away_team NVARCHAR(50),
    @score_home INT,
    @score_away INT
AS
BEGIN
    UPDATE [MATCH]
    SET
        score_home = @score_home,
        score_away = @score_away
    WHERE
        match_date = @date_match
        AND TEAM_HOME_ID = (SELECT TEAM_ID FROM Team WHERE NAME = @home_team)
        AND TEAM_AWAY_ID = (SELECT TEAM_ID FROM Team WHERE NAME = @away_team);
END;
GO

-- Procedure to display team ranking

CREATE OR ALTER PROCEDURE MATCH_UPDATE_TEAM_RANKING
AS
BEGIN
    -- Close the cursor if it's already open
        IF CURSOR_STATUS('global', 'team_cursor_update') >= 0
    BEGIN
        CLOSE team_cursor_update;
        DEALLOCATE team_cursor_update;
    END;

    -- Open a cursor to fetch team data ordered by win percentage
    DECLARE team_cursor_update CURSOR LOCAL  FOR
        SELECT
            team_id,
            wins,
            loses
        FROM team;

    -- Declare variables for cursor fetch
    DECLARE @v_team_id INT;
    DECLARE @v_wins INT;
    DECLARE @v_loses INT;
    DECLARE @v_win_percentage FLOAT;

    -- Open the cursor
    OPEN team_cursor_update;

    -- Fetch data from the cursor
    FETCH NEXT FROM team_cursor_update INTO @v_team_id, @v_wins, @v_loses;

    -- Process the fetched data
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calculate win percentage
        SET @v_win_percentage = ROUND(CASE WHEN (@v_wins + @v_loses) > 0 THEN CAST(@v_wins AS FLOAT) / CAST((@v_wins + @v_loses) AS FLOAT) ELSE 0 END, 3);

        -- Update team with win percentage
        UPDATE team
        SET win_percentage = @v_win_percentage
        WHERE team_id = @v_team_id;

        -- Fetch the next row
        FETCH NEXT FROM team_cursor_update INTO @v_team_id, @v_wins, @v_loses;
    END;

    -- Close the cursor
    CLOSE team_cursor_update;
    DEALLOCATE team_cursor_update;
END;
GO

CREATE OR ALTER PROCEDURE MATCH_DISPLAY_TEAM_RANKING
AS
BEGIN
    EXEC dbo.MATCH_UPDATE_TEAM_RANKING;

    -- Open a cursor to fetch team data ordered by win percentage
   DECLARE team_cursor_display CURSOR LOCAL  FOR
        SELECT
            team_id,
            name,
            wins,
            loses,
            win_percentage
        FROM
            (
                SELECT
                    team_id,
                    name,
                    wins,
                    loses,
                    win_percentage,
                    RANK() OVER (ORDER BY wins DESC, win_percentage DESC) AS team_rank
                FROM
                    Team
            ) t
        ORDER BY
            team_rank ASC;

    PRINT '-------------------------------------------------------------------';
    PRINT 'Ranking | Name                  | Wins | Loses | Win Percentage';
    PRINT '-------------------------------------------------------------------';

    DECLARE @v_team_id INT;
    DECLARE @v_name NVARCHAR(50);
    DECLARE @v_wins INT;
    DECLARE @v_loses INT;
    DECLARE @v_win_percentage DECIMAL(10, 3);

    OPEN team_cursor_display;
    FETCH NEXT FROM team_cursor_display INTO @v_team_id, @v_name, @v_wins, @v_loses, @v_win_percentage;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT RIGHT(' ' + CONVERT(NVARCHAR, @v_team_id), 8)
            + ' | ' + RIGHT(' ' + @v_name, 20)
            + ' | ' + RIGHT(' ' + CONVERT(NVARCHAR, @v_wins), 4)
            + ' | ' + RIGHT(' ' + CONVERT(NVARCHAR, @v_loses), 5)
            + ' | ' + CONVERT(NVARCHAR, @v_win_percentage, 3);

        FETCH NEXT FROM team_cursor_display INTO @v_team_id, @v_name, @v_wins, @v_loses, @v_win_percentage;
    END;

    CLOSE team_cursor_display;
END;
GO




