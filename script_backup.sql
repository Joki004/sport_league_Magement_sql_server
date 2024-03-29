USE [master]
GO
/****** Object:  Database [SportLeague]    Script Date: 1/30/2024 12:46:38 AM ******/
CREATE DATABASE [SportLeague]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'SportLeague', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SportLeague.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'SportLeague_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SportLeague_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [SportLeague] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [SportLeague].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [SportLeague] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SportLeague] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SportLeague] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SportLeague] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SportLeague] SET ARITHABORT OFF 
GO
ALTER DATABASE [SportLeague] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [SportLeague] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SportLeague] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SportLeague] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SportLeague] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SportLeague] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SportLeague] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SportLeague] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SportLeague] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SportLeague] SET  ENABLE_BROKER 
GO
ALTER DATABASE [SportLeague] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SportLeague] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SportLeague] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [SportLeague] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [SportLeague] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SportLeague] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [SportLeague] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [SportLeague] SET RECOVERY FULL 
GO
ALTER DATABASE [SportLeague] SET  MULTI_USER 
GO
ALTER DATABASE [SportLeague] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [SportLeague] SET DB_CHAINING OFF 
GO
ALTER DATABASE [SportLeague] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [SportLeague] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [SportLeague] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [SportLeague] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'SportLeague', N'ON'
GO
ALTER DATABASE [SportLeague] SET QUERY_STORE = OFF
GO
USE [SportLeague]
GO
/****** Object:  User [YourUser]    Script Date: 1/30/2024 12:46:38 AM ******/
CREATE USER [YourUser] FOR LOGIN [UserLogin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  DatabaseRole [UserRole]    Script Date: 1/30/2024 12:46:38 AM ******/
CREATE ROLE [UserRole]
GO
/****** Object:  DatabaseRole [admin]    Script Date: 1/30/2024 12:46:38 AM ******/
CREATE ROLE [admin]
GO
ALTER ROLE [UserRole] ADD MEMBER [YourUser]
GO
ALTER ROLE [db_owner] ADD MEMBER [admin]
GO
/****** Object:  UserDefinedFunction [dbo].[MATCH_GET_MATCH_ID]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Function to get match ID
CREATE   FUNCTION [dbo].[MATCH_GET_MATCH_ID]
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
/****** Object:  UserDefinedFunction [dbo].[MATCH_GET_TEAM_RANKING]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------
-- Function to get team ranking
CREATE   FUNCTION [dbo].[MATCH_GET_TEAM_RANKING]()
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
/****** Object:  UserDefinedFunction [dbo].[SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------
-- CREATE FUNCTION SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED
CREATE   FUNCTION [dbo].[SCHEDULE_CHECK_IF_DATA_IS_OCCUPIED] (
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
/****** Object:  UserDefinedFunction [dbo].[SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- CREATE FUNCTION SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH
CREATE FUNCTION [dbo].[SCHEDULE_CHECK_IF_READY_FOR_NEXT_MATCH] (
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
/****** Object:  UserDefinedFunction [dbo].[SCHEDULE_FIND_DATA_FOR_MATCH]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- CREATE FUNCTION SCHEDULE_FIND_DATA_FOR_MATCH
CREATE FUNCTION [dbo].[SCHEDULE_FIND_DATA_FOR_MATCH] (
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
/****** Object:  UserDefinedFunction [dbo].[TEAM_CHECK_IF_SPONSOR_EXISTS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--FUNCTION TEAM_CHECK_IF_SPONSOR_EXISTS
CREATE FUNCTION [dbo].[TEAM_CHECK_IF_SPONSOR_EXISTS] ( @checked_sponsor_id INT) 
RETURNS BIT 
AS 
BEGIN
	RETURN IIF(EXISTS (SELECT 1 FROM SPONSOR WHERE sponsor_id = @checked_sponsor_id), 1, 0);
END;
GO
/****** Object:  UserDefinedFunction [dbo].[TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--FUNCTION TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM

CREATE FUNCTION [dbo].[TEAM_CHECK_IF_SPONSOR_IS_SPONSORING_ANOTHER_TEAM] (
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
/****** Object:  UserDefinedFunction [dbo].[TEAM_CHECK_IF_TEAM_EXISTS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

--FUNCTION TEAM_CHECK_IF_TEAM_EXISTS;

CREATE FUNCTION [dbo].[TEAM_CHECK_IF_TEAM_EXISTS] ( @checked_team_id INT) 
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
/****** Object:  UserDefinedFunction [dbo].[TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--FUNCTION TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR
CREATE FUNCTION [dbo].[TEAM_CHECK_IF_TEAM_HAS_ALREADY_THIS_SPONSOR] (
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
/****** Object:  UserDefinedFunction [dbo].[TEAM_CHECK_IF_TEAM_IS_FULL]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--FUNCTION TEAM_CHECK_IF_TEAM_IS_FULL

CREATE FUNCTION [dbo].[TEAM_CHECK_IF_TEAM_IS_FULL] (@id_team INT)
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
/****** Object:  Table [dbo].[Match]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Match](
	[match_id] [int] IDENTITY(1,1) NOT NULL,
	[match_date] [date] NULL,
	[sport_object_id] [int] NULL,
	[team_home_id] [int] NULL,
	[team_away_id] [int] NULL,
	[score_home] [int] NULL,
	[score_away] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] NULL,
PRIMARY KEY CLUSTERED 
(
	[match_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Player]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Player](
	[player_id] [int] IDENTITY(1,1) NOT NULL,
	[first_name] [varchar](50) NULL,
	[last_name] [varchar](50) NULL,
	[birthdate] [date] NULL,
	[position] [varchar](50) NULL,
	[team_id] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] NULL,
PRIMARY KEY CLUSTERED 
(
	[player_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PlayerStats]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlayerStats](
	[stats_id] [int] IDENTITY(1,1) NOT NULL,
	[player_id] [int] NULL,
	[match_id] [int] NULL,
	[minutes_played] [int] NULL,
	[two_points_goals] [int] NULL,
	[assists] [int] NULL,
	[blocks] [int] NULL,
	[rebounds] [int] NULL,
	[three_points_goal] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] NULL,
PRIMARY KEY CLUSTERED 
(
	[stats_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Sponsor]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sponsor](
	[sponsor_id] [int] IDENTITY(1,1) NOT NULL,
	[sponsor_name] [varchar](50) NULL,
	[team_id] [int] NULL,
	[sponsorship_amount] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] NULL,
PRIMARY KEY CLUSTERED 
(
	[sponsor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SportObject]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SportObject](
	[object_id] [int] IDENTITY(1,1) NOT NULL,
	[object_name] [varchar](50) NULL,
	[owner_team_id] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] NULL,
PRIMARY KEY CLUSTERED 
(
	[object_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Team]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Team](
	[team_id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[wins] [int] NULL,
	[loses] [int] NULL,
	[win_percentage] [decimal](5, 2) NULL,
	[points_conceded] [int] NULL,
	[points_scored] [int] NULL,
	[players] [nvarchar](max) NULL,
	[sponsors] [nvarchar](max) NULL,
	[ModifiedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] NULL,
PRIMARY KEY CLUSTERED 
(
	[team_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[Match] ADD  CONSTRAINT [DF_Match_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Match] ADD  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[Player] ADD  CONSTRAINT [DF_Player_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Player] ADD  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[PlayerStats] ADD  CONSTRAINT [DF_PlayerStats_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[PlayerStats] ADD  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[Sponsor] ADD  CONSTRAINT [DF_Sponsor_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Sponsor] ADD  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[SportObject] ADD  CONSTRAINT [DF_SportObject_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[SportObject] ADD  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[Team] ADD  CONSTRAINT [DF_Team_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Team] ADD  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[Match]  WITH CHECK ADD  CONSTRAINT [FK_Match_SportObject] FOREIGN KEY([sport_object_id])
REFERENCES [dbo].[SportObject] ([object_id])
GO
ALTER TABLE [dbo].[Match] CHECK CONSTRAINT [FK_Match_SportObject]
GO
ALTER TABLE [dbo].[Match]  WITH CHECK ADD  CONSTRAINT [FK_Match_TeamAway] FOREIGN KEY([team_away_id])
REFERENCES [dbo].[Team] ([team_id])
GO
ALTER TABLE [dbo].[Match] CHECK CONSTRAINT [FK_Match_TeamAway]
GO
ALTER TABLE [dbo].[Match]  WITH CHECK ADD  CONSTRAINT [FK_Match_TeamHome] FOREIGN KEY([team_home_id])
REFERENCES [dbo].[Team] ([team_id])
GO
ALTER TABLE [dbo].[Match] CHECK CONSTRAINT [FK_Match_TeamHome]
GO
ALTER TABLE [dbo].[Player]  WITH CHECK ADD  CONSTRAINT [FK_Player_Team] FOREIGN KEY([team_id])
REFERENCES [dbo].[Team] ([team_id])
GO
ALTER TABLE [dbo].[Player] CHECK CONSTRAINT [FK_Player_Team]
GO
ALTER TABLE [dbo].[PlayerStats]  WITH CHECK ADD  CONSTRAINT [FK_PlayerStats_Match] FOREIGN KEY([match_id])
REFERENCES [dbo].[Match] ([match_id])
GO
ALTER TABLE [dbo].[PlayerStats] CHECK CONSTRAINT [FK_PlayerStats_Match]
GO
ALTER TABLE [dbo].[PlayerStats]  WITH CHECK ADD  CONSTRAINT [FK_PlayerStats_Player] FOREIGN KEY([player_id])
REFERENCES [dbo].[Player] ([player_id])
GO
ALTER TABLE [dbo].[PlayerStats] CHECK CONSTRAINT [FK_PlayerStats_Player]
GO
ALTER TABLE [dbo].[Sponsor]  WITH CHECK ADD  CONSTRAINT [FK_Sponsor_Team] FOREIGN KEY([team_id])
REFERENCES [dbo].[Team] ([team_id])
GO
ALTER TABLE [dbo].[Sponsor] CHECK CONSTRAINT [FK_Sponsor_Team]
GO
ALTER TABLE [dbo].[SportObject]  WITH CHECK ADD  CONSTRAINT [FK_SportObject_Team] FOREIGN KEY([owner_team_id])
REFERENCES [dbo].[Team] ([team_id])
GO
ALTER TABLE [dbo].[SportObject] CHECK CONSTRAINT [FK_SportObject_Team]
GO
/****** Object:  StoredProcedure [dbo].[MATCH_DISPLAY_TEAM_RANKING]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[MATCH_DISPLAY_TEAM_RANKING]
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
/****** Object:  StoredProcedure [dbo].[MATCH_UPDATE_SCORE_WITH__TEAMS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure to update score with teams
CREATE   PROCEDURE [dbo].[MATCH_UPDATE_SCORE_WITH__TEAMS]
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
/****** Object:  StoredProcedure [dbo].[MATCH_UPDATE_SCORE_WITH_MATCH_ID]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Procedure to update score with match ID
CREATE   PROCEDURE [dbo].[MATCH_UPDATE_SCORE_WITH_MATCH_ID]
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
/****** Object:  StoredProcedure [dbo].[MATCH_UPDATE_TEAM_RANKING]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[MATCH_UPDATE_TEAM_RANKING]
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
/****** Object:  StoredProcedure [dbo].[MATCH_UPDATE_TEAM_STATS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

-- Procedure to update team stats
CREATE   PROCEDURE [dbo].[MATCH_UPDATE_TEAM_STATS]
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
/****** Object:  StoredProcedure [dbo].[PLAYER_ADD_PLAYER]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--CREATE PROCEDURE PLAYER_ADD_PLAYER
CREATE PROCEDURE [dbo].[PLAYER_ADD_PLAYER]
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
/****** Object:  StoredProcedure [dbo].[PLAYER_CHECK_IF_PLAYER_EXISTS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

-- Create PROCEDURE PLAYER_CHECK_IF_PLAYER_EXISTS
CREATE   PROCEDURE [dbo].[PLAYER_CHECK_IF_PLAYER_EXISTS]
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
/****** Object:  StoredProcedure [dbo].[PLAYER_REMOVE_PLAYER_FROM_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[PLAYER_REMOVE_PLAYER_FROM_TEAM]
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
/****** Object:  StoredProcedure [dbo].[PLAYER_STATS_ADD_PLAYER_STATS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[PLAYER_STATS_ADD_PLAYER_STATS](
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
/****** Object:  StoredProcedure [dbo].[PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure to display all player stats
-- Procedure to display all player stats

CREATE   PROCEDURE [dbo].[PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS]
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
/****** Object:  StoredProcedure [dbo].[PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS_FROM_MATCH]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure to display all player stats from a match
-- Procedure to display all player stats from a specific match
CREATE   PROCEDURE [dbo].[PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS_FROM_MATCH]
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
/****** Object:  StoredProcedure [dbo].[PLAYER_STATS_DISPLAY_PLAYER_STATS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Procedure to display player stats
-- Procedure to display player stats
CREATE   PROCEDURE [dbo].[PLAYER_STATS_DISPLAY_PLAYER_STATS](
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
/****** Object:  StoredProcedure [dbo].[PLAYER_STATS_REMOVE_PLAYER_STATS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure to remove player stats
CREATE   PROCEDURE [dbo].[PLAYER_STATS_REMOVE_PLAYER_STATS](
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
/****** Object:  StoredProcedure [dbo].[PLAYER_STATS_UPDATE_PLAYER_STATS]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------
--------------------------            FUNCTIONS            -----------------------------------
----------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------

-- Procedure to update player stats
CREATE   PROCEDURE [dbo].[PLAYER_STATS_UPDATE_PLAYER_STATS](
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
/****** Object:  StoredProcedure [dbo].[PLAYER_TRANSFER_PLAYER]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[PLAYER_TRANSFER_PLAYER]
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
/****** Object:  StoredProcedure [dbo].[PRINT_SCHEDULE]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure to print the schedule
CREATE   PROCEDURE [dbo].[PRINT_SCHEDULE]
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
/****** Object:  StoredProcedure [dbo].[SCHEDULE_ADD_MATCH]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURES           -----------------------------------
----------------------------------------------------------------------------------------------
-- CREATE PROCEDURE dbo.SCHEDULE_ADD_MATCH
CREATE PROCEDURE [dbo].[SCHEDULE_ADD_MATCH] (
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
/****** Object:  StoredProcedure [dbo].[SCHEDULE_GENERATE_SCHEDULE]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--CREATE OR ALTER PROCEDURE dbo.SCHEDULE_GENERATE_SCHEDULE

CREATE   PROCEDURE [dbo].[SCHEDULE_GENERATE_SCHEDULE] (
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
/****** Object:  StoredProcedure [dbo].[SCHEDULE_PRINT_MATCHES_FOR_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Procedure to print matches for a specific team
CREATE   PROCEDURE [dbo].[SCHEDULE_PRINT_MATCHES_FOR_TEAM]
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
/****** Object:  StoredProcedure [dbo].[SCHEDULE_PRINT_SCHEDULE]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure to print the schedule
CREATE   PROCEDURE [dbo].[SCHEDULE_PRINT_SCHEDULE]
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
/****** Object:  StoredProcedure [dbo].[TEAM_ADD_SPONSOR_TO_THE_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--PROCEDURE TEAM_ADD_SPONSOR_TO_THE_TEAM

CREATE PROCEDURE [dbo].[TEAM_ADD_SPONSOR_TO_THE_TEAM](
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
/****** Object:  StoredProcedure [dbo].[TEAM_ADD_SPORT_OBJECT]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- --PROCEDURE TEAM_ADD_SPORT_OBJECT


CREATE PROCEDURE [dbo].[TEAM_ADD_SPORT_OBJECT]
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
/****** Object:  StoredProcedure [dbo].[TEAM_ADD_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



----------------------------------------------------------------------------------------------
--------------------------            PROCEDURE            -----------------------------------
----------------------------------------------------------------------------------------------



--PROCEDURE ADD_TEAM

CREATE PROCEDURE [dbo].[TEAM_ADD_TEAM]
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
/****** Object:  StoredProcedure [dbo].[TEAM_CREATE_SPONSOR]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--PROCEDUR TEAM_CREATE_SPONSOR

CREATE PROCEDURE [dbo].[TEAM_CREATE_SPONSOR]
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
/****** Object:  StoredProcedure [dbo].[TEAM_DELETE_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Procedure TEAM_DELETE_TEAM

CREATE PROCEDURE [dbo].[TEAM_DELETE_TEAM] (@delete_team_id INT)
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
/****** Object:  StoredProcedure [dbo].[TEAM_PRINT_PLAYERS_FROM_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- --PROCEDURE TEAM_ADD_SPORT_OBJECTF

CREATE   PROCEDURE [dbo].[TEAM_PRINT_PLAYERS_FROM_TEAM]
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
/****** Object:  StoredProcedure [dbo].[TEAM_PRINT_SPONSORS_FROM_TEAM]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- --PROCEDURE TEAM_PRINT_SPONSORS_FROM_TEAM

CREATE PROCEDURE [dbo].[TEAM_PRINT_SPONSORS_FROM_TEAM]
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
/****** Object:  StoredProcedure [dbo].[update_team_ranking]    Script Date: 1/30/2024 12:46:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[update_team_ranking] AS
BEGIN
    DECLARE @v_team_id INT;
    DECLARE @v_wins INT;
    DECLARE @v_loses INT;
    DECLARE @v_win_percentage FLOAT;

    DECLARE team_cursor CURSOR FOR
    SELECT team_id, wins, loses
    FROM team;

    OPEN team_cursor;
    FETCH NEXT FROM team_cursor INTO @v_team_id, @v_wins, @v_loses;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @v_win_percentage = ROUND(CASE WHEN (@v_wins + @v_loses) > 0 THEN CAST(@v_wins AS FLOAT) / CAST((@v_wins + @v_loses) AS FLOAT) ELSE 0 END, 3);

        UPDATE team
        SET wins = @v_wins,
            loses = @v_loses,
            win_percentage = @v_win_percentage
        WHERE team_id = @v_team_id;

        FETCH NEXT FROM team_cursor INTO @v_team_id, @v_wins, @v_loses;
    END;

    CLOSE team_cursor;
    DEALLOCATE team_cursor;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Table storing information about sports objects.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SportObject'
GO
USE [master]
GO
ALTER DATABASE [SportLeague] SET  READ_WRITE 
GO
