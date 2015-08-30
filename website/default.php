<?php
include_once 'common.php';
include_once 'default.' . $lang_file;
?>
<!doctype html>
<html itemscope itemtype="http://schema.org/Product">
<head>
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js">
        </script>
    <![endif]-->
    <meta charset="UTF-8">
    <meta name="Generator" content="Dreamweaver">
    <meta name="author" content="">
    <meta name="robots" content="index, follow">
    <meta name="Generator" content="Dreamweaver">
    <meta name="author" content="">
    <meta name="viewport" content="width=640;">
    <meta name="robots" content="index, follow">
    <meta name="keywords"content="addons, zz.mu, zz, mu, cs, cs 1.6, 1.6, counter-trike, counter strike condition zero, condition zero, condition-zero,counter-strike 1.6, counter strike 1.6, amx mod x, amxmodx, amx mod, super heros, super-heros, command menu, commandmenu, metamod, podbot, desempenho, ping, lag, add-in, linux, windows, mac, os, mac os">
    <meta itemprop="image" content="http://addonsmultimod.zz.mu/Addons_zz.mu_1300x231.png">
    <link rel="stylesheet" type="text/css" href="default.layout.css">
    <?php echo $lang[ 'HEADER' ] ?>

    <script>
    function ajustarConteudo() 
    {
        var w = window.outerWidth;
        var conteudoPrincipal = document.getElementById("conteudoPrincipal");
        var descricaoInicial = document.getElementById("descricaoInicial");
        var barraDoIdioma = document.getElementById("barraDoIdioma");
        var conteinerDoLogo = document.getElementById("conteinerDoLogo");
        var imagemGrande = "<img src=\"Addons_zz.mu_1300x231.png\" width=\"1300\" height=\"231\">";
        var imagemPequena = "<img src=\"Addons_zz.mu_600x107.png\" width=\"600\" height=\"107\">";

        if( w < 1366 )
        {
            document.getElementById("logoPrincipal").innerHTML = imagemPequena;
            conteudoPrincipal.style.width = "620px";
            descricaoInicial.style.maxWidth = "620px";
            descricaoInicial.style.width = "620px";
            barraDoIdioma.style.width = "620px";
            conteinerDoLogo.style.minHeight = "107px";
            
        } else
        {
            document.getElementById("logoPrincipal").innerHTML = imagemGrande;
            conteudoPrincipal.style.width = 98 + "%";
            descricaoInicial.style.maxWidth = "1300px";
            descricaoInicial.style.width = 98 + "%";
            barraDoIdioma.style.width = "1300px";
            conteinerDoLogo.style.minHeight = "231px";
            
        }
    }
    </script>
</head><body onresize="ajustarConteudo()" onload="ajustarConteudo()">
 
<?php echo $lang[ 'MENU_PRINCIPAL' ] ?>

<div align="center" style="text-align: center; margin: 0 auto; word-wrap:break-word; text-wrap:unrestricted; ">
    <p><table id="descricaoInicial" border="0px" style="margin: 0 auto; ">
    <tr><td class="pre" align="center">
        <?php echo $lang[ 'DESCRICAO_INICIAL' ] ?>
    </td></tr>
    </table></p>
</div>

<div id="conteudoPrincipal" align="center" style="display: table; max-width: 1360px; width:98%; text-align: center; margin: 0 auto; align-content:center;word-wrap:break-word;">
    
    <div class="corDaBorda" align="center" style="border-style:double; padding-left:10px; max-width: 620px; float:left; text-align:left; padding-bottom:5px; word-wrap:break-word;">
        <?php echo $lang[ 'PRIMEIRA_COLUNA' ] ?>
    </div>
    
    <div class="corDaBorda" align="center" style="border-style:double; padding-left:10px; max-width: 620px; float: right; text-align:left; word-wrap:break-word;">
        <?php echo $lang[ 'SEGUNDA_COLUNA' ] ?>
    </div>
</div>

<br>
<div align="center" style="display: table; max-width: 1360px; width:98%; text-align: center; margin: 0 auto; align-content:center;">
    <a href="http://www.fraudlog.com/" target="_blank">
    <img src="//www.fraudlog.com/tracker/1600|1437172524|300*200*1*1*7|FFE98F*00364A|1*1*1/4684NR-IPIB/14028/2/njsUrl/" 
    alt="auction fraud block" style="border:0px;"></a>
    <span style="padding-right:50px"></span>
    <a href="http://www.hostinger.com.br/" target="_blank"><img src="http://hostinger.com.br/banners/br/hostinger-125x125-powered-1.gif" alt="Hospedagem" border="0" width="125" height="125"/></a>
    <br>
    <br>
    <span class="textoForte">__«^‿^»__ <a href="https://github.com/Addonszz">website by: Addons zz</a> __«~‿~»__
    </span>
</div>

<p>&nbsp;</p>

<p>&nbsp;</p>

</body>
</html>
