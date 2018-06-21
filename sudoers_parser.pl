#!/usr/bin/perl -w
# Description : Parser for SUDOERS file
# _Author  : Andrzej Hochbaum
# Date    : 13.11.2017
# Version : v1.01
#
use warnings;
#
# -----> First parse STDIN
$input="";
foreach $line (<>)                                                      # STDIN
{
        if ( $line =~ /^$/ || $line =~ /^#/ ) {} else {                 # Reduction empty and comments line
        $line =~ s/\`//g;                                               # Reduction sign "`"
        $line =~ s/[\t ]+$//;                                           # Removes spaces, TAB from the end of line
        $line =~ s/NOEXEC:/!/g;
        #
        $last5s = substr($line, -10);                                                   # Statement IF last 5 signs contain "\" and doesnt contain "," and "="
        $last5s =~ s/^\s+//;                                                            # add "NO-COMMA," before "\"

                if ($line !~ /\=/ && $last5s =~ /\\/ && $last5s !~ /,/) {
                        $line =~ s/\\/NO-COMMA,\\/g;
                }
        #
        $input = ($input . $line ) };
}
@p_input = `echo "$input" | while read  line ; do echo "\$line" ; done`;        # Concatenation of lines - BASH

# <-- End parse STDIN

# -----> Preparing array in case of occurrence "PASSWD" in a line more that one time   #####

@passwd_tmp = grep { /PASSWD/ } @p_input;                       # Array - Core PASSWORD pattern
#
# Preparing array in case of occurrence "PASSWD" in a line more that one time
$all_passwd = "";
foreach $pline (@passwd_tmp) {
  if ($pline !~ /^$/) {
        ($partpas1) = $pline =~ /([^:]*)/;                                      # Part one - example: +netgroup  ALL=(ALL) NOPASSWD
        ($partpas2) = $pline =~ /:(.+)$/;                                       # Part two - example: CMD_USER,NOPASSWD:RM,NPASSWD:CMD_ALIAS,NOPASSWD:command
                                                                                # If partpas2 contain "PASSWD" - repeat line with every PASSWD
         if ($partpas2 !~ /PASSWD/) {
                $fpwline = $pline;
                $all_passwd = ("$all_passwd" . "$fpwline\n");
         } else {
                if ($partpas1 =~ /NOPASSWD/) {
                         $pwd = "NOPASSWD" ;                                    # Definition of the last word from partpas1 (need to be replace for second part
                } else { $pwd = "PASSWD" }
                #
                foreach $npwd (split /,/, $partpas2)  {
                        if ($npwd !~ /PASSWD/) {                                # Statement for first parameter without stentence "PASSWD" ex: CMD_Alias
                                $tpline = $npwd;
                                $tpline =~ s/^\s+//;
                                $fpwline = ("$partpas1" . ":" . "$tpline\n");   # Needed output - +oraadm  ALL=(ALL) NOPASSWD:CMD_Alias
                                $all_passwd = ("$all_passwd" . "$fpwline\n");
                        } else {
                                $tpline = $npwd;
                                $tpline =~ s/^\s+//;                            # Delete spaces at the beginning
                                #
                                if ($tpline =~ /\(/ && $tpline =~ /\)/) {       # If string contain () - example: "(user) NOPASSWD: SU"
                                        ($nawp2) = $tpline =~ /\((\w+)\)/;      # Obtain string between ()
                                        if ( $partpas1 !~ /\(/ &&  $partpas1 !~ /\)/) {
                                                $fpwline = $partpas1;
                                                $fpwline  =~ s/$pwd/$tpline/g;                  # Replacing last word from partpas1 on the part2-$tpline
                                                $all_passwd = ("$all_passwd" . "$fpwline\n");
                                        } else {
                                                ($nawp1) = $partpas1 =~ /\((\w+)\)/;    # Obtain string between () from $partpas1;
                                                $pwline = $partpas1;
                                                ($pwline) =~ s/\($nawp1\)/\($nawp2\)/g;   # Replace string 1 on the string 2
                                                $tpline =~ s/\($nawp2\)//g;             # remove from tpline "(string)" - eg. "(rmds) NOPASSWD: SU" on " NOPASSWD: SU"
                                                $fpwline = $pwline;
                                                $fpwline  =~ s/$pwd/$tpline/g;                  # Replacing last word from partpas1 on the part2-$tpline
                                                $all_passwd = ("$all_passwd" . "$fpwline\n");
                                        }
                                }
                        }
                }
        }
  }
}
@a_passwd = split /^/m ,$all_passwd;                    # Create array @p_comm_al
@a_passwd = grep(/S/, @a_passwd);                       # Remove empty lines from Array
undef @passwd_tmp;                                      # Destroy Array @passwd_tmp
#
#<-- END: Preparing array in case of occurrence "PASSWD" in a line more that one time   #####



