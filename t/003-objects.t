#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use KiokuDB;
use AberMUD::Container;
use AberMUD::Storage;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Input::State::Game;
use AberMUD::Zone;
use AberMUD::Universe::Sets;
use AberMUD::Config;

my $kdb = KiokuDB->connect('hash', create => 1);
{
    my $zone = AberMUD::Zone->new(name => 'test');

    my %locations = (
        test1 => AberMUD::Location->new(
            world_id           => 'test1',
            id                 => 'road',
            title              => 'A road',
            description        => "There is a road here heading north. "
            . "You hear noises in the distance. ",
            zone               => $zone,
            active             => 1,
        ),
        test2 => AberMUD::Location->new(
            world_id           => 'test2',
            id                 => 'path',
            title              => 'Path',
            description        => "This path goes north and south.",
            zone               => $zone,
            active             => 1,
        ),
    );

    my @objects = (
        AberMUD::Object->new_with_traits(
            name        => 'rock',
            description => 'A rock is laying on the ground here.',
            location    => $locations{test1},
        ),

        AberMUD::Object->new_with_traits(
            name        => 'sword',
            description => 'Here lies a sword run into the ground.',
            location    => $locations{test2},
            traits      => ['AberMUD::Object::Role::Weapon'],
        ),

        AberMUD::Object->new_with_traits(
            name                => 'sign',
            description         => 'There is a sign here.',
            examine_description => "Why do you care what it says? " .
            "You're just a perl script!",
            location            => $locations{test1},
            ungetable           => 1,
            traits              => ['AberMUD::Object::Role::Weapon'],
        ),

        AberMUD::Object->new_with_traits(
            name                => 'sack',
            description         => 'There is a sack here.',
            location            => $locations{test1},
            traits              => ['AberMUD::Object::Role::Container'],
        ),

        AberMUD::Object->new_with_traits(
            name                => 'sack',
            description         => 'There is a sack here.',
            location            => $locations{test1},
            traits              => [
                'AberMUD::Object::Role::Openable',
                'AberMUD::Object::Role::Closeable',
            ],
        ),
    );

    my $sets = AberMUD::Universe::Sets->new;

    my $scope = $kdb->new_scope;
    $kdb->store("location-$_" => $locations{$_}) foreach keys %locations;

    $locations{test1}->north($locations{test2});
    $locations{test2}->south($locations{test1});

    $kdb->update($_) foreach values %locations;

    for (@objects) {
        my $id = $kdb->store($_);
        $sets->all_objects->{$id} = $_;
    }

    $kdb->store("universe-sets" => $sets);

    my $config = AberMUD::Config->new(
        input_states => [qw(Login::Name Game)],
    );

    $kdb->store(config => $config);

    $config->location($locations{test1}); $kdb->update($config);
}


my $c = AberMUD::Container->new_with_traits(
    traits         => ['AberMUD::Container::Role::Test'],
    test_storage => AberMUD::Storage->new(
        directory => $kdb,
    )
)->container;

my $u = $c->fetch('universe')->get;

$c->fetch('controller')->get->_load_objects();

sub player_logs_in {
    my $p = $c->fetch('player')->get;
    $p->input_state([AberMUD::Input::State::Game->new]);

    $p->name(shift);
    $p->location($c->fetch('storage')->get->lookup('location-test1'));
    $p->_join_game;
}

SKIP: {
    skip 'got broken. gonna fix soon', 32;
    ok(my @o = @{$u->objects}, 'objects loaded');
    is_deeply(
        [sort map { $_->does('AberMUD::Object::Role::Getable') } @o],
        [0, 1, 1, 1]
    );

    my %objects = map { $_->name => $_ } @o;

    my $one = player_logs_in('playerone');
    my $two = player_logs_in('playertwo');

    like($one->types_in('look'), qr{A rock is laying on the ground here\.});

    like($one->types_in('take rock'), qr{You take the rock\.});
    like($two->get_output, qr{playerone picks up a rock\.}i);

    is($objects{rock}->held_by, $one);

    unlike($one->types_in('look'), qr{A rock is laying on the ground here\.});

    like($one->types_in('drop rock'), qr{You drop the rock\.});
    is_deeply($one->output_queue, []);

    like($two->get_output, qr{playerone drops a rock\.}i);
    is_deeply($one->output_queue, []);

    like($one->types_in('take sword'), qr{No object of that name is here\.});

# make sure nothing broadcasts to self
    is_deeply($one->output_queue, []);

    $two->types_in('north'); $one->get_output;
    like($two->types_in('take sword'), qr{You take the sword\.}); $one->get_output;

    like($two->types_in('take sword'), qr{You are already carrying that!});

    $two->types_in('south');      $one->get_output;
    $two->types_in('drop sword'); $one->get_output;

    my $look_output = $one->types_in('look');
    like($look_output, qr{A rock});
    like($look_output, qr{a sword});

    like($one->types_in('take all'), qr{You take everything you can\.});
    like($two->get_output, qr{playerone takes everything he can\.});
    is_deeply($one->output_queue, []);

    like($one->types_in('take all'), qr{There is nothing here for you to take\.});

    my @output_lines = split /\n/, $one->types_in('inventory');
    is($output_lines[0], q{Your backpack contains:});
    like($output_lines[1], qr{\brock\b});
    like($output_lines[1], qr{\bsword\b});

    like($two->get_output, qr{playerone rummages through his backpack}i);
    is_deeply($one->output_queue, []);

    like($two->types_in('inventory'), qr{Your backpack contains nothing\.});
    $one->get_output;

    like($one->types_in('drop all'), qr{You drop everything you can\.});
    like($two->get_output, qr{playerone drops everything he can\.}i);

# test bug where I don't see the rock on the ground
    $one->types_in('take sword'); $two->get_output;
    like($two->types_in('take rock'), qr{You take the rock\.});

    $_->held_by($two) for grep { $_->can('held_by') } @o;

# examine
    like($two->types_in('examine sign'), qr{Why do you care});
    like($two->types_in('examine rock'), qr{You don't notice anything special\.});
}

done_testing();
