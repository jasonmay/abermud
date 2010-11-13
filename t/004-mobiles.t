#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar qw(build_preset_game);
use AberMUD::Util;

my $c = build_preset_game(
    'two_wide', {
        locations => {
            room1 => {
                has_mobiles => {
                    knight => {
                        description => 'A knight is standing here.',
                        pname => 'Knight',
                        examine => 'very metallic',
                    },
                }
            }
        }
    }
);

my $u = $c->resolve(service => 'universe');

ok(my @m = $u->get_mobiles, 'mobiles loaded');

my %mobiles                       = map { $_->name => $_ } @m;
my $one                           = $c->player_logs_in('playerone');

ok($mobiles{knight});
ok($mobiles{knight}->description);

is($one->location, $mobiles{knight}->location);

like($one->types_in('look'),           qr{knight is standing here});
like($one->types_in('examine knight'), qr{very metallic});

done_testing();
