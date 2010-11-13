#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar ();

can_ok('AberMUD::Test::Sugar', 'build_game');

my ($c, $locations) = AberMUD::Test::Sugar::build_game(
    zone => 'test',
    default_location => 'myloc',
    locations => {
        myloc => {
            title => 'foo',
            description => 'bar',
            has_objects => {
                objx => {
                    description => 'myobj desc',
                },
            },
            has_mobiles => {
                mobz => {
                    description => 'mobz desc',
                },
                moby => {
                    description => 'moby desc',
                    carrying => {
                        withmoby => {
                            description => 'obj with moby',
                        }
                    },
                },
                mobx => {
                    description => 'mobx desc',
                    wielding => {
                        withmobx => {
                            description => 'obj with mobx',
                            damage      => 5,
                        }
                    },
                },
                mobw => {
                    description => 'mobw desc',
                    wearing => {
                        withmobx => {
                            description => 'obj with mobx',
                            covers      => ['head'],
                        }
                    },
                },
            },
        },

    }
);

ok(my $u = $c->resolve(service => 'universe'));
ok($u->get_mobiles);
ok(my %mobs = map { $_->name => $_ } $u->get_mobiles);
ok($locations->{myloc});
is($locations->{myloc}->title,       'foo');
is($locations->{myloc}->description, 'bar');
ok($mobs{$_}) for qw(mobz moby mobx mobw);
done_testing();
