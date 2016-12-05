#!/usr/bin/env/perl

use IO::Socket;
use MIME::Lite;
use Cwd;

my $serveur = null;
my $ligne = "";
my $i = 1;
my $protocole = "TCP";
my $port = "4242";
my $dir = "";

sub checkDir
{
    if (@_[0] =~ /(([^@]+)@(.+))/)
    {
	print "$2\n";
	$dir = getcwd();
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
	if ($ligne =~ /(([^@]+)@(.+))/)
	{
	    $file = "$dir/$2/passwd";
	    print "$file\n";
	    open(my $fh, '<:encoding(UTF-8)', $file) or die "Cannot open file\n";
	    my $row = <$fh>;
	    close($fh);
	    $passwdOk = 0;
	    while ($passwdOk == 0)
	    {
		@_[0]->send("4242 - Veuillez entrez votre mot de passe: ");
		@_[0]->recv($ligne, 1024);
		if ($row eq $ligne)
		{
		    $passwdOk = 1;
		    @_[0]->send("Mot de passe correct, vous allez etre redirige vers le menu principal\n");
		    return 1;
		}
		else
		{
		    @_[0]->send("Mot de passe incorrect\n");
		}
	    }
	}
    }
    else
    {
	@_[0]->send("Cet utilisateur n'existe pas, veuillez verifier que votre compte existe bien, et creer un compte si vous n'en n'avez pas encore\nVous allez etre redirige vers le menu principal\n");
	return 0;
    }
    return 0;
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
    print "pouet\n";
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
    #1 send mail
    #9 disconnect
    $ligne = "";
    while ($ligne !~ /^quit\r\n$/i)
    {
	#do not remove this print, cannot go ahead without him
	#black magic
	@_[0]->send("Menu principal:\n");
	@_[0]->send("1 - Envoyer courriel\n");
	@_[0]->send("9 - Deconnection\n");
	@_[0]->recv($ligne, 1024);
	if ($ligne =~ /1\n/)
	{
	    sendMail(@_[0]);
	}
	if ($ligne =~ /9\n/)
	{
	    #disconnect
	    @_[0]->send("999 - Disconnecting\n");
	    return 1;
	}
    }
    return 1;
}

sub menuAccueil
{
    @_[0]->recv($ligne, 1024);
    $isConnected = 0;
    while ($isConnected != 1)
    {
	while ($ligne !~ /^1\n/ && $ligne !~ /^2\n/)
	{
	    @_[0]->send("Menu principal:\n1 - Connexion\n2 - Creer un compte\n\nVeuillez rentrer le chiffre correspondant a votre choix\n");
	    @_[0]->recv($ligne, 1024);
	}
	if ($ligne =~ /^1\n/)
	{
	    $isConnected = connexion(@_[0]);
	}
	if ($ligne =~ /^2\n/)
	{
	    $isConnected = creeCompte(@_[0]);
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
	menuAccueil($new_socket);
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
