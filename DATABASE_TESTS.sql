USE SportLeague;

--DELETE DATAS FROM TABLE
DELETE FROM team;
DELETE FROM Match;
DELETE FROM Player;
DELETE FROM PLAYERSTATS;
DELETE FROM SPONSOR;
DELETE FROM SPORTOBJECT;




--ADDING TEAM
	EXEC dbo.TEAM_ADD_TEAM @team_name = 'BOSTON CELTICS';
    EXEC dbo.TEAM_ADD_TEAM @team_name = 'BROOKLYN NETS';
	EXEC dbo.TEAM_ADD_TEAM @team_name = 'NEW YORK KNICKS';
	EXEC dbo.TEAM_ADD_TEAM @team_name = 'PHILADELPHIA 76ERS';
	EXEC dbo.TEAM_ADD_TEAM @team_name = 'TORONTO RAPTORS';


--ADDING PLAYER
	-- CELTICS
EXEC PLAYER_ADD_PLAYER '11-09-1999', 'DREW', 'PETERSON', 'F', 1;
EXEC PLAYER_ADD_PLAYER '12-03-1987', 'Jayson', 'Tatum', 'F-G', 1;
EXEC PLAYER_ADD_PLAYER '11-05-1976', 'Jrue', 'Holiday', 'G', 1;
EXEC PLAYER_ADD_PLAYER '11-01-1989', 'Jaylen', 'Brown', 'G-F', 1;
EXEC PLAYER_ADD_PLAYER '11-10-1990', 'Kristaps', 'Porzingis', 'F-C', 1;
EXEC PLAYER_ADD_PLAYER '11-03-1991', 'Derrick', 'White', 'G', 1;

-- BROOKLYN
EXEC PLAYER_ADD_PLAYER '11-12-1984', 'Dariq', 'Whitehead', 'F', 2;
EXEC PLAYER_ADD_PLAYER '11-04-1993', 'Royce', 'O''Neale', 'F-G', 2;
EXEC PLAYER_ADD_PLAYER '11-02-1992', 'Mikal', 'Bridges', 'G', 2;
EXEC PLAYER_ADD_PLAYER '11-02-1990', 'Cameron', 'Johnson', 'G-F', 2;
EXEC PLAYER_ADD_PLAYER '11-10-1992', 'Lonnie', 'Walker IV.', 'F-C', 2;
EXEC PLAYER_ADD_PLAYER '11-09-1993', 'Trendon', 'Watford', 'G', 2;

-- Execute for KNICKS (team_id = 2)
EXEC PLAYER_ADD_PLAYER '11-06-1989', 'Donte', 'DiVincenzo', 'F', 3;
EXEC PLAYER_ADD_PLAYER '11-06-1990', 'Jacob', 'Toppin', 'F-G', 3;
EXEC PLAYER_ADD_PLAYER '11-08-1993', 'Miles', 'McBride', 'G', 3;
EXEC PLAYER_ADD_PLAYER '11-03-1995', 'Josh', 'Hart', 'G-F', 3;
EXEC PLAYER_ADD_PLAYER '04-09-1997', 'Malachi', 'Flynn IV.', 'F-C', 3;
EXEC PLAYER_ADD_PLAYER '08-02-1990', 'Precious', 'Achiuwa', 'G', 3;

-- Execute for 76ers (team_id = 3)
EXEC PLAYER_ADD_PLAYER '12-03-1997', 'Tyrese', 'Maxey', 'F', 4;
EXEC PLAYER_ADD_PLAYER '11-05-1994', 'KJ', 'Martin', 'F-G', 4;
EXEC PLAYER_ADD_PLAYER '11-07-1993', 'Mo', 'Bamba', 'G', 4;
EXEC PLAYER_ADD_PLAYER '10-07-1995', 'Tobias', 'Harris', 'G-F', 4;
EXEC PLAYER_ADD_PLAYER '11-08-1992', 'Jaden', 'Springer', 'F-C', 4;
EXEC PLAYER_ADD_PLAYER '11-10-1991', 'Ricky', 'Council IV', 'G', 4;

