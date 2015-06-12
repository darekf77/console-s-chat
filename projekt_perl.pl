#!/usr/bin/perl -w
# Pracownia Języków Skryptowych
# ConoleSChat - program zaliczeniowy (eksternistyczine) perl 
# autor Dariusz Filipiak


system("clear");
 
use Term::Cap;
use POSIX;


use threads;
# use Win32::Console::ANSI;
use Term::ANSIColor;
use constant false => 0;
use constant true  => 1;

use diagnostics;
# use strict;
# use warnings;
# use Class::Singleton;
# use Socket;
use IO::Socket::INET;

use constant false => 0;
use constant true  => 1;

my $termios = new POSIX::Termios; $termios->getattr;
my $ospeed = $termios->getospeed;
my $t = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };
($norm, $bold) = map { $t->Tputs($_,1) } qw/me md us/;

package ChatProgram;
sub new
{
	my $class = shift;
	my $self = {	    
	    _peer_port => "",   
	    _peeraddress  => "",
	    _socket => "",
	    _recieved_data => "",
	    _data => "",
	    _userPeer => "",
	    _isProgramActive => true,
	    _secureKey => "1234",
	};
	# print "Constructor: port:$self->{_peerport} ip:$self->{_peeraddress}\n";
	bless $self, $class;
    return $self;
}

sub printLine {	
	for (my $i = 0; $i < 50; $i++) {
		print "-";
	}
	print "\n";
}

sub socketERR {
	print "\nNiepoprawne paramtrey połączenia adresIP:$self->{_peer_address} port: $self->{_peer_port}\n";
	print "Sprawdź pomoc programu.\n\n";
	exit 1;
}

sub initSocketServer {
	$self->{_peer_port} = $_[1];
	# flush after every write
	$| = 1;
	$self->{_socket} = new IO::Socket::INET (
	LocalPort =>$self->{_peer_port},
	Proto => 'udp',
	)  or socketERR();

}

sub initSocketClient {
	# print @_;
	$self->{_peer_port} = $_[1];
	$self->{_peer_address} = $_[2];
	$| = 1;

	#print "argument: $self->{_peer_address}:$self->{_peer_port}";
	# print "** Init socket on port $self->{__peerport} and adress $self->{_peer_address} \n";
	$self->{_socket} = new IO::Socket::INET (
	PeerAddr   => "$self->{_peer_address}:$self->{_peer_port}",
	Proto        => 'udp'
	) or socketERR();
}

sub serverMode {
	$self->{_isProgramActive} = true;
	system("clear");
	default_font_color();
	print "Witaj w programie ConsoleSChat. Port serwera $self->{_peer_port} \n";	
	printLine();
	print "Oczekiwanie na użytkownika.\n";
	$self->{_socket}->recv($self->{_userPeer},1024);	
	my @username = `whoami`;
	chomp(@username);
	$self->{_socket}->send($username[0]);
	system("clear");
	print "Witaj w programie ConsoleSChat\n";
	printLine();
	print " Jesteś połączony z użytkownikiem $self->{_userPeer}. \nWpisz -q i zatwierdz, aby zakończyć czat.\n";
	printLine();
	threaded_recv();
    while(1)
	{
		default_font_color();
		$self->{_data} = <STDIN>;
		$self->{_socket}->send($self->{_data});	
	}

}
sub clientMode {
	$self->{_isProgramActive} = true;
	system("clear");
	default_font_color();
	# print "port:".$self->{_peer_port}."address:".$self->{_peer_address}."\n";
	print "Witaj w programie ConsoleSChat\n";
	printLine();
	my @username = `whoami`;
	chomp(@username);
	$self->{_socket}->send($username[0]);
	$self->{_socket}->recv($self->{_userPeer},1024);	
	if( $self->{_userPeer} eq "") {
		print "Serwer nie odpowiedział na twoje zgłoszenie.\n\n";
		exit 1;
	}
	print " Jesteś połączony z użytkownikiem $self->{_userPeer}. \nWpisz -q i zatwierdz, aby zakończyć czat.\n";
	printLine();
	threaded_recv();
	while(1)
	{		
		default_font_color();		
		$self->{_data} = <STDIN>;
		$self->{_socket}->send($self->{_data});			
	}
		
}

