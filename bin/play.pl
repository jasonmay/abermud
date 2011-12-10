#!/usr/bin/env perl
# PODNAME: game.pl

use strict;
use warnings;
use lib 'lib';
use AberMUD;

my $c = AberMUD->new(
    backend_class  => 'AberMUD::Backend::Shell',
    backend_params => ['input_states', 'storage'],
);

$c->run;
