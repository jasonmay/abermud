#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Container;

my $c = AberMUD::Container->new->container;
$c->fetch('app')->get->run;
