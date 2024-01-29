USE SportLeague

SELECT 
    constraint_name, 
    table_name
FROM 
    information_schema.table_constraints
WHERE 
    constraint_type = 'FOREIGN KEY' AND
    table_name IN ('Player', 'Sponsor', 'PlayerStats','TEAM','Match','SportObject');


	-- Inserting data into Team table
INSERT INTO Team (name, wins, loses, win_percentage, points_conceded, points_scored, players, sponsors)
VALUES
    ('Team A', 10, 5, 66.67, 100, 150, N'["Player1", "Player2"]', N'["Sponsor1", "Sponsor2"]'),
    ('Team B', 8, 7, 53.33, 120, 130, N'["Player3", "Player4"]', N'["Sponsor3", "Sponsor4"]'),
    ('Team C', 12, 3, 80.00, 80, 200, N'["Player5", "Player6"]', N'["Sponsor5", "Sponsor6"]');

insert into player (first_name,last_name)
values
('joram2','mumb')

	DECLARE @player_list XML;
	SELECT @player_list = players
    FROM Team
    WHERE TEAM_ID = 6;
	SELECT CAST(@player_list AS NVARCHAR(MAX)) AS PlayerList;
	SELECT @player_list.query('ArrayOfPlayerType/PlayerType[1]') AS FirstPlayer;


select * from Team;
select * from Sponsor;
select * from Player;
SELECT * FROM SportObject;
SELECT * FROM MATCH;
SELECT * FROM PLAYERsTATS
SELECT MATCH_ID, MATCH_DATE = FORMAT(MATCH_DATE, 'yyyy-MM-dd HH:mm:ss'), SPORT_OBJECT_ID, TEAM_HOME_ID, TEAM_AWAY_ID, SCORE_HOME, SCORE_AWAY
FROM MATCH;

  DECLARE @is_team_has_the_sponsor as BIT
	set @is_team_has_the_sponsor = dbo.TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR(1,1);
	IF @is_team_has_the_sponsor = 1
    BEGIN
        PRINT 'Team is already sponsored by this sponsor!';
        RETURN;
    END;


	DECLARE @matchId AS BIT
SET @matchId = dbo.MATCH_GET_MATCH_ID('2024-01-29 00:00:00', 'Barclays Center');
PRINT @matchId


DECLARE or al@json NVARCHAR(4000) = N'{ 
    "players" : {
            "datas" : [
            { "id" : 1, "first_name" : "Fluffy", "last_name" : "Mumb" },
            { "id" : 2, "first_name" : "john", "last_name" : "cena" },
			{ "id" : 3, "first_name" : "shawn", "last_name" : "mike" },
        ],     
    }
}';


	DECLARE @sponsor_list as NVARCHAR(MAX);
	DECLARE @playerCount INT;
	DECLARE @flag AS BIT;

	SELECT @sponsor_list=players
	FROM team
	WHERE team_id = 2;

	PRINT @sponsor_list

	SELECT *
	FROM OPENJSON(@sponsor_list, '$.players.datas')
	WITH  (
        [id]    int,  
        [first_name]  varchar(60),
		[last_name] varchar(60)
        
    ) where id is not null;




	 DECLARE @v_score_home INT;
    DECLARE @v_score_away INT;
    DECLARE @v_arena NVARCHAR(50);
    DECLARE @v_date DATE;
    DECLARE @v_team_home INT;
    DECLARE @v_team_away INT;
    DECLARE @v_players NVARCHAR(MAX);  -- Assuming 'players' is a JSON-formatted string
    DECLARE @v_player_id INT;

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
        m.match_id = 1;
		--PRINT @v_players
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
        m.match_id = 1;
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
select * from @jsonPlayers
		




