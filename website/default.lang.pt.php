<?php
/* 
------------------
Language: PORTUGUESE
------------------
*/

$lang = array();

$lang[ 'HEADER' ] = <<<EOD
    <meta name="description"content="O Addons Multi-Mod é um add-in para o jogo Counter-Strike e Counter-Strike Condition Zero. O Multi-Mod contém inúmeros mods e vem por padrão configurado para o máximo desempenho e controle do servidor.">
    <title>Addons Multi-Mod - Para Counter-Strike - CS</title>
    <meta itemprop="name" content="Addons Multi-Mod - Para Counter-Strike - CS">
    <meta itemprop="description"content="O Addons Multi-Mod é um add-in para o jogo Counter-Strike e Counter-Strike Condition Zero. O Multi-Mod contém inúmeros mods e vem por padrão configurado para o máximo desempenho e controle do servidor.">
EOD;

$lang[ 'MENU_PRINCIPAL' ] = <<<EOD
<div id="barraDoIdioma" style="text-align:left; margin: 0 auto; ">Language/Idioma: 
    <a href="default.php?lang=en">English</a>
    - - 
    <a href="default.php?lang=pt">Português</a>
</div>
<div id="conteinerDoLogo" align="center" style="display: table; min-height:150px; max-width: 1360px; width:98%; text-align: center; margin: 0 auto; align-content:center; ">
    <a href="http://www.addons.zz.mu/">
    <span id="logoPrincipal"></span></a>
</div>
EOD;

if( $_SESSION['screen_width'] < 800 )
{
$lang[ 'MENU_PRINCIPAL' ] = $lang[ 'MENU_PRINCIPAL' ] . <<<EOD
<div class="tableContainer " style="border:double; margin: 0 auto; border-color:#232323; ">
    <div id="tableRow">
        <div class="tableColumn " style="border-right:double; border-bottom:double; padding:5px; border-color:#232323; ">
            <a href="http://www.addons.zz.mu/"><b>Página Inicial</b></a>
        </div>
        <div class="tableColumn " style="border-bottom:double; padding:5px; border-color:#232323; ">
            <a href="https://github.com/Addonszz/AddonsMultiMod/issues"><b>Fórum - Dúvidas - Requisitar Recursos</b></a>
        </div>
    </div>
    <div id="tableRow">
        <div class="tableColumn " style="border-right:double; border-color:#232323; padding:5px; ">
            <a href="#installation"><b>Instalação</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; border-color:#232323; padding:5px; ">
            <a href="https://github.com/Addonszz/AddonsMultiMod/releases"><b>Downloads</b></a>
        </div>
        <div class="tableColumn " align="center" style="padding:5px; border-color:#232323; ">
            <a href="https://github.com/Addonszz"><b>Contato</b></a>
        </div>
    </div>
</div>
EOD;
} else 
{
$lang[ 'MENU_PRINCIPAL' ] = $lang[ 'MENU_PRINCIPAL' ] . <<<EOD
<div class="tableContainer " style="border:double; margin: 0 auto; border-color:#232323;">
    <div id="tableRow">
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="http://www.addons.zz.mu/"><b>Página Inicial</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="https://github.com/Addonszz/AddonsMultiMod/issues"><b>Fórum - Dúvidas - Requisitar Recursos</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="#installation"><b>Instalação</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="https://github.com/Addonszz/AddonsMultiMod/releases"><b>Downloads</b></a>
        </div>
        <div class="tableColumn " style="padding:5px; border-color:#232323;">
            <a href="https://github.com/Addonszz"><b>Contato</b></a>
        </div>
    </div>
</div>
EOD;
}

$lang[ 'DESCRICAO_INICIAL' ] = <<<EOD
O Addons Multi-Mod é um add-in para o jogo &quot;Counter-Strike&quot; e &quot;Counter-Strike: Condition Zero&quot;.
<p>
O Addons Multi-Mod contém inúmeros mods e vem por padrão configurado para o máximo desempenho e controle do servidor.</p>
EOD;

