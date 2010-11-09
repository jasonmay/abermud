#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar qw(build_game);
use AberMUD::Util;

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
                helmet => {
                    traits => [qw/Wearable Getable/],
                    armor      => 8,
                    covers     => [qw/head/],
                    description => 'There is a helmet on the ground.',
                },
                shoes => {
                    traits => [qw/Wearable Getable/],
                    armor      => 8,
                    covers     => [qw/left_foot right_foot/],
                    description => 'There are some pants on the ground.',
                },
                boots => {
                    traits => [qw/Wearable Getable/],
                    armor      => 8,
                    covers     => [qw/left_foot right_foot/],
                    description => 'There are some boots on the ground.',
                },
                chest => {
                    traits      => [qw/Getable Openable Closeable Container/],
                    description => 'There is a chest here.',
                    open_description => 'There is an open chest here.',
                    closed_description => 'There is a closed chest here.',
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
                door => {
                    traits      => [qw/Openable Closeable Gateway/],
                    description => 'There is a door here.',

                    open_description => 'There is an open door here.',
                    closed_description => 'There is a closed door here.',
                },
                trapdoor => {
                    traits      => [qw/Openable Closeable Gateway/],
                    open_description => 'A trapdoor is open here.',
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
                    dropped_description => 'There is a sword laying on the ground here.',
                },
            },
        },
        red => {
            title              => 'Red Room',
            description        => "It smells like strawberries!\n",
            has_objects => {
                door => {
                    traits      => [qw/Openable Closeable Gateway/],
                    description => 'There is a door here.',
                    open_description => 'There is an open door here.',
                    closed_description => 'There is a closed door here.',
                },
            },
        },
        yellow => {
            title              => 'Yellow Room',
            description        => "It smells like bananas!\n",
            has_objects => {
                trapdoor => {
                    traits      => [qw/Openable Closeable Gateway/],
                    open_description => 'A trapdoor is open here.',
                },
            },
        },
    },
    gateways => {
        'door@test1' => {
            east => 'door@red',
        },
        'door@red' => {
            west => 'door@test1',
        },
        'trapdoor@test1' => {
            down => 'trapdoor@yellow',
        },
        'trapdoor@yellow' => {
            up => 'trapdoor@test1',
        },
    },
;

my $u = $c->resolve(service => 'universe');

ok(my @o = $u->get_objects, 'objects loaded');

ok(scalar(grep { $_->does('AberMUD::Object::Role::Getable') } @o) >= 6);

my %objects                       = map { $_->name => $_ } @o;
my $one                           = $c->player_logs_in('playerone');
my $two                           = $c->player_logs_in('playertwo');


unlike($one->types_in('look'),    qr{sack});
unlike($one->types_in('look'),    qr{potato});
like($one->types_in('look'),      qr{chest});

like($one->types_in('take rock'), qr{You take the rock\.});
like($two->get_output,            qr{playerone picks up a rock\.}i);

is($objects{rock}->held_by, $one);

unlike($one->types_in('look'),    qr{A rock is laying on the ground here\.});

like($one->types_in('drop rock'), qr{You drop the rock\.});
is_deeply($one->output_queue,     []);

like($two->get_output,            qr{playerone drops a rock\.}i);
is_deeply($one->output_queue,     []);

like($one->types_in('take sword'), qr{No object of that name is here\.});

# make sure nothing broadcasts to self
is_deeply($one->output_queue,     []);

$two->types_in('north');                                      $one->get_output;
like($two->types_in('take sword'), qr{You take the sword\.}); $one->get_output;
like($two->types_in('take sword'), qr{You are already carrying that!});

$two->types_in('south');           $one->get_output;
$two->types_in('drop sword');      $one->get_output;

my $look_output                    = $one->types_in('look');

like($look_output,                 qr{A rock});
like($look_output,                 qr{a sword});

like($one->types_in('take all'),   qr{You take everything you can\.});
like($two->get_output,             qr{playerone takes everything he can\.});
is_deeply($one->output_queue,      []);

like($one->types_in('take all'),   qr{There is nothing here for you to take\.});

my @output_lines                   = split /\n/, $one->types_in('inventory');