sub threaded_recv {
    $self->{_mythread} = threads->create(sub { 
    	
    	while (1) {
    		if( $self->{_isProgramActive} eq true ) {

	    		my $thr_id = threads->self->tid;
		        $self->{_socket}->recv($self->{_recieved_data},1024);		
				# print "\nuser thread $thr_id  say: $self->{_recieved_data}";
				if ( $self->{_recieved_data} eq "-q\n" ) {
					$self->{_socket}->send("-q\n");
					$self->{_socket}->close();
					use Term::ANSIColor;
					print colored ['red on_bright_yellow'], 'Koniec czatu', "\n";
					last;
				}
	   			use Term::ANSIColor qw(:constants);
	   			print BOLD, BLUE, "<$self->{_userPeer}> $self->{_recieved_data}", RESET;
				
		        sleep 1; 
	        }
	        else {
	        	last;
	        }
    	}       
        threads->detach(); #End thread.
        # self->{_socket}->close();
        exit 1;
    });
}


sub default_font_color {
	use Term::ANSIColor;
	print color 'reset';
}



package main;


#print "${under}Underlined ${bold}bold$norm text (just ${bold}bold$norm)";

my $ARG_SERVER_PORT = "7890";
my $ARG_SERVER_IP = "localhost";

my $isARG_SERVER_MODE = false;
my $isARG_CLIENT_MODE = false;
my $isARG_CLIENT_MODE_GETIP = false;

my $nothinToDo = 0;

foreach $arg (@ARGV) {
	if(($arg eq "-h") || ($arg eq "--help")) {		
		
		printf "CONSOLESCHAT\n\n";
		printf "${bold}AUTOR$norm\n";
		printf "\tDariusz Filipiak\n";		
		printf "${bold}NAZWA$norm\n";
		printf "\tConsoleSChat - program do czatowania między 2 konsolami terminala w sieci\n";
		printf "${bold}OPIS$norm\n";
		printf "\tDomyślnie program ConsoleSCzat jest ustawiony, aby działa na adresieIP:localhost i porcie: 7890.\n";
		printf "\tOpis opcjonalnych argumentów programu ConsoleSCzat: \n";		
		printf "\t${bold}-h lub --help$norm\n";
		printf "\t\tpomoc programu\n"		;
		printf "\t${bold}-s  {OPCJONALNIE:port_na_ktorym_ma_funkcjonować} $norm\n";
		printf "\t\turuchomienie serwera i czekanie na klientów programu ConsoleSCzat\n";
		printf "\t${bold}-c   {OPCJONALNIE:{adres_ip_serwera} {port_serwera}} $norm\n";
		printf "\t\turuchomienie klienia i podłączenie się do serwera programu ConsoelSCzat\n";	
		printf "\t${bold}Przykładowe uruchomienie serwera z parametrami: $norm\n";
		printf "\t\t./nazwa_programu.pl -s 5000\n";	
		printf "\t${bold}Przykładowe uruchomienie klienta z parametrami: $norm\n";
		printf "\t\t./nazwa_programu.pl -c 127.0.0.1 -5000\n";		
		printf "\n";
		printf "${bold}PRZEZNACZENIE PROGRAMU$norm\n";
		printf "\tprojekt na eksternistyczne zaliczenie przedmiotu Pracownia Języków Skryptowcyh 2013/2014 r.\n";	
		printf "\n";
		exit 1;
	}

	if($isARG_SERVER_MODE eq true) {
		$ARG_SERVER_PORT = $arg;
		next;
	} 

	if($arg eq "-s") {
		$isARG_SERVER_MODE = true;
		next;
	}

	if($isARG_CLIENT_MODE_GETIP eq true) {		
		$ARG_SERVER_PORT = $arg;
		next;
	}

	if($isARG_CLIENT_MODE == true) {
		$ARG_SERVER_IP = $arg;
		$isARG_CLIENT_MODE_GETIP = true;
		next;
	}

	if($arg eq "-c") {
		$isARG_CLIENT_MODE = true;
		next;
	}
}


# print "ARG_SERVER PORT=$ARG_SERVER_PORT ";
# print "ARG_SERVER IP=$ARG_SERVER_IP";
# print "\n\n";
	
my $chat;
    
$chat = new ChatProgram();



if($isARG_SERVER_MODE == true) {
	$chat->initSocketServer($ARG_SERVER_PORT);
	$chat->serverMode();
}
else {
	$nothinToDo +=1;
}

if($isARG_CLIENT_MODE == true) {
	$chat->initSocketClient($ARG_SERVER_PORT,$ARG_SERVER_IP);
	$chat->clientMode();		
}
else {
	$nothinToDo +=1;
}

if($nothinToDo == 2 ) {
	print "Nie wybrałeś czy program ma dzialać w trybie serwera lub klienta. Sprawdz pomoc programu.\n\n"
}