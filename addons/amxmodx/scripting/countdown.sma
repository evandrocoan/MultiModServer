/********************************************************************************
countdown.sma          version:0.8            Date:2004/12/9

Bread "afiTa" Dawson       breaddawson@msn.com

Forums thread:

This is my first plugin and it's made to show you the countdown of the event u 
specified

for example,u can specify your girl friend's birthday using the cvar
then there will be a count down at the midtop of your screen
Have fun!!!
And wish u enjoy!!!

Install

	1.compile this plugin and put the .amxx in the /plugins dictionary
	
	2.add this entry in your plugins.ini which is in /configs dictionary
	
		countdown.amxx
	

Features:
	
	1.Now Time display
	2.Count Down For specified event
	3.Both Messages and Sounds when u reach the event
	4.***NEW***Commands auto run when u reach the event


Usages (This is a bit lengthy,but...may help u a lot if u read it ;])
	
	1. Modes Selections
	
	There're 4 modes in total: <0|1|2|3>
	(Only admins who has ADMIN_LEVEL_C access can use this command)
	0----off
	1----now time mode
	2----count down mode(if amx_count_show is set to 0,then no 
	messages or sounds will come up)
	3----count down mode(everyone would hear the event sound ,
	no matter u turn it on or off)
	
	if u set the mode as 0,then this plugin will be turned off,er....,it does
	have differences with uninsalling,that is,u can turn it on by give it a
	none-0 value whenever u want
	
	the mode 1 is made as Now Time Mode
	that means,if u specify the mode as 1
	u can see the now time at the middle top of your screen
	just like this:
	
	******************************************************************************
					Nowtime: 2004/11/10
						 23:00:00
	******************************************************************************	
	
	;),u can use this mode as a clock
	er...till here,maybe someone will throw a bomb:"i want no now time shown up",
	"how can i get rid of this damn messages!",but others who need this may say:
	"er...all right,i want now time shown up"
	then u admin may got a headache with this,
	ha,don't worry,there's another command prepared for all guys
	
	amx_count_show < on|off >
	
	this command will help everyone to turn on/off his own messages
	and the one who want no "damn messages" can set it off,then he can see no
	messages shown up on his screen
	
	2.Cumtomize your hud message color
	
	if u don't like the color (it's white as default)
	u can use this command
	
	amx_count_color <RRR GGG BBB>
	
	for example,blue is your favourate
	then u should type "amx_count_color 0 0 255"
	
	
	3.Specify the event date,time,msg and sound
	
	ok,here comes our superstar,count down mode
	if u set the mode as 2 or 3
	then u can use coun down mode,the differences between these two modes is minor
	and u can see the details below
	
	but...how did the machine know the event date & time?
	-_-,ok,it knows nothing wihout those u told it
	u can specify the event date and time with these two commands
	
	amx_count_date <YYYYmmDD>
	amx_count_time <HHMMSS>
	
	u can turn to Commands Section to see the commands details
	after this,u can also specify your own event messages
	for example,your girl friend's birthday is in 3 days,
	and u want "Happy Birthday,Piggy" shown up till then
	the command "amx_count_msg" will help u 
	
	amx_count_msg <"messages">
	
	e.g.: amx_count_msg "Happy Birthday,Piggy!!!"
	
	er...did i mention it?plz don't give a messages up to 384 characters.
	oh,plz don't,both countdown.sma and i will thank u
	
	after this,u can see the messages below shown up
	
	******************************************************************************
					Nowtime: 2004/11/27
						 23:00:00
					Remaining: 3 Days 01:10:00
	******************************************************************************	
	
	and when u reached the event,let's say it's your gf's birthday
	at the last 10 senconds,u will hear the 10s counddown sound
	then u will see this
	
	******************************************************************************
				Happy Birthday ,Piggy!!!
	
	******************************************************************************
	
	ok,everything is done,oh,no
	wait...wait...let me think,don't u feel there's somthing missing
	"u mean the music?"
	o,god,u got it!why don't we play music when reached the event!
	ok,let's specify a music like this
	
	amx_count_sound "birthday"
	
	with writing like this,u must put "birthday.wav" in /sound/misc dictionary
	then u can hear the music ~~
	
	4.The reminder
	
	after this,u will see the reminder,yes,a reminder will show up every 10s,
	totally 3 times,just like this:
	
	******************************************************************************
				Happy Birthday ,Piggy!!!
				Passed    10  seconds  ago
	
	******************************************************************************
	then u will see another two reminders,each will be shown 10 seconds after the
	prvious one
	
	all above is to the situation that when u start your server,the event u 
	specified has not come
	
	but there's another situation,the event u specified has come before ur server 
	started
	for example,u unluckily fogot ur gir friend's birthday has passed
	(oh,what a poor boy,there may be a World War again)
	u will see the messages below 
	
	******************************************************************************
				Oh,No!!!u've missed the event
				
				Happy Birthday ,Piggy!!!
			    
			    	Elapsed: 1 Days 1: 0 :0
				
	******************************************************************************

	"ah,it actually hasn't passed,i just give a wrong date!!"
	ok,u just need typed again with the command
	and u will use the normal count down
	
	5.the differences between Mode 2 & Mode 3
	
	wa,i nearly forgot that,err..if u're still here with my tedious Usages Section,
	good...let me then explain the differences betwen the mode 2 & 3
	that is,as u know,u can hear some sound with this plugin
	but...maybe someone don't like to hear any sound but the gun's and the enemy's
	and the lazy bread didn't even give a command to do it!!
	ok,i'm lazy...
	but what i think is that the admin may want everyone who's in his server to hear
	the sound,no matter u want it or not
	(calm down,guys,u already turn off the "damn messages",plz bear with the sound
	anyway,it only last several seconds)
	if u set the mode as 3,then everyone will hear the sound,no one can escape
	er...if u give it a 2,then the one who want no sounds can turn it off with
	"amx_count_show 0"

	6.NEW FEATURE: Commands Auto Run when u reach the event
	
	if u want some commands auto run when we reach the event
	just put commands in count_vault.ini with "*" in front of it
	for example,
	
	*amx_count_date 20050101
	*amx_count_msg "happy new year!!!"
	
	then till then,"amx_count_date 20050101" and "amx_count_msg 'happy new year'" will 
	be executed by the server
	REMEMBER:DO add ONE "*" before the command
	

Command:

	amx_count_mode: < 0|1|2|3 >
			0----off
			1----now time mode
			2----count down mode(if amx_count_show is set to 0,then no 
			messages or sounds will come up)
			3----count down mode(everyone would hear the event sound ,
			no matter u turn it on or off)
			
	amx_count_date: YYYYmmDD
			u can specify the event date by this command
			and the date u typed will be checked if it's valid or not
			e.g: amx_count_date 20051004
			
	amx_count_time: HHMMSS
			u can specify the event time by this command
			and the time u typed will be checked if it's valid or not
			e.g: amx_count_time 121000
			
	amx_count_msg: "messages"
			u can specify the event messages which will be shown up 
			when u reached the pont
			just like this:
			amx_count_msg "Happy Birthday,Piggy"
			
			DO USE "" !!!!BOHT COUNT DOWN PLUGIN AND I WILL THANK U!!
			
	amx_count_show: < on|off >
			1|on-u will see the count down messages if bread_count_show
				is set to 1
			0|off-u will not see the count down messages
	
	amx_count_color <RRR GGG BBB>
			u can customized your own hud message color by this command
			for example:
				amx_count_color 255 0 0
			then your hud message color will be red
			
	amx_count_sound:<filename with NO extension>
			Only Admin having ADMIN_LEVEL_C access can use this command
			if u have the access,u can specify the sound played when u
			reached the event
			e.g. amx_count_sound "bread"
			then the event sound will be set to "bread.wav"
			and u SHOULD put the sound in /sound/misc
	amx_count_save:
			Only Admin having ADMIN_LEVEL_C access can use this command
			this command is made to store settings to vault file
			the settings include:
			amx_count_mode
			amx_count_date
			amx_count_time
			amx_count_msg
			amx_count_sound
			
		
History:

	0.8:added vault file to store settings
	    added settings auto preread from vault file
	    added command amx_count_save
	    added new feature:commands auto run when u reached the event
	    	see Usages for details
	    added German support(thanks to PM for his help)
	    added Spanish support (thanks to DarkBeatz for his help)

	0.7:added multi-language support(English & Chinese now)

	0.6:added command amx_count_color

	0.5:fixed a minor error come up when displaying time
	    added command amx_count_mode
	    added command amx_count_date
	    added command amx_count_time
	    added codes to check if the date&time u give is valid
	    added command amx_count_msg
	    
	    i removed all the cvars,instead of them i added several commands
	    removed cvar bread_count_show,u can use amx_count_mode instead
	    removed cvar bread_count_date,u can use amx_count_date instead
	    removed cvar bread_count_time,u can use amx_count_time instead
	    removed cvar bread_count_message,u can use amx_count_msg instead

	0.3:fixed one time display bug that when u reach the day u specified,u will
		still see Remaining 1 days
	    added command amx_count_show,every player could use this command to let the
	    	messages shown on their sceen or not
	    added command amx_count_sound,the admin who has ADMIN_LEVEL_C could use
	    	this command to specify the sound played when u reach the event,
	    	Special thanks to ol's idea!!!
	    added event reminder,after u reached the event,u will see the reminder every
	    	10 seconds,totally 3 times
	0.2:fixed the bug remaining time displayed error when the date u specified 
		has passed
	    added cvar bread_count_show
		0-the count down will not be shown on ur screen
		1-the count down will be shown on ur screen
	    added the message that will show up when the date u specified has passed
	0.1:first release
********************************************************************************/

			
#include <amxmodx>
#include <amxmisc>


