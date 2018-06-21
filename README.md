# Sudoers_parser
Sudoers parser in PERL
Script is designed in PERL – the main purpose is parse sudoers file into following output:

User Name ; User Alias - if exists ; As User ; Command Alias ; Command ; PASSWORD pw_flag ; Commands excluded;

Desription of fileds:

1. User Name
2. User Alias - if exists
3. As User
4. Command Alias
5. Command
6. PASSWORD pw_flag
7. Commands excluded

All data are sorted by each command per each user

To run script:
cat /etc/sudoers | ./sudo_parser.pl

Remarks:
Script must take into account the difficulties associated with:
The number of records is not constant no fixed, uniform separators, include an exception

Example output:

%rhevuser;;ALL;;ALL;NOPASSWD;;
+linas;USR_RMDS;root;SURMDS;/bin/su command;NOPASSWD;;
+linas;USR_RMDS;root;SURMDS;/bin/su - command;NOPASSWD;;
+oper;USR_RMDS;root;SURMDS;/bin/su command;NOPASSWD;;
+oper;USR_RMDS;root;SURMDS;/bin/su - command;NOPASSWD;;
+unixadm;;root;SHELLS;;NOPASSWD;/bin/sh;
+unixadm;;root;SHELLS;;NOPASSWD;/bin/bash;
+unixadm;;root;SHELLS;;NOPASSWD;/bin/csh;
+unixadm;;root;SHELLS;;NOPASSWD;/bin/ksh;
+unixadm;;root;SHELLS;;NOPASSWD;/bin/tcsh;
+unixadm;;root;;ALL;NOPASSWD;;
+unixadm;USR_RMDS;root;SURMDS;/bin/su command;NOPASSWD;;
+unixadm;USR_RMDS;root;SURMDS;/bin/su - command;NOPASSWD;;
anho;;root;MAREK;/bin/su xxl;NOPASSWD;;
anho;;root;MAREK;/bin/su -XXL;NOPASSWD;;
anho;;root;;/install/utils/restorePKGsFromPKGlist;NOPASSWD;;
anho;;root;;/install/utils/restorePKGsFromPKGlist *;NOPASSWD;;
anho;;root;;/usr/bin/ANHA;NOPASSWD;;
ex52576;;ALL;;ALL;PASSWD;;
user1;;ALL;;ALL;PASSWD;;
user2;;ALL;;MAREK12;PASSWD;;
lolo;;root;;/install/utils/restorePKGsFromPKGlist *;NOPASSWD;;
lolo;;root;;/usr/bin/ANHO;NOPASSWD;;
zabbix;ZABBIX;ALL;;CMD_zabbixUAL_ZABBIX;NOPASSWD;;
zabbix;ZABBIX;ALL;;;NOPASSWD;/COSTAM/ll;

Remark:
Additionally sudo_parser script with netgroup will develop all netgroups into users
