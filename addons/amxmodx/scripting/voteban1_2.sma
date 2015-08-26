#include <amxmodx>
#include <amxmisc>

#define MAX_players 32
#define MAX_menudata 1024

new ga_PlayerName[MAX_players][32]
new ga_PlayerAuthID[MAX_players][35]
new ga_PlayerID[MAX_players]
new ga_PlayerIP[MAX_players][16]
new ga_MenuData[MAX_menudata]
new ga_Choice[2]
new gi_VoteStarter
new gi_MenuPosition
new gi_Sellection
new gi_TotalPlayers
new gi_SysTimeOffset = 0
new i
//pcvars
new gi_LastTime
new gi_DelayTime
new gf_Ratio
new gf_MinVoters
new gf_BF_Ratio
new gi_BanTime
new gi_Disable
new gi_BanType


public plugin_init()
{
  register_plugin("voteban menu","1.2","hjvl")
  register_clcmd("say /voteban","SayIt" )
  register_menucmd(register_menuid("ChoosePlayer"), 1023, "ChooseMenu")
  register_menucmd(register_menuid("VoteMenu"), 1023, "CountVotes")

  gi_LastTime=register_cvar("amx_voteban_lasttime","0")
  gi_DelayTime=register_cvar("amxx_voteban_delaytime","600")
  gf_Ratio=register_cvar("amxx_voteban_ratio","0.50")
  gf_MinVoters=register_cvar("amxx_voteban_minvoters","0.0")
  gf_BF_Ratio=register_cvar("amxx_voteban_bf_ratio","0.0")
  gi_BanTime=register_cvar("amxx_voteban_bantime","5")
  gi_Disable=register_cvar("amxx_voteban_disable","0")
  gi_BanType=register_cvar("amxx_voteban_type","0")
}

public SayIt(id)
{
  if(get_pcvar_num(gi_Disable))
  {
    client_print(id,print_chat,"[AMXX]amx_votaban disabled")
    return 0
  }

  new Elapsed=get_systime(gi_SysTimeOffset) - get_pcvar_num(gi_LastTime)
  new Delay=get_pcvar_num(gi_DelayTime)

  if( (Delay > Elapsed) && !is_user_admin(id) )
  {
    new seconds = Delay - Elapsed
    client_print(id,print_chat,"[AMXX] You have to wait %d seconds before a new voteban can be started", seconds)
    return 0
  }

  get_players( ga_PlayerID, gi_TotalPlayers )
  for(i=0; i<gi_TotalPlayers; i++)
  {
    new TempID = ga_PlayerID[i]
    if( is_user_admin(TempID))
    {
      if(!is_user_admin(id))
      {
        client_print(id,print_chat,"There is an admin on the server, voting is disabled!")
        return 0
      }
    }

    if(TempID == id)
      gi_VoteStarter=i

    get_user_name( TempID, ga_PlayerName[i], 31 )
    get_user_authid( TempID, ga_PlayerAuthID[i], 34 )
    get_user_ip( TempID, ga_PlayerIP[i], 15, 1 )
  }

  gi_MenuPosition = 0
  ShowPlayerMenu(id)
  return 0
}

public ShowPlayerMenu(id)
{
  new arrayloc = 0
  new keys = (1<<9)

  arrayloc = format(ga_MenuData,(MAX_menudata-1),"voteban menu ^n")
  for(i=0; i<8; i++)
   if( gi_TotalPlayers>(gi_MenuPosition+i) )
   {
     arrayloc += format(ga_MenuData[arrayloc],(MAX_menudata-1-arrayloc),"%d. %s^n", i+1, ga_PlayerName[gi_MenuPosition+i])
     keys |= (1<<i)
   }
  if( gi_TotalPlayers>(gi_MenuPosition+8) )
  {
    arrayloc += format(ga_MenuData[arrayloc],(MAX_menudata-1-arrayloc),"^n9. More")
    keys |= (1<<8)
  }
  arrayloc += format(ga_MenuData[arrayloc],(MAX_menudata-1-arrayloc),"^n0. Back/exit")

  show_menu(id, keys, ga_MenuData, 20, "ChoosePlayer")
  return PLUGIN_HANDLED 
}