new el_days=0;//elapsed days
new el_seconds=0;//elapsed seconds

new g_Reverse=0;//this variable tells if the day u specified in the cvar has passed
new g_iReminder=0;

new g_iColor[33][3];//the color of user's hud message,[id][0]-red,[id][1]-green,[id][2]-green

new g_iShow[33];//user's flag of showing messages or not
new g_sound[16];//the sound for your event,use amx_count_sound to specify it

new g_messages[384]="Not specified yet";//the event messages
new g_iMode=0;
new g_iDate=20100101;
new g_iTime=000000;

new g_config[64];//the location of config file
new g_data[64];//store values of commands

public plugin_init()
{
	register_plugin("COUNT DOWN","0.8","bread");
	register_concmd("amx_count_mode","count_mode",ADMIN_LEVEL_C,"< 0|1|2|3 > Set the count down mode");
	register_concmd("amx_count_date","count_date",ADMIN_LEVEL_C,"<YYYYmmDD> Set the event date");
	register_concmd("amx_count_time","count_time",ADMIN_LEVEL_C,"<HHMMSS> Set the event time");
	register_concmd("amx_count_msg","count_message",ADMIN_LEVEL_C,"<messages> Set the event message");
	register_concmd("amx_count_sound","count_sound",ADMIN_LEVEL_C,"< filename and NO extension >,speifify the sound for ur event")
	register_concmd("amx_count_save","save_configs",ADMIN_LEVEL_C,"save your settings");
	register_concmd("amx_count_show","user_show",0,"<on | off>,Turn your count down mode on /off");
	register_concmd("amx_count_color","user_color",0,"<RRR GGG BBB>,Customized your hud msg color");
	register_dictionary("countdown.txt");
	set_task(5.0,"pre_read_configs");
	set_task(10.0,"begin_count");
	get_localinfo("amxx_configsdir",g_config,63);
	format(g_config,63,"%s/count_vault.ini",g_config);
	return PLUGIN_HANDLED;
}

