#!/usr/bin/env perl
package AberMUD::Test::Sugar;
use strict;
use warnings;

use Moose::Meta::Class ();
use KiokuDB::Util qw(set);
use Hash::Merge;
use Clone;

use AberMUD;
use AberMUD::Mobile;
use AberMUD::Object;
use AberMUD::Location;
use AberMUD::Location::Util qw(directions);
use AberMUD::Player;
use AberMUD::Config;
use AberMUD::Storage;
use AberMUD::Zone;
use AberMUD::Universe;
use AberMUD::Special;

use base 'Exporter';
our @EXPORT_OK = qw(build_container build_game build_preset_game);

sub build_container {
    my %args = @_;
    # XXX deleting dsn from args is weird
    my $dsn = delete $args{dsn} || 'hash';

    my $c = AberMUD->new(
        backend_class  => 'AberMUD::Backend::Test',
        backend_params => ['input_states', 'storage'],
        storage        => AberMUD::Storage->new(dsn => $dsn),
        special        => AberMUD::Special->new,
        %args,
    );

    return $c;
}

my $ZONE;
sub build_game {
    my %args = @_;
    my %data = %{ $args{config} || {} };

    my $locs = $data{locations};
    my $default_loc = $data{default_location};
    my $dsn = $data{dsn} || 'hash';
    my $zone_name = $data{zone};

    $ZONE = AberMUD::Zone->new(name => $zone_name);
    my (%all_objects, @all_mobiles, %all_locations);
    foreach my $loc (keys %$locs) {
        my %loc_params = (
            title       => $locs->{$loc}{title},
            description => $locs->{$loc}{description},
            zone        => $ZONE,
            moniker     => $loc,
            %{ $locs->{$loc}{extra_params} || {} }
        );

        my (@objects, @mobiles);
        if ($locs->{$loc}{has_objects}) {
            while (my ($obj_name, $obj_data) = each %{ $locs->{$loc}{has_objects} }) {
                push @objects, _handle_object($obj_name, $obj_data);
            }
        }

        if ($locs->{$loc}{has_mobiles}) {
            while (my ($mob_name, $mob_data) = each %{ $locs->{$loc}{has_mobiles} }) {
                my %data = _handle_mobile($mob_name, $mob_data);
                push @mobiles, @{ $data{mobiles} || [] };
                push @objects, @{ $data{objects} || [] };
            }
        }

        my $loc_node;
        if (my $loc_traits_ref = $locs->{$loc}{traits}) {
            $loc_node = AberMUD::Location->with_traits(@$loc_traits_ref)
                        ->new(%loc_params);
        }
        else {
            $loc_node = AberMUD::Location->new(%loc_params);
        }

        for (@objects) {
            $_->change_location($loc_node);
        }

        $_->location($loc_node) for @mobiles;

        $all_objects{$_->name . '@' . $loc} = $_ for @objects;
        push @all_mobiles, @mobiles;
        $all_locations{$loc} = $loc_node;
    }

    foreach my $loc (keys %$locs) {
        next unless $locs->{$loc}{exits};

        foreach my $exit (keys %{ $locs->{$loc}{exits} }) {
            $all_locations{$loc}->$exit($all_locations{$locs->{$loc}{exits}{$exit}});
        }
    }

    my $gateways = $data{gateways};

    if ($gateways) {
        while (my ($object, $data) = each %$gateways) {
            while (my ($exit, $link) = each %$data) {
                my $method = $exit . '_link';
                $all_objects{$object}->$method($all_objects{$link});
            }
        }

    }

    my $c = build_container(%{$args{container_args} || {}});

    #my $k = KiokuDB->connect('hash', create => 1);

    my $storage = $c->storage;

    my $players = $data{players};

    my $universe = AberMUD::Universe->new(
        objects => set(values %all_objects),
        mobiles => set(@all_mobiles),
    );

    my $config = AberMUD::Config->new(
        input_states => [qw(Login::Name Game)],
        location     => $all_locations{$data{default_location}},
        universe     => $universe,
    );
    my $locations = set(values %all_locations);

    $storage->build_universe(
        config    => $config,
        locations => $locations,
    );

    # pre-load universe data
    $c->resolve(service => 'universe');

    if (wantarray) {
        return($c, \%all_locations);
    }
    else {
        return $c;
    }
}

