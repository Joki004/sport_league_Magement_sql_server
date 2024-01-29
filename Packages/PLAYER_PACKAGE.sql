DROP PROCEDURE IF EXISTS PLAYER_CHECK_IF_PLAYER_EXISTS;
DROP PROCEDURE IF EXISTS PLAYER_TRANSFER_PLAYER;
DROP PROCEDURE IF EXISTS PLAYER_ADD_PLAYER
DROP PROCEDURE IF EXISTS PLAYER_REMOVE_PLAYER_FROM_TEAM;
GO
----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

-- Create PROCEDURE PLAYER_CHECK_IF_PLAYER_EXISTS
CREATE OR ALTER PROCEDURE dbo.PLAYER_CHECK_IF_PLAYER_EXISTS
    @checked_player_id INT,
    @player_exists BIT OUTPUT
AS
BEGIN
    SET @player_exists = 0;

    SELECT @player_exists = COUNT(*)
    FROM Player p
    WHERE p.player_id = @checked_player_id;

    IF @player_exists = 0
        SET @player_exists = 0;
    ELSE
        SET @player_exists = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.PLAYER_REMOVE_PLAYER_FROM_TEAM
    @id_player INT
AS
BEGIN
    DECLARE @old_team INT;
    DECLARE @old_team_name VARCHAR(50);
    DECLARE @old_team_id INT;
    DECLARE @player_first_name VARCHAR(50);
    DECLARE @player_last_name VARCHAR(50);
    DECLARE @players_list as NVARCHAR(MAX);
    DECLARE @choosen_player_id INT;

    -- Check if player exists
    EXEC dbo.PLAYER_CHECK_IF_PLAYER_EXISTS @id_player, @old_team OUTPUT;

    IF @old_team = 0
    BEGIN
        PRINT 'Player does not exist';
        RETURN;
    END;

    -- Get old team reference
    SELECT @old_team = TEAM_ID
    FROM Player
    WHERE PLAYER_ID = @id_player;

    -- If player is already a free player
    IF @old_team IS NULL
    BEGIN
        PRINT 'This player is already a free player!';
        RETURN;
    END;

    -- Update player to be free agent
    UPDATE Player
    SET TEAM_ID = NULL
    WHERE PLAYER_ID = @id_player;

    -- Get player information
    SELECT @player_first_name = FIRST_NAME,
           @player_last_name = LAST_NAME
    FROM Player
    WHERE PLAYER_ID = @id_player;

    -- Get old team name and id
    SELECT @old_team_name = NAME,
           @old_team_id = TEAM_ID
    FROM Team
    WHERE TEAM_ID = @old_team;

    -- Get player list from old team
    SELECT @players_list=players
	FROM team
	WHERE team_id =  @old_team_id;

    -- Iterate through player list to find and remove player
	DECLARE @playerToRemove INT = @id_player;
	DECLARE @new_list AS VARCHAR(MAX);
	DECLARE @index INT;
	DECLARE @counter INT = 0;

	-- Find the index of the player to remove
	SELECT @index = [key]
	FROM OPENJSON(@players_list, '$.players.datas')
	WHERE JSON_VALUE([value], '$.id') = CAST(@playerToRemove AS NVARCHAR(50));

-- Remove the player with the specified id
SET @players_list = JSON_MODIFY(@players_list, '$.players.datas[' + CAST(@index AS NVARCHAR(10)) + ']', NULL);

    -- Update old team with modified player list
    UPDATE Team
    SET players = @players_list
    WHERE TEAM_ID = @old_team_id;

    PRINT 'Successfully removed player: ' + @player_first_name + ' ' + @player_last_name + ' from team: ' + @old_team_name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.PLAYER_TRANSFER_PLAYER
    @id_player INT,
    @new_team_id INT
