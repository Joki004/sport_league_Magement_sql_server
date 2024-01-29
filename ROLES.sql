
REVERT;
ALTER ROLE db_owner DROP MEMBER admin;
USE SportLeague; 
DROP USER  IF EXISTS admin;
DROP  LOGIN admin;
DROP ROLE IF EXISTS admin;
DROP ROLE IF EXISTS UserRole;



REVERT;
USE SportLeague; 
ALTER ROLE UserRole DROP MEMBER YourUser;
DROP ROLE IF EXISTS UserRole;
DROP USER IF EXISTS YourUser;
DROP LOGIN UserLogin;

---------------------------------------------------------------------------------------------
----------------------------- role ----------------------------------------------------------
---------------------------------------------------------------------------------------------
SELECT name AS RoleName
FROM sys.database_principals
WHERE type_desc = 'DATABASE_ROLE';


SELECT USER_NAME(role_principal_id) AS RoleName, USER_NAME(member_principal_id) AS MemberName
FROM sys.database_role_members
WHERE USER_NAME(role_principal_id) = 'db_owner';


---------------------------------------------------------------------------------------------
----------------------------- admin ----------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Create the 'admin' role
CREATE ROLE admin;


CREATE LOGIN admin WITH PASSWORD = '54321'; 

ALTER SERVER ROLE admin ADD MEMBER admin;
CREATE USER admin FOR LOGIN admin;

EXEC sp_addrolemember 'db_owner', 'admin';

EXECUTE AS USER = 'admin';

EXEC dbo.TEAM_ADD_TEAM 'barcelona';

REVERT;
---------------------------------------------------------------------------------------------
----------------------------- user ----------------------------------------------------------
---------------------------------------------------------------------------------------------

CREATE ROLE UserRole;

CREATE LOGIN UserLogin WITH PASSWORD = '12345';
CREATE USER YourUser FOR LOGIN UserLogin;
GRANT EXECUTE ON dbo.SCHEDULE_PRINT_SCHEDULE TO UserRole;
GRANT EXECUTE ON dbo.SCHEDULE_PRINT_MATCHES_FOR_TEAM TO UserRole;
GRANT EXECUTE ON dbo.TEAM_PRINT_PLAYERS_FROM_TEAM TO UserRole;
GRANT EXECUTE ON dbo.TEAM_PRINT_SPONSORS_FROM_TEAM TO UserRole;
GRANT EXECUTE ON dbo.PLAYER_STATS_DISPLAY_PLAYER_STATS TO UserRole;
GRANT EXECUTE ON dbo.PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS TO UserRole;
GRANT EXECUTE ON dbo.PLAYER_STATS_DISPLAY_ALL_PLAYER_STATS_FROM_MATCH TO UserRole;
GRANT EXECUTE ON dbo.MATCH_DISPLAY_TEAM_RANKING TO UserRole;

EXEC sp_addrolemember 'UserRole', 'YourUser';

EXECUTE AS USER = 'YourUser';


EXEC dbo.SCHEDULE_PRINT_SCHEDULE;
EXEC dbo.SCHEDULE_PRINT_MATCHES_FOR_TEAM 1;
EXEC DBO.MATCH_DISPLAY_TEAM_RANKING
--SHOULD NOT WORK
EXEC dbo.TEAM_ADD_TEAM 'barcelona'

REVERT;