public pre_read_configs()
{
	read_config("amx_count_mode");
	read_config("amx_count_date");
	read_config("amx_count_time");
	read_config("amx_count_msg");
	read_config("amx_count_sound");
	return PLUGIN_HANDLED;
}

public read_config(command[])
{
	file_rw("R",command,"");
	if (!equal(g_data,"NONE"))
	{
		server_cmd("%s %s",command,g_data);
	}
	return PLUGIN_CONTINUE;
}

public save_configs()
{
	new sTemp[128];
	num_to_str(g_iMode,sTemp,127);
	file_rw("W","amx_count_mode",sTemp);
	num_to_str(g_iDate,sTemp,127);
	file_rw("W","amx_count_date",sTemp);
	num_to_str(g_iTime,sTemp,127);
	file_rw("W","amx_count_time",sTemp);
	format(sTemp,128,"^"%s^"",g_messages);
	file_rw("W","amx_count_msg",sTemp);
	file_rw("W","amx_count_sound",g_sound);
	return PLUGIN_HANDLED;
}

//if one player is connected,his own show mode will be set to 1 as default
public client_putinserver(id)
{
	g_iShow[id]=1;
	g_iColor[id][0]=g_iColor[id][1]=g_iColor[id][2]=255;
	return PLUGIN_CONTINUE;
}


