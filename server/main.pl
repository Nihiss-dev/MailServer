#!/usr/bin/env/perl

use IO::Socket;
use MIME::Lite;
use Cwd;

my $serveur = null;
my $ligne = "";
my $i = 1;
my $protocole = "TCP";
my $port = "4242";

sub checkDir
{
    if (@_[0] =~ /(([^@]+)@(.+))/)
    {
	print "$2\n";
	my $dir = getcwd();
	print "$dir\n";
	opendir my($dh), $dir or die "cannot open dir\n";
	my @files = readdir $dh;
	foreach(@files)
	{
	    if ($_ eq $2)
	    {
		return 0;
	    }
	}
	closedir $dh;
    }
}

sub connexion
{
    @_[0]->send("Veuillez rentrer votre adresse mail: ");
    @_[0]->recv($ligne, 1024);
    while ($ligne !~ /^[^@]+@.+$/i)
    {
	@_[0]->send("Veuillez rentrer une adresse valide\nVeuillez rentrer votre adresse mail: ");
	@_[0]->recv($ligne, 1024);
    }
    if (checkDir($ligne) == 0)
    {
	@_[0]->send("4242 - Veuillez entrez votre mot de passe: ");
	#TODO check passwd in folder
	@_[0]->recv($ligne, 1024);
	print "$ligne\n";
    }
    else
    {
	@_[0]->send("Cet utilisateur n'existe pas, veuillez verifier que votre compte existe bien, et creer un compte si vous n'en n'avez pas encore\nVous allez etre redirige vers le menu principal\n");
	return 0;
    }
    return 1;
}

sub creeCompte
{
    @_[0]->send("Vous avez choisi de creer un compte\nVeuillez indiquer l'adresse mail que vous voulez utiliser: ");
    @_[0]->recv($ligne, 1024);
    while ($ligne !~ /(([^@]+)@(.+))/)
    {
	@_[0]->send("Veuillez indiquer l'adresse mail que vous voulez utilser: ");
	@_[0]->recv($ligne, 1024);
    }
    $address = $ligne;
    $passwdOk = 1;
    #TODO hash passwd client side + maybe termcaps for * instead of char
    #TODO write hashed passwd in user's folder
    while ($passwdOk != 0)
    {
	@_[0]->send("4242 - Veuillez entrer votre mot de passe: ");
	@_[0]->recv($ligne, 1024);
	print "$ligne\n";
	$passwd = $ligne;
	@_[0]->send("4242 - Confirmez en entrant a nouveau votre mot de passe: ");
	@_[0]->recv($ligne, 1024);
	if ($ligne eq $passwd)
	{
	    $passwdOk = 0;
	}
	else
	{
	    @_[0]->send("Les mots de passe different\n");
	}
    }
    $passwd = $ligne;
    if (checkDir($address) == 0)
    {
	@_[0]->send("Le compte que vous avez specifie existe deja, vous allez etre redirige au menu de l'accueil\n");
	return -1;
    }
    else
    {
	if ($address =~ /(([^@]+)@(.+))/)
	{
	    mkdir($2);
	    $currentDir = getcwd();
	    $dir = "$currentDir/$2/passwd";
	    print "$dir\n";
	    open(PASSWD, ">>$currentDir/$2/passwd") or die "cannot create file\n";
	    print PASSWD "$passwd";
	    close(PASSWD);
	}
	@_[0]->send("Vous avez correctement cree votre compte\n");
    }
    return 1;
}

sub printMenu
{
    @_[0]->send("Menu principal:\n");
    @_[0]->send("1 - Envoyer courriel\n");
}

sub sendMail
{
    @_[0]->send("Veuillez entrer l'adresse de la personne a laquelle vous voulez envoyer le courriel: ");
    @_[0]->recv($ligne, 1024);
    while ($ligne !~ /^[^@]+@.+$/i)
    {
	@_[0]->send("500 ERREUR - Adresse incorrecte\r\nVeuillez entrer a nouveau l'adresse de la personne a laquelle vous voulez envoyer le courriel: ");
	@_[0]->recv($ligne, 1024);
    }
    #TODO field FROM from user
    #TODO if hostname == hostname used for the TP, write mail into the folder
    my $msg = MIME::Lite->new(From=> "tp4\@ulaval.ca",
			      To => $ligne,
			      Cc => '',
			      Subject => "exercice 2",
			      Data => "topkek");
    $msg->send('smtp', "smtp.ulaval.ca", Timeout=>60);
    @_[0]->send("250 OK - courriel envoye");
}

sub menu
{
    while ($ligne !~ /^quit\r\n$/i)
    {
	printMenu(@_[0]);
	@_[0]->recv($ligne, 1024);
	if ($ligne =~ /1\n/)
	{
	    sendMail(@_[0]);
	}
    }
}

sub server
{
    my $isConnected = 0;
    $serveur = IO::Socket::INET->new(Proto => $protocole, LocalPort => $port, Listen => SOMAXCONN, Reuse => 1) or die "Impossible de lancer le serveur\n";
    while ($new_socket = $serveur->accept())
    {
	$new_socket->autoflush(1);
	$new_socket->send("250 OK - Bienvenue sur le serveur\r\nMenu principal:\n1 - Connexion\n2 - Creer un compte\n\nVeuillez rentrer le chiffre correspondant a votre choix\n");
	print "\ncommunication $i\n";
	$new_socket->recv($ligne, 1024);
	while ($isConnected != 1)
	{
	    while ($ligne !~ /^1\n/ && $ligne !~ /^2\n/)
	    {
		$new_socket->send("Menu principal:\n1 - Connexion\n2 - Creer un compte\n\nVeuillez rentrer le chiffre correspondant a votre choix\n");
		$new_socket->recv($ligne, 1024);
	    }
	    if ($ligne =~ /^1\n/)
	    {
		$isConnected = connexion($new_socket);
	    }
	    if ($ligne =~ /^2\n/)
	    {
		$isConnected = creeCompte($new_socket);
	    }
	}
	menu($new_socket);
	print "Fin communication\n";
	close $new_socket;
	$i++;
    }
}

sub main
{
    server();
}

main();
