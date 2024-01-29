
DROP FUNCTION IF EXISTS  TEAM_CHECK_IF_TEAM_EXISTS;
DROP FUNCTION IF EXISTS TEAM_CHECK_IF_SPONSOR_EXISTS;
DROP FUNCTION IF EXISTS TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR;
DROP FUNCTION IF EXISTS TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM;
DROP FUNCTION IF EXISTS TEAM_CHECK_IF_TEAM_IS_FULL;
DROP PROCEDURE IF EXISTS  TEAM_ADD_TEAM;
DROP PROCEDURE IF EXISTS  TEAM_DELETE_TEAM;
DROP PROCEDURE IF EXISTS  TEAM_CREATE_SPONSOR;
DROP PROCEDURE IF EXISTS  TEAM_ADD_SPONSOR_TO_THE_TEAM;
DROP PROCEDURE IF EXISTS TEAM_ADD_SPORT_OBJECT;
DROP PROCEDURE IF EXISTS TEAM_PRINT_PLAYERS_FROM_TEAM;
DROP PROCEDURE IF EXISTS dbo.TEAM_PRINT_SPONSORS_FROM_TEAM;
GO

----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

--FUNCTION TEAM_CHECK_IF_TEAM_EXISTS;

CREATE FUNCTION dbo.TEAM_CHECK_IF_TEAM_EXISTS ( @checked_team_id INT) 
RETURNS BIT 
AS 
BEGIN
	DECLARE @team_exists BIT;
		IF EXISTS (SELECT 1 FROM TEAM WHERE team_id = @checked_team_id)
			SET @team_exists = 1;
		ELSE
			SET @team_exists = 0;

		RETURN @team_exists;
END;
GO

--FUNCTION TEAM_CHECK_IF_SPONSOR_EXISTS
CREATE FUNCTION dbo.TEAM_CHECK_IF_SPONSOR_EXISTS ( @checked_sponsor_id INT) 
RETURNS BIT 
AS 
BEGIN
	RETURN IIF(EXISTS (SELECT 1 FROM SPONSOR WHERE sponsor_id = @checked_sponsor_id), 1, 0);
END;
GO

--FUNCTION TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR
CREATE FUNCTION dbo.TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR (
    @checked_sponsor_id INT,
    @checked_team_id INT
	)

RETURNS BIT
AS
BEGIN
    DECLARE @sponsor_count INT;
	DECLARE @sponsor_list as NVARCHAR(MAX);
	DECLARE @playerCount INT;
	DECLARE @flag AS BIT;

	SELECT @sponsor_list=sponsors
	FROM team
	WHERE team_id = @checked_team_id;

	--print @sponsor_list;
	SELECT @sponsor_count = COUNT(*)
	FROM OPENJSON(@sponsor_list, '$.sponsors.datas')
	WITH  (
        [id]    int,  
        [last_name]  varchar(60), 
        [first_name]   varchar(6)
    ) where id = @checked_sponsor_id;

	  --print @sponsor_count

    RETURN CASE WHEN @sponsor_count > 0 THEN 1 ELSE 0 END;
END;
GO


--FUNCTION TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM

CREATE FUNCTION dbo.TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM (
    @checked_sponsor_id INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @team_count INT;

    -- Count the number of occurrences where the sponsor is sponsoring a team
    SELECT @team_count = COUNT(*)
    FROM SPONSOR s
    WHERE s.sponsor_id = @checked_sponsor_id
      AND s.TEAM_ID IS NOT NULL;

    -- Return true if there is at least one occurrence
    RETURN CASE WHEN @team_count > 0 THEN 1 ELSE 0 END;
END;
GO

--FUNCTION TEAM_CHECK_IF_TEAM_IS_FULL

CREATE FUNCTION dbo.TEAM_CHECK_IF_TEAM_IS_FULL (@id_team INT)
RETURNS BIT
AS
BEGIN

	DECLARE @players_list as NVARCHAR(MAX);
	DECLARE @playerCount INT;
	DECLARE @flag AS BIT;

	SELECT @players_list=players
	FROM team
	WHERE team_id = @id_team;

	

	SELECT @playerCount=COUNT(*)
	FROM OPENJSON(@players_list, '$.players.datas')
	WITH  (
        [id]    int,  
        [last_name]  varchar(60), 
        [first_name]   varchar(6)
    );

    -- Check if the team is full (assuming the limit is 14 players)
	
    IF @playerCount <= 14
        SET @flag= 0; -- Team is not full
    ELSE
       SET @flag= 1; -- Team is full
   RETURN @flag; 
END;
GO



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURE            -----------------------------------
----------------------------------------------------------------------------------------------



--PROCEDURE ADD_TEAM

CREATE PROCEDURE dbo.TEAM_ADD_TEAM
(
    @team_name VARCHAR(255)
)
AS
BEGIN
INSERT INTO TEAM ( name, wins, loses, win_percentage, points_conceded, points_scored, players, sponsors)
    VALUES ( @team_name, 0, 0, 0, 0, 0, CAST(NULL AS NVARCHAR(MAX)), CAST(NULL AS NVARCHAR(MAX)));

    PRINT 'Successfully added a new team: ' + @team_name;
END;
GO


-- Procedure TEAM_DELETE_TEAM

CREATE PROCEDURE dbo.TEAM_DELETE_TEAM (@delete_team_id INT)
AS
BEGIN
    IF dbo.TEAM_CHECK_IF_TEAM_EXISTS(@delete_team_id) = 0
    BEGIN
        PRINT 'This team does not exist!';
        RETURN;
    END;

    DECLARE @team_name VARCHAR(50);
    SELECT @team_name = name FROM TEAM WHERE team_id = @delete_team_id;

    DELETE FROM TEAM WHERE team_id = @delete_team_id;

    PRINT 'Successfully deleted team: ' + @team_name;
END;
GO


--PROCEDUR TEAM_CREATE_SPONSOR

CREATE PROCEDURE dbo.TEAM_CREATE_SPONSOR
   ( @name VARCHAR(50),
    @amount INT
	)
AS
BEGIN
    INSERT INTO SPONSOR (SPONSOR_NAME, SPONSORSHIP_AMOUNT)
    VALUES (@name, @amount);

    PRINT 'Successfully added new sponsor: ' + @name + ' with the sponsorship amount: ' + CAST(@amount AS VARCHAR);
END;
GO


--PROCEDURE TEAM_ADD_SPONSOR_TO_THE_TEAM

CREATE PROCEDURE dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM(
    @id_sponsor INT,
    @id_team INT
	)
AS
BEGIN
    DECLARE @sponsored_team INT;
    DECLARE @new_sponsor INT;
    DECLARE @name_sponsor VARCHAR(50);
    DECLARE @name_team VARCHAR(50);

    -- Check if the team exists
	DECLARE @team_exists as BIT;
	set @team_exists = dbo.TEAM_CHECK_IF_TEAM_EXISTS(@id_team);
    IF @team_exists = 0
    BEGIN
        PRINT 'Team does not exist!';
        RETURN;
    END;

    -- Check if the sponsor exists
	DECLARE @sponsor_exists as BIT;
	set @sponsor_exists =  dbo.TEAM_CHECK_IF_SPONSOR_EXISTS(@id_team);
    IF @sponsor_exists = 0
    BEGIN
        PRINT 'Sponsor does not exist!';
        RETURN;
    END;

    -- Check if the team already has this sponsor
	DECLARE @is_team_has_the_sponsor as BIT
	set @is_team_has_the_sponsor = dbo.TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR(@id_sponsor,@id_team);
	IF @is_team_has_the_sponsor = 1
    BEGIN
        PRINT 'Team is already sponsored by this sponsor!';
        RETURN;
    END;
 

    -- Check if the sponsor is already sponsoring another team
	DECLARE @is_sponsor_is_sponsoring_another_teams as BIT;
	set @is_sponsor_is_sponsoring_another_teams = dbo.TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM(@id_sponsor);
	if @is_sponsor_is_sponsoring_another_teams =1
    BEGIN
        PRINT 'This sponsor is already sponsoring someone else!';
        RETURN;
    END;

    -- Get the references to the team and sponsor
    SELECT @sponsored_team = t.team_id FROM TEAM t WHERE t.team_id = @id_team;
    SELECT @new_sponsor = s.sponsor_id FROM SPONSOR s WHERE s.sponsor_id = @id_sponsor;

    -- Update the sponsor with the team
    UPDATE SPONSOR SET TEAM_ID = @sponsored_team WHERE sponsor_id = @id_sponsor;

    -- Add the sponsor to the team's sponsors list
	DECLARE @SponsorsData NVARCHAR(MAX);
	DECLARE @sponsor_name VARCHAR(255);

	SELECT @sponsor_name = sponsor_name FROM Sponsor WHERE sponsor_id = @id_sponsor;

	DECLARE @existingData NVARCHAR(MAX);
	SELECT @existingData = ISNULL(SPONSORS, '{"SPONSORS": {"datas": []}}')
	FROM team
	WHERE team_id = @id_team;

	DECLARE @variableData NVARCHAR(MAX);
	SET @variableData = N'{"id": ' + CAST(@id_sponsor AS NVARCHAR(50)) + ',"name": "' + @sponsor_name + '"}';
    
	SET @existingData = JSON_MODIFY(@existingData, 'append $.SPONSORS.datas', JSON_QUERY(@variableData));

	UPDATE team
	SET SPONSORS = @existingData
	WHERE team_id = @id_team;
	--INSERT INTO TEAM_SPONSORS (team_id, sponsor_id) VALUES (@id_team, @id_sponsor);

    -- Get the names for printing
    SELECT @name_sponsor = SPONSOR_NAME FROM SPONSOR WHERE SPONSOR_ID = @id_sponsor;
    SELECT @name_team = NAME FROM TEAM WHERE TEAM_ID = @id_team;

    PRINT 'Successfully added new sponsor: ' + @name_sponsor + ' to: ' + @name_team;
END;
GO



-- --PROCEDURE TEAM_ADD_SPORT_OBJECT


CREATE PROCEDURE dbo.TEAM_ADD_SPORT_OBJECT
    @sport_object_name NVARCHAR(50),
    @owner_team_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Team WHERE team_id = @owner_team_id)
    BEGIN
        PRINT 'Team does not exist!';
        RETURN;
    END;

    DECLARE @owner_team_ref INT;
    SELECT @owner_team_ref = team_id FROM Team WHERE team_id = @owner_team_id;

    INSERT INTO SPORTOBJECT ( OBJECT_NAME, OWNER_TEAM_ID)
    VALUES ( @sport_object_name, @owner_team_ref);

    PRINT 'Successfully added new sport object: ' + @sport_object_name;