public begin_count()
{
	if (task_exists(906912)==0)
		set_task(1.0,"count_down",906912,"",0,"b");
	return PLUGIN_CONTINUE;
}
/*
modes
0----off
1----now time mode
2----count down mode(if amx_count_show is set to 0,then no messages or sounds will come up)
3----count down mode(everyone would hear the event sound ,no matter u turn it on or off)
*/
public count_mode( id,level,cid )
{
	new mode[2];
	if (!cmd_access(id,level,cid,1) )
		return PLUGIN_HANDLED;
	if (read_argc()<2)
	{
		client_print(id,print_console,"%L",id,"MODE_USAGE",g_iMode);
		return PLUGIN_HANDLED;
	}
	read_argv(1,mode,1);
	if (str_to_num(mode)>3)
	{
		client_print(id,print_console,"%L",id,"MODE_ERROR",g_iMode);
		return PLUGIN_HANDLED;
	}

	if (str_to_num(mode)!=0)
		begin_count();
	if ( (g_iMode!=0) && (str_to_num(mode)==0) )
		remove_task(906912);

	
	g_iMode=str_to_num(mode);
	client_print(id,print_console,"%L",id,"MODE_SET",g_iMode);
	client_print(0,print_chat,"%L",LANG_PLAYER,"MODE_ADMIN",g_iMode);
	return PLUGIN_HANDLED;
}

public count_date( id,level,cid)
{
	new idate[9];
	new temp[5];
	new month;
	new year;
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	if (read_argc()<2)
	{
		num_to_str(g_iDate,idate,8);
		client_print(id,print_console,"%L",id,"DATE_USAGE",g_iDate?idate:"%L",id,"NOT_SPECIFY");
		return PLUGIN_HANDLED;
	}

	read_argv(1,idate,8);
	copy(temp,4,idate);
	year=str_to_num(temp);
	if (year<1900)
	{
		client_print(id,print_console,"%L",id,"WRONG_YEAR",year);
		return PLUGIN_HANDLED;
	}
	copy(temp,2,idate[4]);
	month=str_to_num(temp);
	if ( (month<1) | (month>12) )
	{
		client_print(id,print_console,"%L",id,"WRONG_MONTH",month);
		return PLUGIN_HANDLED;
	}
	copy(temp,2,idate[6]);
	if ( (str_to_num(temp)>day_of_month( month,year ))| (str_to_num(temp)<1) )
	{
		client_print(id,print_console,"%L",id,"WRONG_DAY",str_to_num(temp));
		return PLUGIN_HANDLED;
	}
	g_iDate=str_to_num(idate);
	client_print(id,print_console,"%L",id,"DATE_SET",g_iDate/10000,g_iDate/100%100,g_iDate%100);
	client_print(0,print_chat,"%L",LANG_PLAYER,"DATE_ADMIN",g_iDate/10000,g_iDate/100%100,g_iDate%100);
	begin_count();
	return PLUGIN_HANDLED;
}

