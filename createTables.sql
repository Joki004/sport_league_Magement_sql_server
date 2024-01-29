--Create Database
USE master;
DROP DATABASE IF EXISTS SportLeague;
CREATE DATABASE SportLeague;
USE SportLeague;


ALTER TABLE SportObject DROP CONSTRAINT FK_SportObject_Team;
ALTER TABLE Sponsor DROP CONSTRAINT FK_Sponsor_Team;
ALTER TABLE Player DROP CONSTRAINT FK_Player_Team;
ALTER TABLE Match DROP CONSTRAINT FK_Match_SportObject;
ALTER TABLE Match DROP CONSTRAINT FK_Match_TeamHome;
ALTER TABLE Match DROP CONSTRAINT FK_Match_TeamAway;
ALTER TABLE PlayerStats DROP CONSTRAINT FK_PlayerStats_Player;
ALTER TABLE PlayerStats DROP CONSTRAINT FK_PlayerStats_Match;

DROP TABLE IF EXISTS TEAM;
DROP TABLE IF EXISTS Player;
DROP TABLE IF EXISTS Sponsor;

DROP TABLE IF EXISTS PlayerStats;
DROP TABLE IF EXISTS Match;
DROP TABLE IF EXISTS SportObject;





-- Table: Team
CREATE TABLE Team (
    team_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL, 
    wins INT DEFAULT 0,                   
    loses INT DEFAULT 0,                  
    win_percentage DECIMAL(5,2),
    points_conceded INT DEFAULT 0,        
    points_scored INT DEFAULT 0,          
    players NVARCHAR(MAX)DEFAULT NULL,      
    sponsors NVARCHAR(MAX) DEFAULT NULL,     
    ModifiedDate DATETIME       
        CONSTRAINT DF_Team_ModifiedDate DEFAULT GETDATE(),
    rowguid UNIQUEIDENTIFIER DEFAULT NEWID() 
);

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Table storing information about sports teams.', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'Team';

-- Table: SportObject
CREATE TABLE SportObject (
    object_id INT PRIMARY KEY IDENTITY(1,1),
    object_name VARCHAR(50),
    owner_team_id INT ,
    CONSTRAINT FK_SportObject_Team FOREIGN KEY (owner_team_id) REFERENCES Team(team_id),
    ModifiedDate DATETIME       
        CONSTRAINT DF_SportObject_ModifiedDate DEFAULT GETDATE(),
    rowguid UNIQUEIDENTIFIER DEFAULT NEWID() 
);
-- Add description to SportObject table
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Table storing information about sports objects.', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'SportObject';

-- Table: Sponsor
CREATE TABLE Sponsor (
    sponsor_id INT PRIMARY KEY IDENTITY(1,1),
    sponsor_name VARCHAR(50),
    team_id INT,
    sponsorship_amount INT,
    CONSTRAINT FK_Sponsor_Team FOREIGN KEY (team_id) REFERENCES Team(team_id),
    ModifiedDate DATETIME       
        CONSTRAINT DF_Sponsor_ModifiedDate DEFAULT GETDATE(),
    rowguid UNIQUEIDENTIFIER DEFAULT NEWID() 
);

-- Add description to Sponsor table
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Table storing information about sponsors.', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'Sponsor';

-- Table: Player
CREATE TABLE Player (
    player_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birthdate DATE,
    position VARCHAR(50),
    team_id INT,
    CONSTRAINT FK_Player_Team  FOREIGN KEY (team_id) REFERENCES Team(team_id),
    ModifiedDate DATETIME       
        CONSTRAINT DF_Player_ModifiedDate DEFAULT GETDATE(),
    rowguid UNIQUEIDENTIFIER DEFAULT NEWID() 
);

-- Table: Match
CREATE TABLE Match (
    match_id INT PRIMARY KEY IDENTITY(1,1),
    match_date DATE,
    sport_object_id INT,
    team_home_id INT,
    team_away_id INT,
    score_home INT,
    score_away INT,
    CONSTRAINT FK_Match_SportObject FOREIGN KEY (sport_object_id) REFERENCES SportObject(object_id),
    CONSTRAINT FK_Match_TeamHome FOREIGN KEY (team_home_id) REFERENCES Team(team_id),
    CONSTRAINT FK_Match_TeamAway FOREIGN KEY (team_away_id) REFERENCES Team(team_id),
    ModifiedDate DATETIME       
        CONSTRAINT DF_Match_ModifiedDate DEFAULT GETDATE(),
    rowguid UNIQUEIDENTIFIER DEFAULT NEWID() 
);

-- Add description to Player table
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Table storing information about sports players.', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'Player';


-- Table: PlayerStats
CREATE TABLE PlayerStats (
    stats_id INT PRIMARY KEY IDENTITY(1,1),
    player_id INT,
    match_id INT,
    minutes_played INT,
    two_points_goals INT,
    assists INT,
    blocks INT,
    rebounds INT,
    three_points_goal INT,
    CONSTRAINT FK_PlayerStats_Player FOREIGN KEY (player_id) REFERENCES Player(player_id),
    CONSTRAINT FK_PlayerStats_Match FOREIGN KEY (match_id) REFERENCES Match(match_id),
    ModifiedDate DATETIME       
        CONSTRAINT DF_PlayerStats_ModifiedDate DEFAULT GETDATE(),
    rowguid UNIQUEIDENTIFIER DEFAULT NEWID() 
);

-- Add description to PlayerStats table
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Table storing information about player statistics in matches.', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'PlayerStats';






-- Ch. 4: Database Roles, Permissions, and User Assignment
-- Assuming roles have been created before assigning permissions
CREATE ROLE AdminRole;
CREATE ROLE EmployeeRole;
CREATE ROLE AnonymousCustomerRole;

-- Assign permissions to roles
GRANT CONTROL ON SCHEMA::dbo TO AdminRole;
GRANT EXECUTE ON SCHEMA::dbo TO EmployeeRole;
GRANT SELECT ON SCHEMA::dbo TO AnonymousCustomerRole;

-- Create users and assign roles
CREATE USER AdminUser FOR LOGIN AdminLogin;
CREATE USER EmployeeUser FOR LOGIN EmployeeLogin;
CREATE USER AnonymousCustomerUser FOR LOGIN AnonymousCustomerLogin;

ALTER ROLE AdminRole ADD MEMBER AdminUser;
ALTER ROLE EmployeeRole ADD MEMBER EmployeeUser;
ALTER ROLE AnonymousCustomerRole ADD MEMBER AnonymousCustomerUser;


