/* Copyright (C) 2FuR!uS
* 
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/
#include <amxmodx>
#include <amxmisc>
#include <engine>

new mp3_nbr=1
new mp3_track=1
new mp3_playlist[30][64]

public plugin_init(){
  register_plugin("Mp3 Player","1.1","2FuR!uS")
  register_dictionary("mp3player.txt")
  new mp3_menu_title[128]
  format(mp3_menu_title, 127, "%L",LANG_PLAYER,"MP3_MENU_TITLE")
  register_menucmd(register_menuid(mp3_menu_title),1023,"mp3Choice")
  new mp3_help[128]
  format(mp3_help, 127, "%L",LANG_PLAYER,"MP3_HELP")
  register_clcmd("say /mp3","mp3Menu",0,mp3_help)

  register_clcmd("say /next","mp3Next",0,mp3_help)
  register_clcmd("say /prev","mp3Prev",0,mp3_help)
  register_clcmd("say /stop","mp3Stop",0,mp3_help)

  return PLUGIN_CONTINUE
}

public mp3Play(id){
  client_cmd(id,"mp3 play %s", mp3_playlist[mp3_track])
  client_print(id, print_chat, "%L",LANG_PLAYER,"MP3_PLAY", mp3_playlist[mp3_track], mp3_track, mp3_nbr)
}
public mp3Stop(id){
  client_cmd(id,"mp3 stop")
  client_print(id, print_chat, "%L",LANG_PLAYER,"MP3_STOP")
  mp3_track = 1
}
public mp3Next(id){
  mp3_track++
  if ( mp3_track == (mp3_nbr+1) ) mp3_track = 1
  mp3Play(id)
}
public mp3Prev(id){
  mp3_track--
  if ( mp3_track == 0 ) mp3_track = mp3_nbr
  mp3Play(id)
}

public plugin_precache(){
  new mp3_file[128]
  new length
  new playlist_ini_file[64]
  new mp3_line
  get_configsdir(playlist_ini_file, 63)
  format(playlist_ini_file, 63, "%s/playlist.ini", playlist_ini_file)
  if (file_exists( playlist_ini_file )){ 
    while(read_file( playlist_ini_file,mp3_line++,mp3_file,sizeof(mp3_file),length)){
      if (mp3_file[0] == ';') continue
      if (equali(mp3_file,"")) continue
      if (equali(mp3_file," ")) continue
      if (mp3_file[0] == '/' && mp3_file[1] == '/') continue
      format(mp3_playlist[mp3_nbr],sizeof(mp3_playlist)-1,"%s",mp3_file)
      precache_generic(mp3_file)
      mp3_nbr++
    }
  } else
    server_print("[MP3]ERROR! : The playlist (%s) can t be loaded",playlist_ini_file)
  server_print("[MP3]Loaded %d musics from %s",mp3_nbr,playlist_ini_file)
  mp3_nbr--
  return PLUGIN_CONTINUE
}
public mp3Menu(id){
  new menuBody[1024] 
  new key
  format(menuBody, 1023, "\r%L\R^n^n\y1.\w %L^n\y2.\w %L^n\y3.\w %L^n\y4.\w %L^n\y5.\w %L",LANG_PLAYER,"MP3_MENU_TITLE",LANG_PLAYER,"MP3_MENU_PLAY",LANG_PLAYER,"MP3_MENU_STOP",LANG_PLAYER,"MP3_MENU_NEXT",LANG_PLAYER,"MP3_MENU_PREV",LANG_PLAYER,"MP3_MENU_EXIT")
  key = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)
  show_menu(id, key, menuBody)
}
public mp3Choice(id, key){
  switch(key){
    case 0:
      mp3Play(id)
    case 1:
      mp3Stop(id)
    case 2:
      mp3Next(id)
    case 3:
      mp3Prev(id)
    case 4:
      return PLUGIN_HANDLED
  }
  return PLUGIN_HANDLED
}