public count_time( id,level,cid )
{
	new stime[7];
	new temp[3];
	new itime;
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	if (read_argc()<2)
	{
		client_print(id,print_console,"%L",id,"TIME_USAGE",g_iTime);
		return PLUGIN_HANDLED;
	}
	read_argv(1,stime,6);
	copy(temp,2,stime);
	if ( (str_to_num(temp)<0)||(str_to_num(temp)>23) )
	{
		client_print(id,print_console,"%L",id,"WRONG_HOUR",temp);
		return PLUGIN_HANDLED;
	}
	itime=str_to_num(temp);
	copy(temp,2,stime[2])
	if ( (str_to_num(temp)<0)||(str_to_num(temp)>59) )
	{
		client_print(id,print_console,"%L",id,"WRONG_MINUTE",temp);
		return PLUGIN_HANDLED;
	}
	itime=itime*100+str_to_num(temp);
	copy(temp,2,stime[4])
	if ( (str_to_num(temp)<0)||(str_to_num(temp)>59) )
	{
		client_print(id,print_console,"%L",id,"WRONG_SECOND",temp);
		return PLUGIN_HANDLED;
	}
	itime=itime*100+str_to_num(temp);
	
	g_iTime=itime;
	client_print(id,print_console,"%L",id,"TIME_SET",itime/10000,itime/100%100,itime%100);
	client_print(0,print_chat,"%L",LANG_PLAYER,"TIME_ADMIN",g_iTime/10000,g_iTime/100%100,g_iTime%100);
	begin_count();
	return PLUGIN_HANDLED;
}

public count_message( id,level,cid )
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	if (read_argc()<2)
	{
		client_print(id,print_console,"%L",id,"MSG_USAGE",g_messages);
		return PLUGIN_HANDLED;
	}
	read_args(g_messages,380);
	client_print(id,print_console,"%L",id,"MSG_SET",g_messages);
	return PLUGIN_HANDLED;
}

//when the client use amx_count_show,this function will be called
public user_show( id,level,cid )
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	
	if (read_argc()<2)
	{
		new statu[4];
		if (g_iShow[id]==1)
			copy(statu,4,"on");
		else
			copy(statu,4,"off");
		client_print(id,print_console,"%L",id,"SHOW_USAGE",statu);
		return PLUGIN_HANDLED;
	}
	
	new arg[10];
	read_argv(1,arg,10);
	
	if (equal(arg,"on",2)||equal(arg,"1",1))
	{
		g_iShow[id]=1;
	}
	else if (equal(arg,"off",3)||equal(arg,"0",1))
			{
				g_iShow[id]=0;
			}
			else
			{
				new statu[4];
				if (g_iShow[id]==1)
					copy(statu,4,"on");
				else
					copy(statu,4,"off");
				client_print(id,print_console,"%L",id,"SHOW_USAGE",statu);
			}
	
	return PLUGIN_HANDLED;
}

public user_color(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;

	if (read_argc()<4)
	{
		client_print(id,print_console,"%L",id,"COLOR_USAGE",g_iColor[id][0],g_iColor[id][1],g_iColor[id][2]);
		return PLUGIN_HANDLED;
	}
	
	new temp[4];
	new i;
	for (i=1;i<4;i++)
	{
		read_argv(i,temp,3);
		if (str_to_num(temp)<256 && str_to_num(temp)>=0)
			g_iColor[id][i-1]=str_to_num(temp);
		else
		{
			client_print(id,print_console,"%L",id,"WRONG_COLOR")
			return PLUGIN_HANDLED;
		}
	}
	client_print(id,print_console,"%L",id,"COLOR_SET",g_iColor[id][0],g_iColor[id][1],g_iColor[id][2]);
	return PLUGIN_HANDLED;
}

