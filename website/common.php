<?php
session_start();
ini_set( 'default_charset', 'UTF-8' );
header( 'Content-Type: text/html; charset=utf-8' );

// calcula a largura da tela do usuario para se poder exibir a versao de 1300px ou a de 800px
if( isset( $_SESSION[ 'screen_width' ] ) AND isset( $_SESSION[ 'screen_height' ] ) )
{
    //echo $_SESSION['screen_width'] . 'x' . $_SESSION['screen_height'];
} else
{
    if( isset( $_REQUEST[ 'width' ] ) AND isset( $_REQUEST[ 'height' ] ) )
    {
        $_SESSION[ 'screen_width' ] = $_REQUEST[ 'width' ];
        $_SESSION[ 'screen_height' ] = $_REQUEST[ 'height' ];
        header( 'Location: ' . $_SERVER[ 'PHP_SELF' ] );
    } else
    {
        echo '<script type="text/javascript">
                  window.location = "' . $_SERVER[ 'PHP_SELF' ] . '?width=" + screen.width + "&height=" + screen.height;
             </script>';
    }
}

header( 'Cache-control: private' ); // IE 6 FIX

if( isSet( $_GET[ 'lang' ] ) )
{
    $lang = $_GET[ 'lang' ];

    // register the session and set the cookie
    $_SESSION[ 'lang' ] = $lang;

    setcookie( "lang", $lang, time() + ( 3600 * 24 * 3600 ) );
} else
{
    if( isSet( $_SESSION[ 'lang' ] ) )
    {
        $lang = $_SESSION[ 'lang' ];
    } else
    {
        if( isSet( $_COOKIE[ 'lang' ] ) )
        {
            $lang = $_COOKIE[ 'lang' ];
        } else
        {
            if( isSet( $_SERVER[ 'HTTP_ACCEPT_LANGUAGE' ] ) )
            {
                $lang = substr( $_SERVER[ 'HTTP_ACCEPT_LANGUAGE' ], 0, 2 );
            } else
            {
                $lang = 'en';
            }
        }
    }
}

switch( $lang )
{
case 'pt':
    $lang_file = 'lang.pt.php';
    break;

default:
    $lang_file = 'lang.en.php';
}

?>