#!/usr/bin/env perl
# PODNAME: game.pl

use strict;
use warnings;
use lib 'lib', 'extlib';
use AberMUD;
use KiokuDB;

use IO::Socket::INET;

my $abermud = AberMUD->new;

sub _check_port {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

if (my $pid = fork()) {
    sleep 1 until _check_port 6715;
    system 'rlwrap', 'telnet', 'localhost', 6715;
    waitpid $pid, 0;
}
else {
    $abermud->run;
}