END;
GO

-- --PROCEDURE TEAM_ADD_SPORT_OBJECTF

CREATE OR ALTER PROCEDURE dbo.TEAM_PRINT_PLAYERS_FROM_TEAM
    @id_team INT
AS
BEGIN
    DECLARE @players_list as NVARCHAR(MAX);
	DECLARE @playerCount INT;
	DECLARE @flag AS BIT;

	SELECT @players_list=players
	FROM team
	WHERE team_id = @id_team;


	SELECT *
	FROM OPENJSON(@players_list, '$.players.datas')
	WITH  (
        [id]    int,  
        [first_name]  varchar(60),
		[last_name] varchar(60)
        
    ) where id is not null;

END;
GO


-- --PROCEDURE TEAM_PRINT_SPONSORS_FROM_TEAM

CREATE PROCEDURE dbo.TEAM_PRINT_SPONSORS_FROM_TEAM
    @id_team INT
AS
BEGIN
    DECLARE @sponsor_list as NVARCHAR(MAX);
	DECLARE @playerCount INT;
	DECLARE @flag AS BIT;

	SELECT @sponsor_list=sponsors
	FROM team
	WHERE team_id = @id_team;

	

	SELECT *
	FROM OPENJSON(@sponsor_list, '$.SPONSORS.datas')
	WITH  (
        [id]    int,  
        [name]  varchar(60)
        
    ) ;
END;

GO