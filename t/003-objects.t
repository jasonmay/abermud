#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar;

my $c = build_game
    zone => 'test',
    default_location => 'test1',

    locations => {
        test1 => {
            title              => 'A road',
            description        => "There is a road here heading north. " .
                                  "You hear noises in the distance.\n",
            exits => { north => 'test2' },
            has_objects => {
                rock => {
                    traits => [qw/Getable/],
                    description => 'A rock is laying on the ground here.',
                },
                sign => {
                    description         => 'There is a sign here.',
                    examine => "Why do you care what it says? " .
                                           "You're just a perl script!",
                },
                chest => {
                    traits      => [qw/Getable Openable Closeable Container/],
                    description => 'There is a chest here.',
                    contains    => {
                        sack => {
                            traits      => [qw/Getable Container/],
                            description => 'There is a sack here.',
                            contains => {
                                potato => {
                                    traits => [qw/Getable Food/],
                                    description => 'mmm potato',
                                }
                            }
                        },
                    },
                },
            },
        },
        test2 => {
            title              => 'Path',
            description        => "This path goes north and south.\n",
            exits              => { south => 'test1' },
            has_objects => {
                sword => {
                    traits => [qw/Weapon Getable/],
                    description => 'Here lies a sword run into the ground.',
                },
            },
        },
    },
;

my $u = $c->fetch('universe')->get;

SKIP: {
#    skip 'got broken. gonna fix soon', 32;
    ok(my @o = @{$u->objects}, 'objects loaded');

    #warn map { $_->name } @o;
    is_deeply(
        [sort map { $_->does('AberMUD::Object::Role::Getable') } @o],
        [0, 1, 1, 1, 1, 1]
    );

    my %objects = map { $_->name => $_ } @o;

    my $one = $c->player_logs_in('playerone');
    my $two = $c->player_logs_in('playertwo');

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
    like($two->types_in('examine rock'), qr{You notice nothing special\.});
}

done_testing();
