#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar ();

{
    my $game = AberMUD::Test::Sugar::build_preset_game('square');

    ok($game);

    my $config = $game->resolve(service => 'storage')->lookup('config');

    ok($config);
    ok($config->location);

    my $l = $config->location;

    is($l->title,              'Northwest Corner');
    is($l->east->title,        'Northeast Corner');
    is($l->south->title,       'Southwest Corner');
    is($l->south->east->title, 'Southeast Corner');

    is($l->south->east, $l->east->south);
    is($l->east,        $l->south->east->north);
}

sub get_default_location {
    my $game = shift;
    return $game->resolve(service => 'storage')
                ->lookup('config')->location;
}

{
    my $game = AberMUD::Test::Sugar::build_preset_game('jack');
    my $l = get_default_location($game);

    is($l->title,        'Center Room');
    is($l->east->title,  'Eastern Wing');
    is($l->west->title,  'Western Wing');
    is($l->south->title, 'Southern Wing');
    is($l->north->title, 'Northern Wing');
    is($l->up->title,    'High Wing');
    is($l->down->title,  'Low Wing');

    is ($l->north->south, $l);
    is ($l->south->north, $l);
    is ($l->east->west,   $l);
    is ($l->west->east,   $l);
    is ($l->up->down,     $l);
    is ($l->down->up,     $l);
}

{
    my $game = AberMUD::Test::Sugar::build_preset_game(
        'plus',
        extra => [
            {
                locations => {
                    center => {
                        has_objects => {
                            thing => {
                                description => 'A thing is here.',
                            }
                        },
                    },
                },
            },
        ],
    );
    my $l = get_default_location($game);

    my $u = $game->resolve(service => 'universe');

    ok($u->objects);
    is(scalar(@{[$u->get_objects]}), 1);
    my ($o) = $u->get_objects;

    is($o->name, 'thing');
}

done_testing();
