#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Messages;
use AberMUD::Test::Sugar qw(build_preset_game);

my $c = build_preset_game(
    'two_wide', {
        locations => {
            room1 => {
                has_mobiles => {
                    foo => {
                        wielding => {
                            sword => {
                                description => 'uh oh',
                                damage => 1,
                            },
                        },
                        gender => 'Female',
                    },
                    bar => {
                        gender => 'Male',
                    },
                    baz => {
                        description => 'baz is gender-neutral',
                    },
                }
            }
        },
    }
);

my %mobs = map {; $_->name => $_ }
            $c->resolve(service => 'universe')->get_mobiles;

my $dude = $c->gen_player('dude');
$dude->gender('Male');

my $chick = $c->gen_player('chick');
$chick->gender('Female');

can_ok('AberMUD::Messages', 'format_fight_message');

my %message_map = (
    '%a come%s very close to hitting %d with %g %w.' => {
        args => {
            attacker => $mobs{foo},
            victim   => $dude,
        },
        result => [
            'foo comes very close to hitting dude with her sword.',
            'you come very close to hitting dude with your sword.',
            'foo comes very close to hitting you with her sword.',
        ],
    },
    '%a deliver%s a good hit to %p %b.' => {
        args => {
            attacker => $chick,
            victim   => $mobs{baz},
            bodypart => 'left_arm',
        },
        result => [
            q[chick delivers a good hit to baz's &+mleft arm&N.],
            q[you deliver a good hit to baz's &+mleft arm&N.],
            q[chick delivers a good hit to your &+mleft arm&N.],
        ],
    },
);

my @perspectives = qw(bystander attacker victim);

while ( my ($message, $data) = each %message_map ) {
    my %args = %{ $data->{args} };
    my %results;

    @results{@perspectives} = @{ $data->{result} };

    foreach my $perspective (@perspectives) {
        my $f = AberMUD::Messages::format_fight_message(
            $message,
            %args,
            perspective => $perspective,
        );

        is($f, $results{$perspective});
    }
}

done_testing();