-- Execute for RAPTORS (team_id = 4)
EXEC PLAYER_ADD_PLAYER '10-10-1990', 'Javon', 'Freeman-Liberty', 'F', 5;
EXEC PLAYER_ADD_PLAYER '11-04-1987', 'Gradey', 'Dick', 'F-G', 5;
EXEC PLAYER_ADD_PLAYER '11-02-1996', 'Jalen', 'McDaniels', 'G', 5;
EXEC PLAYER_ADD_PLAYER '11-09-1994', 'Scottie', 'Barnes', 'G-F', 5;
EXEC PLAYER_ADD_PLAYER '11-01-1984', 'Immanuel', 'Quickley', 'F-C', 5;
EXEC PLAYER_ADD_PLAYER '11-03-1992', 'RJ', 'Barrett IV', 'G', 5;


EXEC REMOVE_PLAYER_FROM_TEAM 1


--ADD SPORT OBJECT
	EXEC TEAM_ADD_SPORT_OBJECT 'TD Garden', 1
    EXEC TEAM_ADD_SPORT_OBJECT 'Barclays Center', 2
    EXEC TEAM_ADD_SPORT_OBJECT 'Madison Square Garden', 3
    EXEC TEAM_ADD_SPORT_OBJECT'Wells Fargo Center', 4
	EXEC TEAM_ADD_SPORT_OBJECT 'Scotiabank Arena', 5

--ADD SPONSORS

	EXEC TEAM_CREATE_SPONSOR 'MOTOROLA', 150000;
	EXEC TEAM_CREATE_SPONSOR'DISNEY', 360000
    EXEC TEAM_CREATE_SPONSOR'PAYPAL', 230000
    EXEC TEAM_CREATE_SPONSOR'TESLA', 400000
    EXEC TEAM_CREATE_SPONSOR'COCA COLA', 500000
    EXEC TEAM_CREATE_SPONSOR'RAKUTEN', 450000
    EXEC TEAM_CREATE_SPONSOR'CHIME', 130000
    EXEC TEAM_CREATE_SPONSOR'FEASTABLES', 160000
    EXEC TEAM_CREATE_SPONSOR'WEBULL', 50000
    EXEC TEAM_CREATE_SPONSOR'VISTAPRINT', 250000
    EXEC TEAM_CREATE_SPONSOR'NIKE', 200000
    EXEC TEAM_CREATE_SPONSOR'ADDIDAS', 265000
    EXEC TEAM_CREATE_SPONSOR'PUMA', 300000
    EXEC TEAM_CREATE_SPONSOR 'GOOGLE', 420000

	exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 1,1;
	exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 2,2
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 3,2
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 4,2
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 5,3
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 6,3
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 7,4
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 8,5
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 9,5
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 10,2
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 11,4
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 12,3
    exec dbo.TEAM_ADD_SPONSOR_TO_THE_TEAM 13,1

--PRINT SPONSORS FROM TEAM
	EXEC dbo.TEAM_PRINT_SPONSORS_FROM_TEAM 1

--PRINT PLAYER FROM TEAM
	EXEC TEAM_PRINT_PLAYERS_FROM_TEAM 4

--TRANSFERT PLAYER FROM TEAM
	EXEC  PLAYER_TRANSFER_PLAYER 2,4





--GENERATE SCHEDULE
	DELETE FROM  MATCH;
	DECLARE @start_season_date date = GETDATE()
	PRINT @start_season_date
	EXEC SCHEDULE_GENERATE_SCHEDULE @start_season_date

	EXEC SCHEDULE_PRINT_SCHEDULE
	EXEC SCHEDULE_PRINT_MATCHES_FOR_TEAM 1

--DISPLAY RANKING
	EXEC MATCH_UPDATE_SCORE_WITH_MATCH_ID 1, 115,110
	EXEC PLAYER_STATS_UPDATE_PLAYER_STATS 1,15,10,23,13,40,12
    EXEC MATCH_DISPLAY_TEAM_RANKING;
    EXEC PLAYER_STATS_DISPLAY_PLAYER_STATS 1


	EXEC MATCH_UPDATE_SCORE_WITH_MATCH_ID 3,115,110


	EXEC PLAYER_STATS_DISPLAY_PLAYER_STATS 7
--TRANSFERT PLAYER 
    EXEC TEAM_PRINT_PLAYERS_FROM_TEAM 2
	EXEC  PLAYER_TRANSFER_PLAYER 2,4
    EXEC TEAM_PRINT_PLAYERS_FROM_TEAM 2
    EXEC TEAM_PRINT_PLAYERS_FROM_TEAM 4


--STATS

	EXEC PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS


	EXEC PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS_FROM_MATCH 1
