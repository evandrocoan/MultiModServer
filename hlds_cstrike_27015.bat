echo -pingboost <1/2/3> - Selects between optimized HLDS network code stack. 
echo Set this on 2 usually reduces latency toward 1ms without loss of activity 
echo input packets.
echo use 1 or 2 for normal pingboost, use 3 for pretty damn good ping boost 
echo at cost of crazy amounts of CPU .... I would recommend -pingboost 1, 
echo it works ok. 3 topped my CPUs at full server and that cause lag also lol.
echo 
start hlds.exe -console -game cstrike -pingboost 3 +log off -condebug -noaff -secure +map de_dust2 +maxplayers 32 +port 27015
exit