is($output_lines[0],               q{Your backpack contains:});
like($output_lines[1],             qr{\brock\b});
like($output_lines[1],             qr{\bsword\b});

like($two->get_output,             qr{playerone rummages through his backpack}i);
is_deeply($one->output_queue,      []);

like($two->types_in('inventory'),  qr{Your backpack contains nothing\.});
$one->get_output;

like($one->types_in('drop all'),   qr{You drop everything you can\.});
like($two->get_output,             qr{playerone drops everything he can\.}i);

# test bug where I don't see the rock on the ground
$one->types_in('take sword');      $two->get_output;
like($two->types_in('take rock'),  qr{You take the rock\.});

$_->held_by($two) for grep { $_->can('held_by') and not $_->contained_by } @o;

$two->types_in('drop sword');
like($two->types_in('look'),       qr{sword laying on the ground});
$objects{sword}->held_by($two);

# examine
like($two->types_in('examine sign'), qr{Why do you care});
like($two->types_in('examine rock'), qr{You notice nothing special\.});

like($one->types_in('look in chest'),        qr{it's closed}i);
like($one->types_in('open chest'),           qr{you open the chest}i);
like($one->types_in('open chest'),           qr{that's already open}i);

like($one->types_in('look in chest'),        qr{sack}i);
like($one->types_in('take sack from chest'), qr{you take the sack out of the chest}i);

my $inv                                     = $one->types_in('inventory');
like($inv,                                  qr{sack}i);
like($inv,                                  qr{potato}i); # inside the sack

like($one->types_in('drop sack'),           qr{you drop the sack}i);

my $look                                    = $one->types_in('look');
like($look,                                 qr{sack}i);
unlike($look,                               qr{potato}i); # shouldn't see it

# test the 'empty' command
like($one->types_in('empty sack'),          qr{you take the potato from the sack, and put it on the ground}i);
like($one->types_in('look'),                qr{potato});

#test 'put'
like($one->types_in('put potato in chest'), qr{you put the potato in the chest}i);
like($one->types_in('put potato in chest'), qr{that's already inside something}i);
like($one->types_in('look in chest'),       qr{potato});

like($one->types_in('close chest'),         qr{you close the chest}i);
like($one->types_in('close chest'),         qr{that's already closed}i);

like($one->types_in('open door'),           qr{you open the door}i);
like($one->types_in('look'),                qr{there is an open door here.+east}ism); # east exit shows up

like($one->types_in('close door'),          qr{you close the door}i);

{
    my $look                                = $one->types_in('look');
    ::unlike($look,                         qr{east}i, 'door conceals new exit (east)');
    ::like($look,                           qr{closed door}i, 'player sees that door has been closed');
}

like($one->types_in('east'),                qr{you can't go that way}i);

like($one->types_in('open door'),           qr{you open the door}i);
unlike($one->types_in('east'),              qr{you can't go that way}i);
unlike($one->types_in('west'),              qr{you can't go that way}i);

like($one->types_in('open trapdoor'),       qr{you open the trapdoor}i);
like($one->types_in('look'),                qr{down}i);

unlike($one->types_in('down'),              qr{you can't go that way}i);

like($one->types_in('close trapdoor'),      qr{you close the trapdoor}i);
like($one->types_in('look'),                qr{none}i); # no exits -- trapped!

like($one->types_in('open trapdoor'),       qr{you open the trapdoor}i);

like($one->types_in('look'),                qr{up}i);

like($two->types_in('wield sword'),         qr{you wield the sword}i);

like($two->types_in('wear helmet'),         qr{you put on the helmet}i);


$objects{$_}->held_by($one) for qw/shoes boots/;
like($one->types_in('wear shoes'),          qr{you put on the shoes}i);
like($one->types_in('wear boots'),          qr{remove your shoes first}i);

ok($objects{sword}->wielded,                 'sword got wielded');
ok($objects{helmet}->worn,                   'helmet got worn');

my $eq                                      = $two->types_in('equipment');
like($eq,                                   qr{wielding:.+sword}i);
like($eq,                                   qr{head:.+helmet}i);

like($two->types_in('remove helmet'),       qr{you take off the helmet}i);

done_testing();
