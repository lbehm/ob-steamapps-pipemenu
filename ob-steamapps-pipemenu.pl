#!/usr/bin/perl

###############
# Openbox Pipemenu for Steam on Linux games
# Author: Devimplode
# Tested on Crunchbang
# Excuse: I touched perl yesterday the first time.... and I regret nothing!
# Special thanks to the creators of http://www.kegel.com/wine/winetricks
#
# You know how to code perl the right way? Please contribute!
#
###############

use strict;

#use warnings;
# we will display warnings via the xml output
# maybe there is a custom error handler in perl?

# helper function for config variables
# just couse we didn't want globals
sub get_config{
	my( %config ) = (
		'steamExec' => "/usr/bin/steam-debian",
		'globalConfig' => $ENV{"HOME"}."/.steam/steam/config/config.vdf",
		'steamAppsDir' => $ENV{"HOME"}."/.steam/steam/SteamApps/"
	);
	my( $get ) = $_[0];
	
	return ($config{$get})
}

# recursive function to read a config block into a HASH
sub read_into_container{
    my( $pcontainer ) = @_;

    $_ = <FILE> || out_error("Can't read first line of container");
    /{/ || out_error("First line of container was not {");
    while (<FILE>) {
       chomp;
       if (/"([^"]*)"\s*"([^"]*)"$/) {
           ${$pcontainer}{$1} = $2;
       } elsif (/"([^"]*)"$/) {
           my( %newcon, $name );
           $name = $1;
           read_into_container(\%newcon);
           ${$pcontainer}{$name} = \%newcon;
        } elsif (/}/) {
           return;
        } else {
           out_error("huh?");
        }
    }
}
# same like above... I just need to push the file handle into a variable...
sub read_appmanifest_container{
	my( $amcontainer ) = @_;
	$_ = <APPMANIFESTFILE> || out_error("Can't read first line of container");
    /{/ || out_error("First line of container was not {");
    
    while (<APPMANIFESTFILE>) {
       chomp;
       if (/"([^"]*)"\s*"([^"]*)"$/) {
           ${$amcontainer}{$1} = $2;
       } elsif (/"([^"]*)"$/) {
           my( %newcon, $name );
           $name = $1;
           read_appmanifest_container(\%newcon);
           ${$amcontainer}{$name} = \%newcon;
        } elsif (/}/) {
           return;
        } else {
           out_error("huh?");
        }
    }
}
sub read_app_name{
	my( $app ) = @_;
	my( $id ) = ${$app}{'id'};
	my( $steamAppsDir ) = &get_config('steamAppsDir');
	my( %appmanifest );
	my( $appmanifestline );

	open APPMANIFESTFILE, $steamAppsDir."appmanifest_".${$app}{'id'}.".acf" || out_error("can not open appmanifest");
	$appmanifestline = <APPMANIFESTFILE> || out_error("Could not read first line");
	$appmanifestline =~ /"AppState"/ || out_error("this is not a config.vdf file");

	read_appmanifest_container(\%appmanifest);
	my( $appmanifestcontainer ) = \%appmanifest;

	${$app}{"name"} = ${$appmanifestcontainer}{"UserConfig"}{"name"};
	close APPMANIFESTFILE;
	return;
}
sub read_app_ids{
	my( $pcontainer ) = @_;
	my( %games ) = ( );
	foreach (sort(keys(${$pcontainer}{"Software"}{"Valve"}{"Steam"}{"apps"}))) {
        my( %game ) = ('id' => $_, 'name' => "");
        $game{"installdir"} = ${$pcontainer}{"Software"}{"Valve"}{"Steam"}{"apps"}{$_}{"installdir"};
        if ($game{"installdir"} eq '') {
			# the game isn't installed
		} else {
			read_app_name(\%game);
			#print "GameId: ".$game{"id"}."\n";
			#print "GameName: ".$game{"name"}."\n";
			$games{"".$game{"name"}.""} = $game{"id"};
		}
    }
    out_menu(%games);
}
# output
sub out_entry{
	my( $label, $cmd ) = @_;
	my( $indent ) = $_[2] || "\t";
	print $indent.'<item label="'.$label.'">'."\n";
	print $indent."\t".'<action name="Execute"><command>'.$cmd.'</command></action>'."\n";
	print $indent.'</item>'."\n";
}
sub out_label{
	my( $msg ) = @_;
	my( $indent ) = $_[1] || "\t";
	print $indent.'<separator label="'.$msg.'"/>'."\n";
}
sub out_separator{
	my( $indent ) = $_[0] || "\t";
	print "${indent}<separator/>\n";
}
sub out_error{
	my( $msg ) = @_;
	print '<?xml version="1.0" encoding="utf-8"?>'."\n";
	print "<openbox_pipe_menu>\n";
	out_label("Es ist ein Fehler aufgetreten!");
	out_separator();
	out_label($msg);
	print "</openbox_pipe_menu>\n";
	exit 1;
}
sub out_menu{
	my( %games ) = @_;
	my( $gameName );
	my( $steamExec ) = &get_config('steamExec');
	print '<?xml version="1.0" encoding="utf-8"?>'."\n";
	print "<openbox_pipe_menu>\n";
	out_entry("Steam", $steamExec);
	out_separator();
	foreach $gameName ( sort(keys(%games)) ) {
		out_entry($gameName, $steamExec." -applaunch ".$games{$gameName});
	}
	print "</openbox_pipe_menu>\n";
}

# config
my( $confFile ) = &get_config('globalConfig');

# Read the file
my(%top);
open FILE, $confFile || out_error("can't open ".$confFile);
my($line);
$line = <FILE> || out_error("Could not read first line from ".$confFile);
$line =~ /"InstallConfigStore"/ || out_error("this is not a config.vdf file");
read_into_container(\%top);
read_app_ids(\%top);
