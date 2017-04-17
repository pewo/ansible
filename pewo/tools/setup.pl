#!/usr/bin/perl -w

use Getopt::Long;
use Term::ReadKey;
my($sudo) = undef;
my($setup_user) = "root";
my($setup_target) = undef;
my($setup_password) = undef;

GetOptions (
	"s|sudo" => \$sudo,
	"u|user=s" => \$setup_user,
	"t|target=s" => \$setup_target,
	"p|password=s" => \$setup_password,
	
);

unless ( $setup_target ) {
	die "Usage: $0 -s (For sudo) -u <username to ssh> -p <password> -t <target>\n"
}

if ( $setup_user ) {
	$ENV{SETUP_USER}=$setup_user
}

if ( $setup_target ) {
	$ENV{SETUP_TARGET}=$setup_target
}

unless ( $setup_password ) {
	print "Enter password for $setup_user on $setup_target:";
	ReadMode('noecho'); # don't echo
	chomp($setup_password = <STDIN>);
	ReadMode(0);        # back to normal
}

if ( $setup_password ) {
	$ENV{SETUP_PASSWORD}=$setup_password
}

my($rc) = 0;
$rc = system("$0.scp");
print "rc=$rc\n";
unless ( $rc ) {
	$rc = system("echo \"$setup_password\" | $0.sudo");
}
print "rc=$rc\n";
