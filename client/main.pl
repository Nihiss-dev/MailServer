#!/usr/bin/env/perl

use IO::Socket;
use Getopt::Long;

my $destination = "";
my $port = "";
my $help = 0;

sub help
{
    #TODO help
    print "client help\n";
}

sub main
{
    my $options = GetOptions("port=s" => \$port, "destination=s" => \$destination, "help" => \$help);
    if ($help == 1)
    {
	help();
	exit 1;
    }
    my $connection = IO::Socket::INET->new(Proto => $protocole, PeerAddr => $destination, PeerPort => $port) or die "Impossible de se connecter\n";
    while ($connection)
    {
	$reponse = "";
	$connection->recv($reponse, 1024);
	print $reponse;
	$ligne = <STDIN>;
	$connection->send($ligne);
    }
}

main();