# -----> Create main ARRAYS
#
@a_user_al = grep { /User_Alias/ } @p_input;            # Array - User Alias
@a_comm_al = grep { /Cmnd_Alias/ } @p_input;            # Array - Command Alias
undef @p_input;                                         # Destroy Array p_input
#
# <-- End


# ----->  Users, Users alias - creating list of real users

$user_alias="";
foreach $n (@a_user_al) {
        ($part1) = $n =~ /^(.+)=/;                      # Separate string to substring from ^  to "="
         $part1 =~ s/[\t ]+$//;
        ($part2) = $n =~ /=(.+)$/;                      # Separate string to substring from "=" to END
        $part2 =~ s/ //g;                               # Remove spaces
        $user_alias = (split ' ', $part1)[-1];          # Print last word from substring - User Alias
        @users = split(',', $part2);                    # Array - list of users
        @{$user_alias} = (@users);                      # Array User_Alias ans assigned users
}

# -> IF we have some names divided by coma - split them and assign to each rest of line
$usr_input="";
foreach $nline (@a_passwd) {
        $name = (split ' ', $nline)[0];                 # $name -  first record in core array @a_passwd
        if ( $name =~ /,/ ) {
                @split_names = split(',', $name);
                foreach $n_names (@split_names) {
                        $tmp_n = $nline;
                        $tmp_n =~ s/"$name"/"$n_names"/g;
                        $usr_input = ("$usr_input" . "$tmp_n");
                        }
                }
        else    {
                $tmp_n = $nline;
                $usr_input = ("$usr_input" . "$tmp_n");
        }
}
# <-


# ->  Check if names is Alias or not and list of real users and rest of line
$fin_usr="";
foreach $sline (split /^/, $usr_input) {
        $sline =~ s/\+/P_/g;                            # Replace sign + on the P_
        $name = (split ' ', $sline)[0];
                if (@{$name}) {                         # If array exist with name os User Alias print all real name assigned to alias
                        foreach $i (@{$name}) {
                                $i =~ s/^\s+//;
                                $tmp_n = $sline;
                                $name_plus_alias = "$i UAL_$name";                      # Name + alias
                                $tmp_n =~ s/$name/$name_plus_alias/g;
                                $fin_usr = ($fin_usr . $tmp_n);
                        }
                }
                else {
                        $tmp_n2 = $sline;
                        $tmp_n2 =~ s/"$name"/"$name" UAL_NONE/g;
                        $tmp_n2 =~ s/P_/\+/g;           # Back to original - replace P_ on the + character
                        $fin_usr = ("$fin_usr" . "$tmp_n2");
                }
}

# <---  END Users, Users alias


# ----->   Commands - creating list of real commands

$comm_alias="";
foreach $n (@a_comm_al) {
        ($part1) = $n =~ /^(.+)=/;                      # Separate string to substring from ^  to "="
        ($part2) = $n =~ /=(.+)$/;                      # Separate string to substring from "=" to END
        $comm_alias = (split ' ', $part1)[-1];          # Print last word from substring - Command Alias
        @orders = split(',', $part2);                   # Array - list of commands
        @{$comm_alias} = (@orders);                     # Array Commands_Alias ans assigned users
}