$lang[ 'PRIMEIRA_COLUNA' ] = <<<EOD
<p><span style="font-size:40px">Sobre Addons Multi-Mod? Veja aqui:</span>
<p><a href="https://github.com/Addonszz/AddonsMultiMod">https://github.com/Addonszz/AddonsMultiMod</a></p>
</p>
<p><span style="font-size:40px">Sobre Amx Ultra? Veja aqui:</span>
<p><a href="https://github.com/Addonszz/Amx_Ultra">https://github.com/Addonszz/Amx_Ultra</a></p>
</p>
<p>Notas básicas sobre a última versão do <strong><font color="red"><u>Addons Multi-Mod v2.0</u></font></strong>
    lança no dia 16/08/2015:</p>
* Galileo 1.1.290 que é um plugins cheio de recursos para votar o próximo mapa.<br>
* Agora nos últimos 5 minutos ou se solicitado antes uma votação pelo comando "say votemod", cria uma votação para selecionar qual será o Mod jogado no próximo mapa.<br>
* Desenvolvimento de um sistema de menu votemod multi-página para exibir até 100 mods.<br>
* Adicionado um arquivo currentmod.ini para salvar atual id mod ativa e carregá-lo na inicialização do servidor.<br>
<p><img src="recursos/2015-08-16_14-08_Counter-Strike.jpg" width="600" ></p>
<p><img src="recursos/2015-08-16_14-08_Counter-Strike(2).jpg" width="600" ></p>
* Altera a mapcycle, se e somente se uma mapcycle costume mod foi criada.<br>
* Feito o votemod manter o mod atual, se menos de 30% de jogadores votaram.<br>
* Feito "Estender mapa atual" logo após escolher, não para reiniciar o jogo para o mapa atual.<br>
* Feito armazenar o Mod atual no arquivo "currentmod.ini".<br>
* Mensagem mod atual Corrigido.<br>
* Quando o tempo min voto não for atingido/desativado, display e mensagem informando isso.
    
<p>Versão do <strong><font color="red"><u>Addons Multi-Mod v1.5</u></font></strong>
    lança no dia 12/08/2015:<br>
 
* Adicionado Dragon Ball Mod v1.3<br>
* Novo multi-mod_core com melhor controle de servidor.<br>
* Corrigido a incompatilidade do plugin daily_maps com nextmap.<br>
* Posição multi-mod_plugin e informação a seu originais plugins nextmap e cmdmenus.</p>

<p>Versão do <strong><font color="red"><u>Addons Multi-Mod v1.4</u></font></strong>
    lança no dia 10/08/2015:<br>

* Adicionado plugins pain_shock_free que desativa o andar devagar ao levar tiros.<br>
* Adicionado novo Command Menu (tecla h do jogo) com suporte a:<br>
* Ativação do Superheros Mod, Predator Mod, Knife Arena Mod
e Ultimate Warcraft Mod.<br>
* Maior controle do server como terminar o round em empate, ou com os
CT's ou TR's ganhando.

<p><img src="recursos/2015-07-28_05-18_Untitled.jpg" width="362" height="424" alt=""/></p>

* Binds configuradas como walk-continue e fast-change.<br>
* Ativação do PODBot e comandos do Superheros Mod.<br>
* Acesso ao top 15, tempo restante do mapa e mapa atual.<br>
* Controle das configurações do PODBots como cota, time,
dificuldade, matar, retirar, modo de armas e etc...<br>
* Mudança de gravidade, fogo amigo, equilibrio de times, limite de times, ...</p>

<p><img src="instalacao/2015-07-27_04-02_Counter-Strike.jpg" width="360" height="334"></p>

* Adicionado suporte a servers linux e windows.<br>
* Adicionado suporte ao PODBot para MAC OS, Linux e Windows.<br>
* Adicionado suporte ao Zombie Plague Mod 5.08a<br>
* Adicionado suporte ao Superheros Mod 1.2.1<br>
* Adicionado suporte ao CSDM (Death-Match) v2.1.3c<br>
* Adicionado suporte ao Gun-Game Mod v2.13c<br>
* Adicionado suporte ao Predator Mod_B2 2.1<br>
* Adicionado suporte ao Ultimate Warcraft Mod 3<br>
* Adicionado suporte ao Knife Arena Mod 1.2<br>
* Adicionado arquivo hlds.bat e hlds.sh para criar um servido por linha de comando em windows em Linux.

<p><img src="recursos/2015-07-28_04-18_Half-Life.jpg" width="465" height="118" alt=""/></p>

