USE SportLeague
DROP TRIGGER PLAYER_AGE_CHECK
-- Trigger for PLAYER table
CREATE OR ALTER TRIGGER PLAYER_AGE_CHECK
ON PLAYER
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @v_min_age INT = 18;

    -- Check age before inserting
    IF DATEDIFF(YEAR, (SELECT BIRTHDATE FROM INSERTED), GETDATE()) < @v_min_age
        RAISERROR ('Player must be at least 18 years old!', 16, 1);
    ELSE
  
      
        INSERT INTO PLAYER (first_name, last_name, birthdate, position, team_id, ModifiedDate, rowguid)
        SELECT first_name, last_name, birthdate, position, team_id, GETDATE(), NEWID()
        FROM INSERTED;
END;
GO



-- Trigger for SPONSOR table
CREATE TRIGGER SPONSORSHIP_AMOUNT_CHECK
ON SPONSOR
INSTEAD OF INSERT
AS
BEGIN
    -- Check sponsorship amount before inserting
    IF (SELECT SPONSORSHIP_AMOUNT FROM INSERTED) <= 0
    BEGIN
        RAISERROR('Sponsorship must be bigger than 0!', 16, 2);
    END
    ELSE
    BEGIN
        -- Perform the actual insert
        INSERT INTO SPONSOR (sponsor_name, team_id, sponsorship_amount, ModifiedDate, rowguid)
        SELECT sponsor_name, team_id, sponsorship_amount, GETDATE(), NEWID()
        FROM INSERTED;
    END
END;
GO
-- Trigger for TEAM table
CREATE TRIGGER TEAM_NAME_CHECK
ON TEAM
INSTEAD OF INSERT
AS
BEGIN
    -- Check team name before inserting
    IF (SELECT NAME FROM INSERTED) = ''
    BEGIN
        RAISERROR('Team name can not be empty!', 16, 3);
    END
    ELSE
    BEGIN
        -- Perform the actual insert
        INSERT INTO TEAM (name, wins, loses, win_percentage, points_conceded, points_scored, players, sponsors, ModifiedDate, rowguid)
        SELECT name, wins, loses, win_percentage, points_conceded, points_scored, players, sponsors, GETDATE(), NEWID()
        FROM INSERTED;
    END
END;
GO


-- Create a trigger for Team table
CREATE TRIGGER trg_Team_ModifiedDate
ON dbo.Team
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET t.ModifiedDate = GETDATE()
    FROM dbo.Team t
    JOIN inserted i ON t.team_id = i.team_id;
END;
GO

-- Create a trigger for SportObject table
CREATE TRIGGER trg_SportObject_ModifiedDate
ON dbo.SportObject
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE so
    SET so.ModifiedDate = GETDATE()
    FROM dbo.SportObject so
    JOIN inserted i ON so.object_id = i.object_id;
END;
GO

-- Create a trigger for Sponsor table
CREATE TRIGGER trg_Sponsor_ModifiedDate
ON dbo.Sponsor
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.ModifiedDate = GETDATE()
    FROM dbo.Sponsor s
    JOIN inserted i ON s.sponsor_id = i.sponsor_id;
END;
GO

-- Create a trigger for Player table
CREATE TRIGGER trg_Player_ModifiedDate
ON dbo.Player
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.ModifiedDate = GETDATE()
    FROM dbo.Player p
    JOIN inserted i ON p.player_id = i.player_id;
END;
GO

-- Create a trigger for Match table
CREATE TRIGGER trg_Match_ModifiedDate
ON dbo.Match
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE m
    SET m.ModifiedDate = GETDATE()
    FROM dbo.Match m
    JOIN inserted i ON m.match_id = i.match_id;
END;
GO

-- Create a trigger for PlayerStats table
CREATE TRIGGER trg_PlayerStats_ModifiedDate
ON dbo.PlayerStats
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ps
    SET ps.ModifiedDate = GETDATE()
    FROM dbo.PlayerStats ps
    JOIN inserted i ON ps.stats_id = i.stats_id;
END;
GO