/*
the admin command amx_count_sound will call this function
if u use the correct format,like this amx_count_sound bread
it will play bread.wav to all client which is in /sound/misc dictionary
*/
public count_sound( id,level,cid )
{
	
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	if (read_argc()<2)
	{
		client_print(id,print_console,"%L",id,"SOUND_USAGE",equal(g_sound,"")?"%L":g_sound,id,"NOT_SPECIFY");
		return PLUGIN_HANDLED;
	}
	
	read_args(g_sound,16);
	new filename[32];
	format(filename,31,"sound/misc/%s.wav",g_sound)
	
	if (file_exists(filename)==0)
	{
		client_print(id,print_console,"%L",id,"FILE_NONE",g_sound);
		copy(g_sound,16,"");
		return PLUGIN_HANDLED;
	}
	
	client_print(id,print_console,"%L",id,"SOUND_SET",g_sound);
	
	return PLUGIN_HANDLED;
}

//it's made to show hudmessages to all clients who set their amx_count_show to 1
public user_hud_msg(mode,red,green,blue, Float:x,Float:y,effect,Float:fxtime,Float:holdtime,Float:fadein,Float:fadeout,channel,msg[])
{
	new i;
	new iMaxplayer=get_maxplayers();
	
	for (i=1;i<iMaxplayer;i++)
	{
		if (is_user_connected(i)&&g_iShow[i])
		{
			if (mode==1)//use comstomized color
				set_hudmessage(g_iColor[i][0],g_iColor[i][1],g_iColor[i][2],x,y,effect,fxtime,holdtime,fadein,fadeout,channel);
			else
				set_hudmessage(red,green,blue,x,y,effect,fxtime,holdtime,fadein,fadeout,channel);
			show_hudmessage(i,msg);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public user_play_sound(temp[])
{
	new i;
	new iMaxplayer=get_maxplayers();
	
	for (i=1;i<iMaxplayer;i++)
	{
		if (is_user_connected(i)&&g_iShow[i])
			client_cmd(i,"spk ^"%s^"",temp);
	}
	
	return PLUGIN_CONTINUE;
}

public event_reminder()
{
	new sMessages[256];
	new iColor[3]={0,0,0};
	
	g_iReminder+=10;
	iColor[g_iReminder/10-1]=255;

	user_hud_msg(0,iColor[0],iColor[1],iColor[2],-1.0,0.06, 0, 3.0, 3.0, 1.0, 2.0, 13,g_messages);
	
	format(sMessages,255,"%L",LANG_PLAYER,g_iReminder);
	user_hud_msg(0,iColor[0],iColor[1],iColor[2],-1.0,0.10, 0, 3.0, 3.0, 1.0, 2.0, 14,sMessages);
	
	if (g_iReminder==30)
		remove_task(906104);
	return PLUGIN_CONTINUE;
}

//this is the main function which carries the count down
public count_down()
{
	//the plugin is turned off
	if (g_iMode==0)
		return PLUGIN_CONTINUE;
	new sDateNow[11];
	new sTimeNow[9];
	new nowtime[32]
	//only now time mode
	if (g_iMode==1)
	{
		get_time("%Y/%m/%d",sDateNow,10);
		get_time("%H:%M:%S",sTimeNow,8);
		
		format(nowtime,31,"%L:%s ^n %s",LANG_PLAYER,"NOWTIME",sDateNow,sTimeNow);
		user_hud_msg(1,255, 0, 0, -1.0, 0.05, 0, 1.0, 0.9, 0.1, 0.1,2,nowtime);
		return PLUGIN_CONTINUE;
	}
	
	new sMessages[256];
	
	new iDate;
	new iTime;

	new iDateNow;
	new iTimeNow;
	

	new remain_time[64]
	new re_Hour;
	new re_Minute;
	new re_Second;

	
	g_Reverse=0;
	
	iDate=g_iDate;
	iTime=g_iTime;

	get_time("%Y%m%d",sDateNow,8);
	get_time("%H%M%S",sTimeNow,6);
	iDateNow=str_to_num(sDateNow);
	iTimeNow=str_to_num(sTimeNow);
	
	if (iDate<iDateNow)
	{
		g_Reverse=1;
	}
	else if ( (iDate==iDateNow) && (iTime<iTimeNow) )
			{
				g_Reverse=1;
			}
			
	if (g_Reverse==1)//the day u specified has already gone
	{
		time_elapsed(iDate,iTime,iDateNow,iTimeNow);
		
/*
		'cause the lag would cause the time not so correct,and u will miss the moment
		when both days and seconds is zero,i add another contidion here 
		that even remain seconds is 1,and days is 0,it will show the event message,too
*/
		if ( (el_days==0)&&(el_seconds==1) )
		{		
			event_reached();
			return PLUGIN_CONTINUE;
		}
		
		
		re_Second=el_seconds%60;
		re_Minute=el_seconds%3600/60;
		re_Hour=el_seconds/3600;
		
		format(sMessages,255,"%L",LANG_PLAYER,"MISS");
		user_hud_msg(0,255, 0, 0, -1.0, 0.05, 0, 3.0, 10.0, 1.0, 2.0,10,sMessages);
		
		user_hud_msg(0,0, 0, 255, -1.0, 0.10, 0, 3.0, 10.0, 1.0, 2.0,11,g_messages);
		
		format(remain_time,63,"%L",LANG_PLAYER,"ESLAPE",el_days,re_Hour,re_Minute,re_Second);
		user_hud_msg(1,255, 0, 0, -1.0, 0.15, 0, 3.0, 10.0, 1.0, 2.0,12,remain_time);
		
		remove_task(906912);
		return PLUGIN_CONTINUE;
	}
	
	time_elapsed(iDateNow,iTimeNow,iDate,iTime);
	
	//if  both remain days and remain seconds come to zero,then you reached the event

	if ( (el_seconds==0)&&(el_days==0) )
	{
		event_reached();
		return PLUGIN_CONTINUE;
	}
		
	re_Second=el_seconds%60;
	re_Minute=el_seconds%3600/60;
	re_Hour=el_seconds/3600;
	
	get_time("%Y/%m/%d",sDateNow,10);
	get_time("%H:%M:%S",sTimeNow,8);
	
	format(nowtime,31,"%L:%s ^n %s",LANG_PLAYER,"NOWTIME",sDateNow,sTimeNow);
	user_hud_msg(1,255, 255, 255, -1.0, 0.05, 0, 1.0, 0.9, 0.1, 0.1,2,nowtime);
		
	format(remain_time,63,"%L",LANG_PLAYER,"REMAIN",el_days,re_Hour,re_Minute,re_Second);
	user_hud_msg(1,255, 255, 255, -1.0, 0.12, 0, 1.0, 0.9, 0.1, 0.1,3,remain_time);
	
	if (re_Second < 11 && el_days==0 && re_Hour==0 && re_Minute==0 )
	{
		new temp[48];
		num_to_word(re_Second,temp,48);
		format(temp,47,"fvox/%s",temp);
		if (g_iMode==2)
			user_play_sound(temp);
		else if (g_iMode==3)
			client_cmd(0,"spk ^"%s^"",temp);
	}
	
	return PLUGIN_CONTINUE;
}

public event_reached()
{
	user_hud_msg(0,255, 0, 0, -1.0, 0.15, 0, 3.0, 10.0, 1.0, 2.0,12,g_messages);
	
	g_iReminder=0;
	set_task(10.0,"event_reminder",906104,"",0,"b");
	
	new filename[32];
	format(filename,31,"sound/misc/%s.wav",g_sound)
	if (file_exists(filename))
	{
		format(filename,31,"misc/%s",g_sound);
		if (g_iMode==2)
			user_play_sound(filename);
		else if (g_iMode==3)
			client_cmd(0,"spk ^"%s^"",filename);
	}
	excute_commands();
	remove_task(906912);
	return PLUGIN_CONTINUE;
}

public excute_commands()
{
	new line=0;
	new sCommand[32];
	new sValue[64];
	new temp[96];
	new txtleng;
	
	if (!file_exists(g_config))
		return PLUGIN_CONTINUE;
	while ( (line=read_file(g_config,line,temp,96,txtleng))!=0)
	{
		parse (temp,sCommand,32,sValue,64);
		if (equal(sCommand,"*",1))
		{
			copy(sCommand,128,sCommand[1]);
			server_cmd("%s %s",sCommand,sValue);
		}
	}
	return PLUGIN_CONTINUE;
}

public file_rw(rw[],keys[],values[])
{
	new sCommand[32];//this is command
	new sValue[64];//this is the value of the command
	new temp[96];//the is command+value
	new line=0;
	new txtleng;
	new iDone=0;
	if (!file_exists(g_config))
	{
		write_file(g_config,"---This is use to store values for coundown plugin---");
	}
	if (equal(rw,"W"))
	{
		while ( (line=read_file(g_config,line,temp,96,txtleng))!=0)
		{
			parse(temp,sCommand,32,sValue,64);
			if (equal(sCommand,keys))
			{
				format(temp,96,"%s %s",keys,values);
				write_file(g_config,temp,line-1);
				iDone=1;
			}
		}
		if (iDone==0)
		{
			format(temp,96,"%s %s",keys,values);
			write_file(g_config,temp,-1);
		}
		return PLUGIN_CONTINUE;
	}
	if (equal(rw,"R"))
	{
		copy(g_data,64,"NONE");
		while ( (line=read_file(g_config,line,temp,96,txtleng))!=0)
		{
			parse(temp,sCommand,32,sValue,64);
			if (equal(sCommand,keys))
			{
				copy(g_data,64,sValue);
				return PLUGIN_CONTINUE;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

//this is made to calculate the period between two dates
public time_elapsed(iDateNow,iTimeNow,iDate,iTime)
{
	new i;
	new iYear;
	new iMonth;
	new iDay;
	new iHour;
	new iMinute;
	new iSecond;
	
	new iYearNow;
	new iMonthNow;
	new iDayNow;
	new iHourNow;
	new iMinuteNow;
	new iSecondNow;

	el_seconds=0;
	el_days=0;
	
	iDayNow=iDateNow%100;
	iMonthNow=iDateNow%10000/100;
	iYearNow=iDateNow/10000;
	
	iSecondNow=iTimeNow%100
	iMinuteNow=iTimeNow%10000/100;
	iHourNow=iTimeNow/10000;
	
	iDay=iDate%100;
	iMonth=iDate%10000/100;
	iYear=iDate/10000;
	
	iSecond=iTime%100
	iMinute=iTime%10000/100;
	iHour=iTime/10000;

	for (i=iYearNow+1;i<iYear;i++)
	{
		el_days+=365;
		if ((i%400==0)||((i%4==0)&&(i%100!=0)))
			el_days+=1;
	}

	if (iYearNow==iYear)//if they are the same year;
	{
		
		for (i=iMonthNow;i<iMonth;i++)
		{
			el_days+=day_of_month(i,iYear);
		}

	}
	else//if they are not the same year
	{
		for (i=iMonthNow;i<=12;i++)
		{
			el_days+=day_of_month(iMonth,iYear);
		}

		for (i=1;i<iMonth;i++)
		{
			el_days+=day_of_month(iMonth,iYear);
		}

	}
	
	el_days-=iDayNow;
	el_days+=iDay-1;
	
	el_seconds+=(iHour+24)*3600+iMinute*60+iSecond;
	el_seconds-=(iHourNow*3600+iMinuteNow*60+iSecondNow);
	if (el_seconds>=24*3600)
	{
		el_seconds-=24*3600;
		el_days+=1;
	}
	
	return PLUGIN_CONTINUE;
}

/*
this is made to show u the days of every month specified by the parameter
iMonth-an integer ,such as 1--January and 12---Decembery
iYear -an integer of 4 digits,such as 2004,1999,etc.
*/
public day_of_month(iMonth,iYear)
{
	new days;
	switch(iMonth)
	{
		case 1:days=31;
		case 2:
		{
			days=28;
			if ((iYear%400==0)||((iYear%4==0)&&(iYear%100!=0)))
				days+=1;
		}
		case 3:days=31;
		case 4:days=30;
		case 5:days=31;
		case 6:days=30;
		case 7:days=31;
		case 8:days=31;
		case 9:days=30;
		case 10:days=31;
		case 11:days=30;
		case 12:days=31;
	}
	return days;
}