*** Adicionado todos os código fontes utilizados:<br>
* Um total de 450 plugins com sources.<br>
* player_wanted que paga recompensas pelos CT's e TR's mais procurados.<br>
* amx_plant_bonus que dá um bonus em dinheiro, a quem plantar a C4.<br>
* Amx Mod X 1.82 e PODBot V3.0 metamod Build 22.<br>
* usurf que fornece ajuda e outras coisas para mapas surf.<br>
* cssurfboards que adiciona uma prancha de surf, (amx_createnpc).

<p><img src="recursos/2015-07-28_03-39_Counter-Strike.jpg" width="607" height="711" alt=""/></p>

* lastmanbets Plugin de apostas, quando sobram 1x1.<br>
* BombSite_Radar para ver onde estão os locais de plantar a bomba<br>
* bad_camper que pune quem faz camper indiscriminadamente.<br>
* multi-mod_core, amx_exec, head_shot_announcer, grentrail, parachute, knife_duel, amx_chicken,
adv_killstreak, countdown_exec, ...<br>
* Portando possível total modificação dos recursos
disponíveis do addons.

<p><a href="https://github.com/Addonszz/AddonsMultiMod/blob/master/gamemod_common/addons/amxmodx/configs/plugins.ini">Veja mais informações aqui.</a></p>
EOD;

$lang[ 'SEGUNDA_COLUNA' ] = <<<EOF
<p>Ele funciona em <a name="installation"><strong><font color="red"><u>Counter-Strike e Counter-Strike Condition Zero</u></font></strong></a> atualizado.</p>

<p><span style="font-size:66px">Para instalá-lo</span><br> 
Baixar os binários 
<a href="https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_plugin.zip">amx_ultra_plugin.zip</a>, 
<a href="https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_resources.zip">amx_ultra_resources</a>, 
<a href="https://github.com/Addonszz/AddonsMultiMod/releases/download/v4.0/addons_resources.zip">addons_resources.zip</a>, 
<a href="https://github.com/Addonszz/Amx_Ultra/archive/master.zip">Amx_Ultra-master.zip</a> 
e 
<a href="https://github.com/Addonszz/AddonsMultiMod/archive/master.zip">AddonsMultiMod-master.zip</a>, 
e então basta descompactar e copiar o conteúdo da pasta cstrike ou czero e gamemod_common para a sua pasta cstrike ou czero do seu jogo, 
substituindo os arquivos existentes. A pasta cstrike ou czero do jogo geralmente fica em:</p>

<p><u>C:\Arquivos de Programas (x86)\Steam\SteamApps\common\Half-Life\cstrike</u></p>
<p><u>C:\Arquivos de Programas (x86)\Steam\SteamApps\common\Half-Life\czero</u></p>

<p>Após instalar o addons, basta configurar o seu STEAM ID usuário. </p>

<p>Para isso abra o arquivo: </p>

<p>***users (user.ini) na pasta gamemod/addons/amxmodx/configs</p>

<p>Após instalar o addons, basta configurar sua senha RCON. 

<p>***autoexec (autoexec.cfg) na pasta gamemod. </p>

<p>E siga as instruções contidas neles. </p>

<p>Nota 1: Para utilizar o commandmenu (h tecla no jogo). Cada administrador 
do server deveria ter os arquivos de código fonte (Source Code Zip) acima instalado,
em sua própria cópia do jogo, ou apenas a pasta "gamemod_common/admin" e
o arquivo "gamemod_common/commandmenu.txt".</p>

<p>Nota 2: A SENHA do arquivo podbotconfig.cfg na sua pasta gamemod, serve para criar
    waypoint utilizando o linstenserver ( jogo offline pelo new game ) e adicionar podbots. Mas quem tem
    autenticação rcon também pode controlar os podbots.</p>

<p>Caso tenha problemas em configurar o servidor, o este é um incrível tutorial
    de como configurar um servidor Steam atualizado que funciona com qualquer tipo de cliente:</p>

<p>
    <a href="http://translate.google.com.br/translate?hl=pt-BR&sl=en&u=http://steamcommunity.com/sharedfiles/filedetails/?id=340974032">http://steamcommunity.com/sharedfiles/filedetails/?id=340974032</a>
</p>

<p>
    <a href="http://translate.google.com.br/translate?hl=pt-BR&sl=en&u=https://developer.valvesoftware.com/wiki/SteamCMD">https://developer.valvesoftware.com/wiki/SteamCMD</a>
</p>

EOF;
?>