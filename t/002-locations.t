#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use AberMUD::Container;
use AberMUD::Zone;
use AberMUD::Input::State::Game;
use AberMUD::Config;

my $kdb = KiokuDB->connect(
    "dbi:SQLite:dbname=:memory:",
    create => 1,
);

{
    my $zone = AberMUD::Zone->new(name => 'test');

    my %locations = (
        test1 => AberMUD::Location->new(
            world_id    => 'test1',
            id          => 'road',
            title       => 'A road',
            description => "There is a road here heading north. "
                        . "You hear noises in the distance. ",
            zone        => $zone,
            active      => 1,
        ),
        test2 => AberMUD::Location->new(
            world_id    => 'test2',
            id          => 'path',
            title       => 'Path',
            description => "This path goes north and south.",
            zone        => $zone,
            active      => 1,
        ),
    );

    my $scope = $kdb->new_scope;
    $kdb->store("location-$_" => $locations{$_}) foreach keys %locations;

    $locations{test1}->north($locations{test2});
    $locations{test2}->south($locations{test1});

    $kdb->update($_) foreach values %locations;

    my $config = AberMUD::Config->new(
        input_states => [qw(Login::Name Game)],
    );

    $kdb->store(config => $config);

    $config->location($locations{test1}); $kdb->update($config);
}

my $c = AberMUD::Container->new_with_traits(
    traits         => ['AberMUD::Container::Role::Test'],
    test_directory => AberMUD::Directory->new(
        kdb => $kdb,
    )
)->container;

my $u = $c->fetch('universe')->get;

sub player_logs_in {
    my $p = $c->fetch('player')->get;
    $p->input_state([AberMUD::Input::State::Game->new]);

    $p->name(shift);
    $p->location($c->fetch('directory')->get->lookup('location-test1'));
    $p->_join_game;
}

my $one = player_logs_in('playerone');
my $two = player_logs_in('playertwo');

like($one->types_in('look'),  qr{playertwo is standing here}i);
like($one->types_in('north'), qr{This path goes north and south});
like($two->get_output,        qr{playerone goes north}i);
like($two->types_in('north'), qr{playerone is standing here}i);
like($one->get_output,        qr{playertwo arrives from the south}i);

$one->types_in('south');
$one->types_in('north');

like($two->get_output, qr{playerone goes south});
like($two->get_output, qr{playerone arrives from the south});