sub _handle_object {
    my ($obj_name, $obj_data) = @_;
    my @objects;
    my $description = $obj_data->{description};
    #                || "Here lies a normal $obj_name";

    my $examine = $obj_data->{examine};
    #    || "It looks just like a normal $obj_name!";

    my @contained = _handle_objects_from_key($obj_data, 'contains');

    $obj_data->{covers} = +{ map {; $_ => 1 } @{ $obj_data->{covers} } };
    my %params = (
        name                => $obj_name,
        description         => $description,
        examine_description => $examine,
        zone                => $ZONE,
        open_description    => $obj_data->{open_description},
        closed_description  => $obj_data->{closed_description},
        locked_description  => $obj_data->{locked_description},
        dropped_description => $obj_data->{dropped_description},
        descriptions        => $obj_data->{descriptions},
        buy_value           => $obj_data->{bvalue},
        flags               => $obj_data->{oflags},
        coverage            => $obj_data->{covers},
        opened              => $obj_data->{opened} || 0,
    );

    # delete all undef values (for default fallback)
    delete $params{$_} for grep {not defined $params{$_}} keys %params;

    my $obj_class;
    if ($obj_data->{traits}) {
        $obj_class = AberMUD::Object->with_traits(@{delete $obj_data->{traits}});
    }
    else {
        $obj_class = 'AberMUD::Object';
    }

    my $obj = $obj_class->new(%params);

    if (@contained) {
        $obj->contents->insert(@contained);
        $_->contained_by($_->contained_by || $obj) for @contained;
    }

    return(@contained, $obj);
}

sub _handle_mobile {
    my ($mob_name, $mob_data) = @_;
    my @mobiles;

    my $sflags = delete $mob_data->{sflags} || [];
    my $pflags = delete $mob_data->{pflags} || [];
    my @spells = (@$sflags, @$pflags);

    $mob_data->{examine_description} ||=
        delete $mob_data->{examine};

    my %params = (
        name                => $mob_name,
        zone                => $ZONE,
        spells              => { map {; $_ => 1 } @spells },
        display_name        => delete $mob_data->{pname},
        %$mob_data,
    );

    delete $params{$_} for 'carrying', 'wielding', 'wearing';
    # delete all undef values (for default fallback)
    delete $params{$_} for grep {not defined $params{$_}} keys %params;

    my $mob = AberMUD::Mobile->new(%params);

    push @mobiles, $mob;

    my @carrying = _handle_objects_from_key($mob_data, 'carrying');
    my @wielding = _handle_objects_from_key($mob_data, 'wielding');
    my @wearing  = _handle_objects_from_key($mob_data, 'wearing');

    $_->held_by($mob) for @carrying, @wielding, @wearing;
    $_->worn(1)       for @wearing;
    $_->wielded(1)    for @wielding;

    $mob->wielding($wielding[0]) if @wielding;

    return(
        objects => [@carrying, @wielding, @wearing],
        mobiles => [@mobiles],
    );
}

sub _handle_objects_from_key {
    my $data = shift;
    my $key  = shift;

    my @objects;
    if ($data->{$key}) {
        while (my ($inside, $inside_data) = each %{ $data->{$key} }) {
            my @traits = ();
            if ($key eq 'carrying') {
                push(@traits, 'Getable');
            }
            elsif ($key eq 'wearing') {
                push(@traits, 'Getable');
                push(@traits, 'Wearable');
            }
            elsif ($key eq 'wielding') {
                push(@traits, 'Getable');
                push(@traits, 'Weapon');
            }

            $inside_data->{traits} ||= [];

            push @{$inside_data->{traits}}, @traits;

            push @objects, _handle_object($inside, $inside_data);
        }
    }

    return @objects;
}

