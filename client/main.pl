#!/usr/bin/env/perl

use IO::Socket;
use Getopt::Long;
use Digest::MD5 qw(md5_hex);

my $destination = "";
my $port = "";
my $help = 0;

sub help
{
    #TODO help
    print "Aide utilisateur\n";
    print "Pour lancer le programme: perl mail.pl -d <adresse du serveur> -p 4242\n";
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
	if ($reponse =~ /^(999)/)
	{
	    #disconnect
	    return 0;
	}
	print $reponse;
	$ligne = <STDIN>;
	if ($reponse =~ /^(4242)/)
	{
	    while ($ligne !~ /[a-zA-Z]/ && $ligne !~ /[0-9]/)
	    {
		print "Votre mot de passe doit contenir au moins 1 lettre et 1 chiffre\n";
		$ligne = <STDIN>;
	    }
	    my $hash = md5_hex($ligne);
	    $connection->send($hash);
	}
	#TODO maybe termcaps for writing passwd
	else
	{
	    $connection->send($ligne);
	}
    }
    close($connexion);
}

main();