public ChooseMenu(id, key)
{
  switch(key)
  {
    case 8:
    {
      gi_MenuPosition=gi_MenuPosition+8
      ShowPlayerMenu(id)
    }
    case 9:
    {
      if(gi_MenuPosition>=8)
      {
        gi_MenuPosition=gi_MenuPosition-8
        ShowPlayerMenu(id)
      }
      else
        return 0
    }
    default:
    {
      gi_Sellection=gi_MenuPosition+key
      new Now=get_systime(gi_SysTimeOffset)
      set_pcvar_num(gi_LastTime, Now)

      run_vote()
      return 0
    }
  }
  return PLUGIN_HANDLED
}

public run_vote()
{
  log_amx("Vote ban started by %s for %s %s", ga_PlayerName[gi_VoteStarter], ga_PlayerName[gi_Sellection], ga_PlayerAuthID[gi_Sellection])
  format(ga_MenuData,(MAX_menudata-1),"Ban %s for %d minutes?^n1. Yes^n2. No",ga_PlayerName[gi_Sellection], get_pcvar_num(gi_BanTime))
  ga_Choice[0] = 0
  ga_Choice[1] = 0
  show_menu( 0, (1<<0)|(1<<1), ga_MenuData, 15, "VoteMenu" )
  set_task(15.0,"outcom")
  return 0
}

public CountVotes(id, key)
{
  ++ga_Choice[key]
  return PLUGIN_HANDLED
}

public outcom()
{
  new TotalVotes = ga_Choice[0] + ga_Choice[1]
  new Float:result = (float(ga_Choice[0]) / float(TotalVotes))

  if( get_pcvar_float(gf_MinVoters) >= ( float(TotalVotes) / float(gi_TotalPlayers) ) )
  {
    client_print(0,print_chat,"[AMXX] Not enough voters to ban %s!", ga_PlayerName[gi_Sellection])
    return 0
  }
  else
  {
    if( result < get_pcvar_float(gf_BF_Ratio) )
    {
      client_print(0,print_chat,"[AMXX] The vote back fired at %s, he is banned for %d minutes", ga_PlayerName[gi_VoteStarter], get_pcvar_num(gi_BanTime))
      ActualBan(gi_VoteStarter)
      log_amx("[AMXX] The vote back fired at %s, he is banned for %d minutes", ga_PlayerName[gi_VoteStarter], get_pcvar_num(gi_BanTime))
    }

    if( result >= get_pcvar_float(gf_Ratio) )
    {
      client_print(0,print_chat,"[AMXX] The vote succeeded, %s is banned for %d minutes", ga_PlayerName[gi_Sellection], get_pcvar_num(gi_BanTime))
      log_amx("[AMXX] The vote succeeded: %s is banned for %d minutes", ga_PlayerAuthID[gi_Sellection], get_pcvar_num(gi_BanTime))
      ActualBan(gi_Sellection)
    }
    else
    {
      client_print(0,print_chat,"[AMXX] The vote did not succeeded!")
      log_amx("[AMXX] The voteban dit not sucseed.")
    }
  }
  client_print(0,print_chat,"A total of %d players, %d voted yes.", gi_TotalPlayers, ga_Choice[0])

  return 0
}

public ActualBan(Selected)
{
  new Type = get_pcvar_num(gi_BanType) 
  switch(Type)
  {
    case 1:
      server_cmd("addip %d %s", get_pcvar_num(gi_BanTime), ga_PlayerIP[Selected])
    case 2:
      server_cmd("amx_ban %d %s Voteban", get_pcvar_num(gi_BanTime), ga_PlayerAuthID[Selected])
    default:
      server_cmd("banid %d %s kick", get_pcvar_num(gi_BanTime), ga_PlayerAuthID[Selected])
  }
  return 0 
}