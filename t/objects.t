#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar qw(build_preset_game);
use AberMUD::Util;

my ($c, $locations) = build_preset_game(
    'two_wide',
    extra => [
        {
            locations => {
                room1 => {
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
                        ladder => {
                            traits      => [qw/Multistate Gateway/],
                            descriptions => [
                                undef, # user doesn't see it when it's not open
                                'A ladder levitates in the sky',
                            ],
                        },
                    },
                },
                room2 => {
                    has_objects => {
                        sword => {
                            traits => [qw/Weapon Getable/],
                            description => 'Here lies a sword run into the ground.',
                            dropped_description => 'There is a sword laying on the ground here.',
                        },
                    },
                },
                blue => {
                    title              => 'Blue Room',
                    description        => "It smells like a sky!\n",
                    has_objects => {
                        ladder => {
                            traits      => [qw/Multistate Gateway/],
                            descriptions => [
                                undef,
                                'A levitating ladder below awaits your descent.',
                            ]
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
                misc => {
                    title              => 'Room of Etcetera',
                    description        => "The other stuff.",
                },
            },
            gateways => {
                'door@room1' => {
                    north => 'door@red',
                },
                'door@red' => {
                    south => 'door@room1',
                },
                'trapdoor@room1' => {
                    down => 'trapdoor@yellow',
                },
                'trapdoor@yellow' => {
                    up => 'trapdoor@room1',
                },
                'ladder@room1' => {
                    up => 'ladder@blue',
                },
                'ladder@blue' => {
                    down => 'ladder@room1',
                },
            },
        },
    ],
);

my $u = $c->universe;
my $b = $c->controller->backend;

ok(my @o = $u->get_objects, 'objects loaded');

ok(scalar(grep { $_->does('AberMUD::Object::Role::Getable') } @o) >= 6);

my %objects                       = map {;
    sprintf('%s@%s', $_->name, $_->final_location->moniker) => $_
} @o;

my ($one, $conn_one)              = $b->new_player('playerone');
my ($two, $conn_two)              = $b->new_player('playertwo');


unlike($b->inject_input($conn_one, 'look'),    qr{sack});
unlike($b->inject_input($conn_one, 'look'),    qr{potato});
like($b->inject_input($conn_one, 'look'),      qr{chest});

like($b->inject_input($conn_one, 'take rock'), qr{You take the rock\.});
like($conn_two->get_output,            qr{playerone picks up a rock\.}i);

$u->carry($one, $objects{'rock@room1'});

unlike($b->inject_input($conn_one, 'look'),    qr{A rock is laying on the ground here\.});

like($b->inject_input($conn_one, 'drop rock'), qr{You drop the rock\.});
is_deeply($conn_one->output_queue,     []);

like($conn_two->get_output,            qr{playerone drops a rock\.}i);
is_deeply($conn_one->output_queue,     []);

like($b->inject_input($conn_one, 'take sword'), qr{No object of that name is here\.});

# make sure nothing broadcasts to self
is_deeply($conn_one->output_queue,     []);

$b->inject_input($conn_two, 'east');                                      $conn_one->get_output;
like($b->inject_input($conn_two, 'take sword'), qr{You take the sword\.}); $conn_one->get_output;
like($b->inject_input($conn_two, 'take sword'), qr{You are already carrying that!});

$b->inject_input($conn_two, 'west');           $conn_one->get_output;
$b->inject_input($conn_two, 'drop sword');      $conn_one->get_output;

my $look_output                    = $b->inject_input($conn_one, 'look');

like($look_output,                 qr{A rock});
like($look_output,                 qr{a sword});

like($b->inject_input($conn_one, 'take all'),   qr{You take everything you can\.});
like($conn_two->get_output,             qr{playerone takes everything he can\.});
is_deeply($conn_one->output_queue,      []);

like($b->inject_input($conn_one, 'take all'),   qr{There is nothing here for you to take\.});

my @output_lines                   = split /\n/, $b->inject_input($conn_one, 'inventory');

is($output_lines[0],               q{Your backpack contains:});
like($output_lines[1],             qr{\brock\b});
like($output_lines[1],             qr{\bsword\b});

like($conn_two->get_output,             qr{playerone rummages through his backpack}i);
is_deeply($conn_one->output_queue,      []);

like($b->inject_input($conn_two, 'inventory'),  qr{Your backpack contains nothing\.});
$conn_one->get_output;

like($b->inject_input($conn_one, 'drop all'),   qr{You drop everything you can\.});
like($conn_two->get_output,             qr{playerone drops everything he can\.}i);


# test bug where I don't see the rock on the ground
$b->inject_input($conn_one, 'take sword');      $conn_two->get_output;
like($b->inject_input($conn_two, 'take rock'),  qr{You take the rock\.});

my @objects_for_two = grep { $_->can('held_by') and not $_->contained_by } @o;
$one->_carrying->remove($objects{'sword@room2'});
$u->carry($two, $_) for @objects_for_two;
$two->_carrying->insert(@objects_for_two);

$b->inject_input($conn_two, 'drop sword');
like($b->inject_input($conn_two, 'look'),       qr{sword laying on the ground});
$u->carry($two, $objects{'sword@room2'});

# examine
like($b->inject_input($conn_two, 'examine sign'), qr{Why do you care});
like($b->inject_input($conn_two, 'examine rock'), qr{You notice nothing special\.});

like($b->inject_input($conn_one, 'look in chest'),        qr{it's closed}i);
like($b->inject_input($conn_one, 'open chest'),           qr{you open the chest}i);
like($b->inject_input($conn_one, 'open chest'),           qr{that's already open}i);

like($b->inject_input($conn_one, 'look in chest'),        qr{sack}i);
like($b->inject_input($conn_one, 'take sack from chest'), qr{you take the sack out of the chest}i);

my $inv                                     = $b->inject_input($conn_one, 'inventory');
like($inv,                                  qr{sack}i);
like($inv,                                  qr{potato}i); # inside the sack

like($b->inject_input($conn_one, 'drop sack'),           qr{you drop the sack}i);

my $look                                    = $b->inject_input($conn_one, 'look');
like($look,                                 qr{sack}i);
unlike($look,                               qr{potato}i); # shouldn't see it

# test the 'empty' command
like($b->inject_input($conn_one, 'empty sack'),          qr{you take the potato from the sack, and put it on the ground}i);
like($b->inject_input($conn_one, 'look'),                qr{potato});

#test 'put'
like($b->inject_input($conn_one, 'put potato in chest'), qr{you put the potato in the chest}i);
like($b->inject_input($conn_one, 'put potato in chest'), qr{that's already inside something}i);
like($b->inject_input($conn_one, 'look in chest'),       qr{potato});

like($b->inject_input($conn_one, 'close chest'),         qr{you close the chest}i);
like($b->inject_input($conn_one, 'close chest'),         qr{that's already closed}i);

like($b->inject_input($conn_one, 'open door'),           qr{you open the door}i);
like($b->inject_input($conn_one, 'look'),                qr{there is an open door here.+east}ism); # east exit shows up

like($b->inject_input($conn_one, 'close door'),          qr{you close the door}i);

{
    my $look                                = $b->inject_input($conn_one, 'look');
    ::unlike($look,                         qr{north}i, 'door conceals north exit');
    ::like($look,                           qr{closed door}i, 'player sees that door has been closed');
}

like($b->inject_input($conn_one, 'north'),                qr{you can't go that way}i);

like($b->inject_input($conn_one, 'open door'),           qr{you open the door}i);
unlike($b->inject_input($conn_one, 'north'),              qr{you can't go that way}i);
unlike($b->inject_input($conn_one, 'south'),              qr{you can't go that way}i);

like($b->inject_input($conn_one, 'open trapdoor'),       qr{you open the trapdoor}i);
like($b->inject_input($conn_one, 'look'),                qr{down}i);

unlike($b->inject_input($conn_one, 'down'),              qr{you can't go that way}i);

like($b->inject_input($conn_one, 'close trapdoor'),      qr{you close the trapdoor}i);
like($b->inject_input($conn_one, 'look'),                qr{none}i); # no exits -- trapped!

like($b->inject_input($conn_one, 'open trapdoor'),       qr{you open the trapdoor}i);

like($b->inject_input($conn_one, 'look'),                qr{up}i);

like($b->inject_input($conn_two, 'wield sword'),         qr{you wield the sword}i);

like($b->inject_input($conn_two, 'wear helmet'),         qr{you put on the helmet}i);


$u->carry($one, $objects{$_}) for qw/shoes@room1 boots@room1/;
$one->_carrying->insert(@objects{qw/shoes@room1 boots@room1/});
like($b->inject_input($conn_one, 'wear shoes'),          qr{you put on the shoes}i);
like($b->inject_input($conn_one, 'wear boots'),          qr{remove your shoes first}i);

ok($objects{'sword@room2'}->wielded,                 'sword got wielded');
ok($objects{'helmet@room1'}->worn,                   'helmet got worn');

my $eq                                      = $b->inject_input($conn_two, 'equipment');
like($eq,                                   qr{wielding:.+sword}i);
like($eq,                                   qr{head:.+helmet}i);

like($b->inject_input($conn_two, 'remove helmet'),       qr{you take off the helmet}i);
$b->inject_input($conn_one, 'up');

unlike($b->inject_input($conn_one, 'look'), qr{ladder}, "player doesn't see ladder");
$u->set_state($objects{'ladder@room1'}, 1);
like($b->inject_input($conn_one, 'look'), qr{ladder}, "ladder is revealed by state change");
my $l = $one->location;
$b->inject_input($conn_one, 'up');
isnt($one->location, $l, "ladder's state change allowed the player to go to revealed exit");

# test cloning

$b->inject_input($conn_two, 'drop rock');
my $cloned = $u->clone_object(
    $objects{'rock@room1'},
    location    => $locations->{misc},
);

ok($cloned);
$u->change_location($one, $locations->{misc});
like($b->inject_input($conn_one, 'look'), qr{A rock is laying on the ground here\.}, 'cloned object is seen in the universe');
like($b->inject_input($conn_one, 't rock'), qr{You take the rock\.}, 'cloned object is seen in the universe');

done_testing();
