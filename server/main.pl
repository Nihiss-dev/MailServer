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
my $clientAddress = "";

sub checkDir
{
    if (@_[0] =~ /(([^@]+)@(.+))\.(.*)/)
    {
	$dir = getcwd();
	opendir my($dh), $dir or die "cannot open dir\n";
	my @files = readdir $dh;
	foreach(@files)
	{
	    if ($_ eq $2)
	    {
		closedir $dh;
		return 0;
	    }
	}
	closedir $dh;
    }
    return 1;
}

sub connexion
{
    @_[0]->send("Veuillez rentrer votre adresse mail: ");
    @_[0]->recv($ligne, 1024);
    while ($ligne !~ /([^@]+)(@reseauglo\.ca)/)
    {
	@_[0]->send("Veuillez rentrer une adresse valide\nVeuillez rentrer votre adresse mail: ");
	@_[0]->recv($ligne, 1024);
    }
    if (checkDir($ligne) == 0)
    {
	if ($ligne =~ /(([^@]+)@(.+))\.(.*)/)
	{
	    $file = "$dir/$2/config.txt";
	    open(my $fh, '<:encoding(UTF-8)', $file) or die "Cannot open file\n";
	    my $row = <$fh>;
	    close($fh);
	    $clientAddress = $ligne;
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
    while ($ligne !~ /([^@]+)(@reseauglo\.ca)/)
    {
	@_[0]->send("Veuillez indiquer l'adresse mail que vous voulez utilser: ");
	@_[0]->recv($ligne, 1024);
    }
    $address = $ligne;
    $clientAddress = $ligne;
    $passwdOk = 1;
    while ($passwdOk != 0)
    {
	@_[0]->send("4242 - Veuillez entrer votre mot de passe: ");
	@_[0]->recv($ligne, 1024);
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
	if ($address =~ /(([^@]+)@(.+))\.(.*)/)
	{
	    mkdir($2);
	    $currentDir = getcwd();
	    open(PASSWD, ">>$currentDir/$2/config.txt") or die "cannot create file\n";
	    print PASSWD "$passwd";
	    close(PASSWD);
	}
	@_[0]->send("Vous avez correctement cree votre compte\n");
    }
    return 1;
}

sub readMail
{
    $clientAddress =~ /(([^@]+)@(.+))\.(.*)/;
    $dir = getcwd();
    $directory = "$dir/$2";
    opendir my($dh), $directory or die "cannot open dir\n";
    my @files = readdir $dh;
    $i = 0;
    @_[0]->send("Choisissez le courriel a visualiser: ");
    foreach(@files)
    {
	if ($_ ne "." && $_ ne ".." && $_ ne "config.txt")
	{
	    @_[0]->send("$i - $_\n");
	    $i++;
	}
    }
    @_[0]->recv($response, 1024);
    $index = substr($response, 0, 1) + 3;
    open(my $fh, "<:encoding(UTF-8)", "$directory/@files[$index]");
    while (my $row = <$fh>)
    {
	chomp $row;
	@_[0]->send("$row\n");
    }
    close($fh);
    closedir $dh;
    @_[0]->send("Appuyez sur une touche pour quitter le mail\n");
    @_[0]->recv($response, 1024);
}

sub stats
{
    $clientAddress =~ /(([^@]+)@(.+))\.(.*)/;
    $dir = getcwd();
    $directory = "$dir/$2";
    opendir my($dh), $directory or die "cannot open dir\n";
    my @files = readdir $dh;
    $i = 0;
    foreach(@files)
    {
	if ($_ ne "." && $_ ne ".." && $_ ne "config.txt")
	{
	    $i++;
	}
    }
    my $size = (stat $directory)[7];
    @_[0]->send("Statistiques de votre compte:\n$i courriels\nTaille du dossier en byte: $size\n\nAppuyer sur une touche pour revenir au menu precedent\n");
    @_[0]->recv($response, 1024);
}

sub sendMail
{
    #destinataire
    @_[0]->send("Veuillez entrer l'adresse de la personne a laquelle vous voulez envoyer le courriel: ");
    @_[0]->recv($address, 1024);
    while ($address !~ /(([^@]+)@(.+))\.(.*)/)
    {
	@_[0]->send("500 ERREUR - Adresse incorrecte\r\nVeuillez entrer a nouveau l'adresse de la personne a laquelle vous voulez envoyer le courriel: ");
	@_[0]->recv($address, 1024);
    }

    #CC ?
    @_[0]->send("Voulez vous ajouter un CC ?\nO - Oui\nN - Non\n");
    @_[0]->recv($ligne, 1024);
    while ($ligne !~ /O\n/ && $ligne !~ /N\n/)
    {
	@_[0]->send("Veuillez entrer un choix valide\n");
	@_[0]->recv($ligne, 1024);
    }
    if ($ligne =~ /O\n/)
    {
	@_[0]->send("Veuillez entrer l'adresse de la personne a laquelle vous voulez envoyer le courriel: ");
	@_[0]->recv($CC, 1024);
	while ($CC !~ /(([^@]+)@(.+))\.(.*)/)
	{
	    @_[0]->send("500 ERREUR - Adresse incorrecte\r\nVeuillez entrer a nouveau l'adresse de la personne a laquelle vous voulez envoyer le courriel: ");
	    @_[0]->recv($CC, 1024);
	}
    }
    else
    {
	$CC = "";
    }

    #sujet
    @_[0]->send("Saisissez le sujet de votre courriel: ");
    @_[0]->recv($subject, 1024);
    if ($subject eq "\n")
    {
	$dateString = localtime();
	$subject = "Sans Sujet: $dateString";
    }

    #data
    @_[0]->send("Veuillez rentrer le contenu de votre courriel: (4096 characteres restant)\n");
    @_[0]->recv($data, 4096);
    $address =~ /(([^@]+)@(.+))\.(.*)/;

    #message goes directly in user folder ?
    if ($3 eq "reseauglo")
    {
	$currentDir = getcwd();
	if (checkDir($address) == 0)
	{
	    #write into folder
	    open(MAIL, ">>$currentDir/$2/$subject") or die "cannot create file\n";
	    print MAIL "From: $clientAddress\nTo: $address\nCc: $CC\nSubject: $subject\n$data\n";
	    close(MAIL);
	    $CC =~ /(([^@]+)@(.+))\.(.*)/;
	    if ($3 eq "reseauglo")
	    {
		print "$3\n";
		open(MAIL, ">>$currentDir/$2/$subject") or die "cannot create file\n";
		print MAIL "From: $clientAddress\nTo: $address\nCc: $CC\nSubject: $subject\n$data\n";
		close(MAIL);
	    }
	    @_[0]->send("250 OK - courriel envoye\n");
	}
	else
	{
	    #error
	    open(ERROR, ">>$currentDir/DESTERREUR/$subject") or die "cannot create file\n";
	    print ERROR "From: $clientAddress\nTo: $address\nCc: $CC\nSubject: $subject\n$data\n";
	    close(ERROR);
	    @_[0]->send("L'utilisateur que vous avez specifie n'existe pas\n");
	}
    }
    else
    {
	#send mail via smtp
	my $msg = MIME::Lite->new(From=> $clientAddress,
				  To => $address,
				  Cc => $CC,
				  Subject => $subject,
				  Data => $data);
	$msg->send('smtp', "smtp.ulaval.ca", Timeout=>60);
	@_[0]->send("250 OK - courriel envoye\n");
    }
}

sub menu
{
    #TODO
    #1 send mail
    #2 read mail
    #3 stats
    $ligne = "";
    while ($ligne !~ /^quit\r\n$/i)
    {
	@_[0]->send("Menu principal:\n1 - Envoyer courriel\n2 - Consulter vos courriels\n3 - Statistiques de votre compte\n4 - Deconnection\n");
	@_[0]->recv($ligne, 1024);
	if ($ligne =~ /1\n/)
	{
	    sendMail(@_[0]);
	}
	elsif ($ligne =~ /2\n/)
	{
	    #read mail
	    readMail(@_[0]);
	}
	elsif ($ligne =~ /3\n/)
	{
	    #stats
	    stats(@_[0]);
	}
	elsif ($ligne =~ /4\n/)
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
	menuAccueil($new_socket);
	menu($new_socket);
	close $new_socket;
	$i++;
    }
}

sub main
{
    mkdir("DESTERREUR");
    server();
}

main();