sub location_preset {
    my $type = shift;
    my @extra = @_;

    # square, plus, N_wide, jack
    my %preset_dispatch = (
        square     => {
            default_location => 'northwest',
            locations => {
                northwest => {
                    title => 'Northwest Corner',
                    description => 'You are in the northwest corner of the universe.',
                    exits => {
                        south => 'southwest',
                        east  => 'northeast',
                    },
                },
                northeast => {
                    title => 'Northeast Corner',
                    description => 'You are in the northeast corner of the universe.',
                    exits => {
                        south => 'southeast',
                        west  => 'northwest',
                    },
                },
                southwest => {
                    title => 'Southwest Corner',
                    description => 'You are in the southwest corner of the universe.',
                    exits => {
                        north => 'northwest',
                        east  => 'southeast',
                    },
                },
                southeast => {
                    title => 'Southeast Corner',
                    description => 'You are in the southeast corner of the universe.',
                    exits => {
                        north => 'northeast',
                        west  => 'southwest',
                    },
                },
            }
        },
        plus       => {
            default_location => 'center',
            locations => {
                center => {
                    title => 'Center Room',
                    description => 'You are in the center of the universe.',
                    exits => {
                        north => 'northwing',
                        south => 'southwing',
                        east  => 'eastwing',
                        west => 'westwing',
                    },
                },
                northwing => {
                    title => 'Northern Wing',
                    description => 'You are in the north wing of the universe.',
                    exits => {
                        south => 'center',
                    },
                },
                southwing => {
                    title => 'Southern Wing',
                    description => 'You are in the south wing of the universe.',
                    exits => {
                        north => 'center',
                    },
                },
                eastwing => {
                    title => 'Eastern Wing',
                    description => 'You are in the east wing of the universe.',
                    exits => {
                        west => 'center',
                    },
                },
                westwing => {
                    title => 'Western Wing',
                    description => 'You are in the west wing of the universe.',
                    exits => {
                        east => 'center',
                    },
                },
            },
        },
        two_wide   => {
            default_location => 'room1',
            locations => {
                room1 => {
                    title => 'Room One',
                    description => 'You are in the first room.',
                    exits => {
                        east => 'room2',
                    },
                },
                room2 => {
                    title => 'Room Two',
                    description => 'You are in the second room.',
                    exits => {
                        west => 'room1',
                    },
                },
            }
        },
        three_wide => {
            default_location => 'room1',
            locations => {
                room1 => {
                    title => 'Room One',
                    description => 'You are in the first room.',
                    exits => {
                        east => 'room2',
                    },
                },
                room2 => {
                    title => 'Room Two',
                    description => 'You are in the second room.',
                    exits => {
                        west => 'room1',
                        east => 'room3',
                    },
                },
                room3 => {
                    title => 'Room Three',
                    description => 'You are in the third room.',
                    exits => {
                        west => 'room2',
                    },
                },
            }
        },
        four_wide  => {
            default_location => 'room1',
            locations => {
                room1 => {
                    title => 'Room One',
                    description => 'You are in the first room.',
                    exits => {
                        east => 'room2',
                    },
                },
                room2 => {
                    title => 'Room Two',
                    description => 'You are in the second room.',
                    exits => {
                        west => 'room1',
                        east => 'room3',
                    },
                },
                room3 => {
                    title => 'Room Three',
                    description => 'You are in the third room.',
                    exits => {
                        west => 'room2',
                        east => 'room4',
                    },
                },
                room4 => {
                    title => 'Room Four',
                    description => 'You are in the fourth room.',
                    exits => {
                        west => 'room1',
                        east => 'room3',
                    },
                },
            }
        },
    );

    # jack is 'plus' but with an 'up' and 'down' room
    $preset_dispatch{jack} = Clone::clone($preset_dispatch{plus});
    $preset_dispatch{jack}{locations}{highwing} = {
        title       => 'High Wing',
        description => 'You are in the high wing of the universe.',
        exits => {
            down        => 'center',
        },
    };
    $preset_dispatch{jack}{locations}{lowwing} = {
        title       => 'Low Wing',
        description => 'You are in the low wing of the universe.',
        exits       => {
            up          => 'center',
        },
    };
    $preset_dispatch{jack}{locations}{center}{exits}{up}
        = 'highwing';
    $preset_dispatch{jack}{locations}{center}{exits}{down}
        = 'lowwing';

    return unless exists $preset_dispatch{$type};

    my $config = $preset_dispatch{$type};

    $config->{zone} = $type;

    my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
    for (@extra) {
        next unless ref() eq 'HASH';

        $config = $merger->merge($config, $_);
    }

    return %$config;
}

sub build_preset_game {
    my $type = shift;
    my %args = @_;

    my @extra = @{ $args{extra} || [] };
    my %config = location_preset($type, @extra);

    return build_game(container_args => $args{container_args}, config => \%config);
}

1;
