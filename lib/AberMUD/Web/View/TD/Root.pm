#!/usr/bin/env perl
package AberMUD::Web::View::TD::Root;
use strict;
use warnings;
use Template::Declare::Tags;
use Data::Dumper;

template main => sub {
    my $class = shift;
    my $c     = shift;

    html {
        body {
            a { attr { href => '/location/start2' } 'Here' };
        }
    }
};

1;

