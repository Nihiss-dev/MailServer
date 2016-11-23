#!/usr/bin/env/perl

use IO::Socket;
use MIME::Lite;

my $serveur = null;
my $ligne = "";
my $i = 1;
my $protocole = "TCP";
my $port = "4242";

sub sendMail
{
    $serveur = IO::Socket::INET->new(Proto => $protocole, LocalPort => $port, Listen => SOMAXCONN, Reuse => 1) or die "Impossible de lancer le serveur\n";
    while ($new_socket = $serveur->accept())
    {
	$new_socket->autoflush(1);
	$new_socket->send("250 OK - Bienvenue sur le serveur\r\nA qui voulez vous envoyer le courriel ?");
	print "\ncommunication $i\n";
	$new_socket->recv($ligne, 1024);
	while ($ligne !~ /^quit\r\n$/i)
	{
	    if ($ligne =~ /^[^@]+@.+$/i)
	    {
		my $msg = MIME::Lite->new(From=> "tp4\@ulaval.ca",
					  To => $ligne,
					  Cc => '',
					  Subject => "exercice 2",
					  Data => "topkek");
		$msg->send('smtp', "smtp.ulaval.ca", Timeout=>60);
		$new_socket->send("250 OK - courriel envoye");
		last;
	    }
	    else
	    {
		$new_socket->send("550 ERREUR - Adresse incorrecte\r\n");
	    }
	    $new_socket->recv($ligne, 1024);
	}
	$new_socket->send("250 OK - Au revoir\r\n");
	print "Fin communication\n";
	close $new_socket;
	$i++;
    }
}

sub main
{
    sendMail();
}

main();