AS
BEGIN
    DECLARE @player_exists BIT;
    DECLARE @new_team_exists_flag BIT;
    DECLARE @old_team INT;
    DECLARE @new_team INT;
    DECLARE @old_team_name VARCHAR(50);
    DECLARE @new_team_name VARCHAR(50);
    DECLARE @old_team_id INT;
    DECLARE @player_first_name VARCHAR(50);
    DECLARE @player_last_name VARCHAR(50);
    DECLARE @existingData NVARCHAR(MAX);

    -- Check if player exists
    EXEC dbo.PLAYER_CHECK_IF_PLAYER_EXISTS @id_player, @player_exists OUTPUT;

    IF @player_exists = 0
    BEGIN
        PRINT 'Error: Player does not exist';
        RETURN;
    END;

    -- Check if team exists
    SET @new_team_exists_flag = dbo.TEAM_CHECK_IF_TEAM_EXISTS(@new_team_id);

    IF @new_team_exists_flag = 0
    BEGIN
        PRINT 'Error: Team does not exist!';
        RETURN;
    END;

    -- Get old team reference
    SELECT @old_team = TEAM_ID
    FROM Player p
    WHERE p.Player_id = @id_player;

    -- Get new team reference
    SELECT @new_team = TEAM_ID
    FROM Team t
    WHERE t.TEAM_ID = @new_team_id;

    -- Check if the player is being transferred to the same team
    IF @old_team = @new_team
    BEGIN
        PRINT 'Error: Player is already a member of the selected team.';
        RETURN;
    END;

    -- Get old team name and id
    SELECT @old_team_name = NAME, @old_team_id = TEAM_ID
    FROM Team t
    WHERE t.TEAM_ID = @old_team;

    -- If old team is not NULL, remove player from old team
    IF @old_team IS NOT NULL
    BEGIN
        -- Remove player from the old team
        EXEC dbo.PLAYER_REMOVE_PLAYER_FROM_TEAM @id_player;
    END;

    -- Update player with new team
    UPDATE Player
    SET TEAM_ID = @new_team
    WHERE PLAYER_ID = @id_player;

    -- Get player information
    SELECT @player_first_name = FIRST_NAME,
           @player_last_name = LAST_NAME
    FROM Player p
    WHERE p.PLAYER_ID = @id_player;

    -- Get new team name
    SELECT @new_team_name = NAME
    FROM Team t
    WHERE t.TEAM_ID = @new_team_id;

    -- Get existing player data for the new team
    SELECT @existingData = ISNULL(players, '{"players": {"datas": []}}')
    FROM Team
    WHERE team_id = @new_team_id;

    -- Append the transferred player to the existing player data
    SET @existingData = JSON_MODIFY(@existingData, 'append $.players.datas', JSON_QUERY(
        N'{"id": ' + CAST(@id_player AS NVARCHAR(50)) +
        N',"first_name": "' + @player_first_name +
        N'", "last_name": "' + @player_last_name + N'"}'
    ));

    -- Update team with modified player list
    UPDATE Team
    SET players = @existingData
    WHERE team_id = @new_team_id;

    PRINT 'Successfully transferred player: ' + @player_first_name + ' ' + @player_last_name +
          ' from: ' + @old_team_name + ' to: ' + @new_team_name;
END;
GO


--CREATE PROCEDURE PLAYER_ADD_PLAYER
CREATE PROCEDURE dbo.PLAYER_ADD_PLAYER
    @player_datebirth DATE,
    @player_first_name VARCHAR(50),
    @player_last_name VARCHAR(50),
    @player_position VARCHAR(50),
    @player_team_id INT
AS
BEGIN
    DECLARE @player_team_ref INT;
    DECLARE @player_list XML;
    DECLARE @new_player INT;
    DECLARE @team_full BIT = 0;
	DECLARE @newPlayerId INT;
	DECLARE @existingData NVARCHAR(MAX);
	DECLARE @variableData NVARCHAR(MAX);
	DECLARE @player_id_add INT;
    -- Check if team exists
    SET @player_team_ref =  dbo.TEAM_CHECK_IF_TEAM_EXISTS(@player_team_id);

    IF @player_team_ref = 0
    BEGIN
        PRINT 'Error: Team does not exist!';
        RETURN;
    END;

    -- Check if team is full
    SET @team_full =  dbo.TEAM_CHECK_IF_TEAM_IS_FULL( @player_team_id);

    IF @team_full = 1
    BEGIN
        PRINT 'Team has too many players!';
        RETURN;
    END;

    -- Get team reference
    SELECT @player_team_ref = TEAM_ID
    FROM Team
    WHERE TEAM_ID = @player_team_id;

    -- Insert new player
    INSERT INTO PLAYER ( FIRST_NAME, LAST_NAME, BIRTHDATE, POSITION, TEAM_ID)
    VALUES ( @player_first_name, @player_last_name, @player_datebirth, @player_position, @player_team_ref);

    -- Get player list from team
    SELECT @player_list = players
    FROM Team
    WHERE TEAM_ID = @player_team_ref;

    -- Get reference to new player
    SELECT @new_player = PLAYER_ID
    FROM Player
    WHERE PLAYER_ID =  SCOPE_IDENTITY();

    -- Append new player to player list
    
	
	SELECT @existingData = ISNULL(players, '{"players": {"datas": []}}')
	FROM team
	WHERE team_id=@player_team_ref;

	SELECT @player_id_add=player_id
	FROM PLAYER
	WHERE FIRST_NAME = @player_first_name
	AND LAST_NAME = @player_last_name
	AND BIRTHDATE = @player_datebirth
	AND POSITION = @player_position
	AND TEAM_ID = @player_team_ref;

	SELECT @variableData = N'{"id": ' + CAST(player_id AS NVARCHAR(50)) + ',"first_name": "' + first_name + '", "last_name": "' + last_name + '"}'
	FROM player where player_id=@player_id_add;

	SET @existingData = JSON_MODIFY(@existingData, 'append $.players.datas', JSON_QUERY(@variableData));

	-- Print the updated data
	PRINT @existingData;
    -- Update team with modified player list
    UPDATE team
	SET players = @existingData
	WHERE team_id=@player_team_ref;


    -- Print with explicit conversion to NVARCHAR(MAX)
   PRINT 'Successfully added new player: ' + CONVERT(NVARCHAR(MAX), @player_first_name) + ' ' + CONVERT(NVARCHAR(MAX), @player_last_name);
END;
GO