$fin_comm="";
foreach $cline (split /^/, $fin_usr) {
                ($cpart2) = $cline =~ /PASSWD:(.+)$/;
                ($cpart1) = $cline =~ /^(.+):/;
                foreach $com (split /,/, $cpart2) {
                        $com =~ s/^ //g;
                        $com =~ s/ $//g;
                        #--> for all commands which contain sign "/" and doesn't contain "!" do:
                        if ( $com =~ /\//) {
                                $comt = $com;
                                $comt =~ s{!}{EX-}g;                    #Replace
                                $com_line = ("$cpart1".":" . "$comt");
                                $fin_comm = ($fin_comm . "$com_line\n");
                        }
                        #<--

                        #-->  for all Command_Alias - sentence doesn't contain sign "/" and doesn't contain sign '!" do:
                        if ( $com !~ /\// && $com !~ /!/ ) {
                                if (@{$com}) {                         # If array exist with name of Command Alias print all real commands assigned to alias
                                        foreach $lcom (@{$com}) {
                                                 $lcomt = $lcom;
                                                 $lcomt =~ s/[\t ]+$//;
                                                 $lcomt =~ s{!}{EX-}g;
                                                 $com_line = ("$cpart1".":" . " CAL_$com" . " $lcomt");
                                                 $fin_comm = ($fin_comm . "$com_line\n");
                                        }
                                } else  {
                                        $com_line = ("$cpart1".":" . "$com");
                                        $fin_comm = ($fin_comm . "$com_line\n");
                                }
                        }
                        #<--

                        #-->  for all Command_Alias - sentence doesn't contain sign "/" and contain sign '!" do:
                        if ( $com !~ /\// && $com =~ /!/ ) {
                                $E_comt = $com;
                                $E_comt =~ s/[\t ]+$//;
                                $E_comt =~ s{!}{}g;
                                if (@{$E_comt}) {                         # If array exist with name of Command Alias print all real commands assigned to alias
                                        foreach $Elcom (@{$E_comt}) {
                                                 $com_line = ("$cpart1".":" . " CAL_$E_comt" ." EX-$Elcom");
                                                 $fin_comm = ($fin_comm . "$com_line\n");
                                        }
                                }
                        }
                        #<--
                }
}
# <--- END commands


# -----> Two statement for statement without pattern "PASSWD" - exception like: "root ALL=(ALL) ALL,root ALL=ALL"
foreach $entry (@p_input) {
        ($uroot) = split(/\s+/, $entry);
        if ( $uroot =~ /root/ && $entry !~ /PASSWD/ && $entry =~ /\)/ ) {
                $rline = $entry;
                $rline =~ s{\)}{\) NOPASSWD:}g;
                $fin_comm = ("$rline" . "$fin_comm\n");
        } else {
                if ( $uroot =~ /root/ && $entry !~ /PASSWD/ && $entry !~ /\)/ ) {
                $rline = $entry;
                $rline =~ s{\=}{\= NOPASSWD:}g;
                $fin_comm = ("$rline" . "$fin_comm\n");
                }
         }
}
# <--


@all = split /^/m ,$fin_comm;                           # Assign $fin_comm variable into array
@last = sort @all;                                      # Sort all lines
#
#--> Last PRINT all records
#
# -----> Last parse and PRINT
for $lastpr (@last) {
        if ($lastpr !~ /^$/) {

                ($piece2) = $lastpr =~ /SWD:(.+)$/;

                # Real Name
                ($real_user) = split(/\s+/, $lastpr);

                # User Alias
                $real_alias_tmp = (split ' ', $lastpr)[1];
                if ($real_alias_tmp !~ /NONE/ && $real_alias_tmp =~ /UAL\_/) {
                        $real_alias = $real_alias_tmp;
                        $real_alias =~ s{UAL\_}{}g;
                }
                if ($real_alias_tmp =~ /NONE/) {
                        $real_alias = "";
                }
                if ($real_alias_tmp !~ /UAL\_/) {
                        $real_alias = "";
                }

                # As user
                if ($lastpr =~ /\(/) {                          # if line contain "("
                        ($as_user) = $lastpr =~ /\((.+)\)/;     # print world between ()
                } else {
                        $as_user = "root";                      # Else as_user = root
                }

                # Command Alias
                if ($piece2 =~ / CAL\_/) {                       # if line contain " CAL_"
                        ($cmd_alias) = (split ' ', $piece2)[0];
                        $cmd_alias =~  s{CAL\_}{}g;              # Remove "CAL_"
                }  else {
                        $cmd_alias = "";
                }

                # Commands
                        if ($piece2 =~ /\// && $piece2 !~ /EX-/) {
                                ($command_tmp) = $piece2  =~ /\/(.+)$/;
                                $command = "/$command_tmp";
                                $command =~ s{^ }{}g;
                                $excluded = "";
                        }
                        if ($piece2 =~ /\// && $piece2 =~ /EX-/) {
                                ($command_tmp) = $piece2  =~ /\/(.+)$/;
                                $command = "";
                                $excluded = "/$command_tmp";
                        }
                        if ($piece2 !~ /\// && $piece2 !~ /EX-/) {
                                $command = $piece2;
                                $command =~ s{ }{}g;
                                $excluded = "";
                        }

                # PASSWD
                if ($lastpr =~ /NOPASSWD/) {
                        $pwflag = "NOPASSWD";
                } else {
                        $pwflag = "PASSWD";
                }


        # FINAL PRINT:
        print "$real_user;$real_alias;$as_user;$cmd_alias;$command;$pwflag;$excluded;\n"
        }
}
# <--- END Print
#
# END

