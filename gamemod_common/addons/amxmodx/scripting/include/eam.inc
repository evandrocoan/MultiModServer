
#define MAX_PLAYERS				32
#define MAX_CATEGORIES			10
#define CATEGORY_NAME_LENGTH	20
#define MAX_COMMANDS			50
#define COMMAND_NAME_LENGTH		20
#define COMMENT_LENGTH			30
#define OPTION_NAME_LENGTH		20
#define INPUT_LENGTH			30
#define MAX_ARGUMENTS			5
#define MAX_OPTIONS				10

#if defined _eam_included || defined _eam_base
  #endinput
#endif
#define _eam_included

#pragma reqlib "eam"

enum TYPE_ARG {	//Argument Types
	PLAYER = 1,
	TEAM,
	PLAYER_OR_TEAM,
	RANGE,
	F_RANGE,
	OPTIONS,
	OPT_OR_PLYR,
	INPUT
}
enum TYPE_PLAYER {
	USERID = 1,
	AUTHID,
	USERNAME
}
 
enum TYPE_ACCESS{	//Access Types
	CVAR = 1,
	ADMIN_CONST,
	FLAG
}
enum TYPE_EXEC {	//Execute Types
	EXEC_PLAYER = 0,
	EXEC_SERVER,
	EXEC_ALL
}

//returns category number in menu
native eam_category_register(const category_name[]);

//specifys access needed for the category
native eam_category_access(const category, const TYPE_ACCESS:access_type, {_}:...);

//returns command number in menu
native eam_command_register(const command_name[]);

//adds a comment to the command
native eam_command_comment(const command, const comment[]);

//changes a commands category
native eam_command_category(const command, const category);

//adds an argument to the command. only specify range_min and range_max if arg_type is RANGE
native eam_command_arg(const command, const arg_number, const TYPE_ARG:arg_type, {Float,TYPE_PLAYER,_}:...);

//specifys access needed for the command
native eam_command_access(const command, const TYPE_ACCESS:access_type, {_}:...);

//specifys what executes the command
native eam_command_exec(const command, const TYPE_EXEC:exec_type);



