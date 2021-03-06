#!/usr/bin/env perl
use strict;
use warnings;
# PODNAME: build_kdb_from_cache.pl

use JSON;
use File::Slurp;
use File::Basename;
use autodie;

use KiokuDB;
use KiokuDB::Util qw(set);

use lib 'lib', 'extlib';
use AberMUD::Util;
use AberMUD::Universe;
use AberMUD::Config;
use AberMUD::Zone;
use AberMUD::Mobile;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Storage;

use constant DEFAULT_START_LOC => 'church@start';

###########################################
###########################################
###########################################

my $json = JSON->new->pretty or die $!;
my (%expanded, %info);
foreach my $file (<data/json/*.json>) {
    my $contents = read_file($file);
    print STDERR "$file... ";

    (my $zone_name = lc $file) =~ s{data/json/(.+?)\.json}{$1}s or die "invalid zone";
    my $zone_info;

    print STDERR "decoding... ";
    my $json_string = read_file "data/json/$zone_name.json";
    $zone_info = $json->decode($json_string);

    # since we don't accumulate info this way, we must do it manually
    for (qw/mob obj loc/) {
        if ($info{$_}) {
            %{$info{$_}} = (%{$info{$_}}, %{$zone_info->{$_}});
        }
        else {
            $info{$_} = $zone_info->{$_};
        }
    }

    print STDERR "expanding... ";

    if ($zone_info) {
        expand_zone_data(\%expanded, $zone_info, $zone_name);
    }

    print STDERR "\n";
}

link_zone_data(\%expanded, \%info);

store_zone_data(\%expanded);

###########################################
###########################################
###########################################

sub write_pretty_json {
    my $file = shift;
    my $data = shift;

    open my $fh, '>', $file;
    print $fh $json->encode($data);
    close $fh;
}

sub construct_info_from_parsed {
    my ($info, $results, $zone_name) = @_;

    my @locs = map {
        $_->{LocFlags}{lflags} = +{ FlagItem => [] }
        if $_->{LocFlags}{lflags}
            and not ref $_->{LocFlags}{lflags};

        +{
            id          => $_->{Map}{LocID},
            zone        => $zone_name,
            altitude    => ($_->{AltitudeLine} || {})->{'alt'},
            flags       => handle_flag_statement($_->{LocFlags}{lflags}),
            title       => $_->{LocTitle},
            description => $_->{LocDescription}{CaretString}{Inside},
            exits       => {
                map {;
                    $_->{ExitLetter} => $_->{exit_dest}
                } @{ $_->{Map}{Exit} },
            },
        },
    } @{ $results->{Zone}{Locations}{Location} };
    $info->{loc}{lc "$_->{id}\@$zone_name"} = $_ for @locs;

    my @mobs = map {
        +{ create_map_from_statements( @{ $_->{Statement} } ) },
    } @{ $results->{Zone}{Mobiles}{Mobile} };
    $info->{mob}{lc "$_->{name}\@$zone_name"} = $_ for @mobs;

    my @objs = map {
        +{ create_map_from_statements( @{ $_->{ObjectStatement} } ) },
    } @{ $results->{Zone}{Objects}{Object} };
    $info->{obj}{lc "$_->{name}\@$zone_name"} = $_ for @objs;

    return +{
        mob => +{ map {; lc("$_->{name}\@$zone_name") => $_ } @mobs },
        obj => +{ map {; lc("$_->{name}\@$zone_name") => $_ } @objs },
        loc => +{ map {; lc("$_->{id}\@$zone_name") => $_ } @locs },
    }
}

sub create_map_from_statements {
    map {;
        my $key = lc($_->{key});
        my $value;

        if (ref($_->{value}) eq 'HASH') {
            $value = $_->{value}{FlagItem}
                ? handle_flag_statement($_->{value})
                : handle_quoted_statement($_->{value});
        }
        else { $value = $_->{value} }

        $key => $value
    } @_
}

sub handle_flag_statement {
    my $flag_data = shift;

    ref($flag_data) eq 'HASH'
        or return [];

    ref($flag_data->{FlagItem}) eq 'ARRAY'
        or return [];

    my @flags;

    foreach my $flag_node (@{$flag_data->{FlagItem}}) {
        ref($flag_node) eq 'HASH'
            or return [];

        push @flags, $flag_node->{Word};
    }

    if (ref $flag_data eq 'HASH') {
        return [] unless $flag_data
    }
    else { return [] };

    return \@flags;
}

sub handle_quoted_statement {
    my $stmt = shift;

    my $sub_result;
    if (my $quoted = $stmt->{Quoted}) {

        $quoted->{"${_}String"} and
            $sub_result = $quoted->{"${_}String"}{Inside}
                for qw[Caret Quote Apostrophe];

    }
    else { $sub_result = '&+MUnknown value&*' }

    return $sub_result;
}

sub format_flags {
    my %result;

    foreach my $flags (@_) {
        next unless ref $flags eq 'ARRAY';
        $result{lc $_} = 1 for @$flags;
    }

    return \%result;
}

sub expand_zone_data {
    my $expanded      = shift;
    my $info      = shift;
    my $zone_name = shift;

    expand_zone($expanded, $zone_name);
    expand_mobiles($expanded, $info->{mob}, $zone_name),
    expand_objects($expanded, $info->{obj}, $zone_name),
    expand_locations($expanded, $info->{loc}, $zone_name),
}

sub expand_zone {
    my $expanded = shift;
    my $zone_name = shift;
    $expanded->{zone}{lc $zone_name}
        = AberMUD::Zone->new(name => lc $zone_name);
}

sub expand_mobiles {
    my $expanded      = shift;
    my $mobs = shift;
    my $zone_name = shift;

    my %mob_objects;
    foreach my $mob_data (values %$mobs) {

        my %params = (
            name                => $mob_data->{name},
            damage              => $mob_data->{damage},
            armor               => $mob_data->{armor},
            aggression          => $mob_data->{aggression},
            speed               => $mob_data->{speed},
            description         => $mob_data->{description},
            examine_description => $mob_data->{examine},
            display_name        => $mob_data->{pname}
                                || $mob_data->{altname}
                                || ucfirst($mob_data->{name}),
            basestrength        => $mob_data->{strength},
            intrinsics          => format_flags(
                                        $mob_data->{pflags},
                                        $mob_data->{eflags},
                                    ),
            spells              => format_flags($mob_data->{sflags}),

        );

        # try to fall back on attr defaults
        delete $params{$_} for grep { not defined $params{$_} } keys %params;

        my $m = AberMUD::Mobile->new(%params);

        my $key = sprintf q[%s@%s], $mob_data->{name}, $zone_name;
        $expanded->{mob}{lc $key} = $m;
    }
}

sub expand_objects {
    my $expanded      = shift;
    my $objs      = shift;
    my $zone_name = shift;

    my %obj_objects; # ugh :)
    foreach my $obj_data (values %$objs) {
        my @traits = calculate_object_traits($obj_data);

        my $oclass = @traits ? AberMUD::Object->with_traits(@traits)
                             : 'AberMUD::Object';

        my $oflags = format_flags($obj_data->{oflags});
        my $coverage = format_flags($obj_data->{aflags});
        my %params = (
            flags               => $oflags,
            coverage            => $coverage,
            damage              => $obj_data->{damage},
            buy_value           => $obj_data->{bvalue},
            size                => $obj_data->{size},
            name                => $obj_data->{pname} || $obj_data->{name},
            examine_description => $obj_data->{examine},
            alt_name            => $obj_data->{altname} || $obj_data->{name},
            description         => $obj_data->{'desc[0]'},
        );

        delete $params{$_} for grep { not defined $params{$_} } keys %params;

        my $key = $obj_data->{name} . '@' . $zone_name;
        $params{moniker} = $key;

        my %extra_params = calculate_rolebased_params($obj_data);

        if (@traits) {
            my $anon = AberMUD::Object->with_traits(@traits) ->new(
                %params, %extra_params,
            );

            $expanded->{obj}{lc $key} = $anon;
        }
        else {
            $expanded->{obj}{lc $key} = AberMUD::Object->new(
                %params, %extra_params,
            );
        }
    }
}

sub calculate_object_traits {
    my $data = shift;
    my $flags = format_flags($data->{oflags});

    my @traits;
    push @traits, 'Gateway'               if $flags->{linked};
    push @traits, 'Openable', 'Closeable' if $flags->{openable};
    push @traits, 'Lockable'              if $flags->{lockable};
    push @traits, 'Pushable'              if $flags->{pushable};
    push @traits, 'Pushable'              if $flags->{pushtoggle};
    push @traits, 'Food'                  if $flags->{food};
    push @traits, 'Wearable'              if $flags->{wearable}
                                          or $flags->{armor};
    push @traits, 'Key'                   if $flags->{key};
    push @traits, 'Lightable'             if $flags->{lightable};
    push @traits, 'Weapon'                if $flags->{weapon};
    push @traits, 'Container'             if $flags->{container};
    push @traits, 'Getable'               if !$flags->{noget};

    push @traits, 'Gateway'               if $data->{linked};

    {
        next unless $data->{linked};
        next if $flags->{openable};
        next if $flags->{pushable};
        next if $flags->{pushtoggle};
        next if $flags->{lockable};

        push @traits, 'Multistate';
    }

    return @traits;
}

sub calculate_rolebased_params {
    my $obj_data = shift;

    my %data = (
        openable => {
            open_description   => 0,
            closed_description => 1,
        },
        lockable => {
            open_description   => 0,
            closed_description => 1,
            locked_description => 2,
        },
        getflips => {
            dropped_description => 0,
            description         => 1,
        },
        pushable => {
            pushed_description => 0,
            description        => 1,
        },
    );

    my %params;

    my $flags = format_flags($obj_data->{oflags});
    my $preset_multistate = 0;
    foreach my $flag (keys %data) {
        if ($flags->{$flag}) {
            foreach my $attr (keys %{ $data{$flag} }) {
                $preset_multistate = 1;
                my $legacy_attr = 'desc[' . $data{$flag}{$attr} . ']';
                $obj_data->{$legacy_attr} and
                    do {$params{$attr} = $obj_data->{$legacy_attr } };
            }
        }
    }

    if ($flags->{openable} and $obj_data->{state}) {
        if ($obj_data->{state} eq '1') {
            $params{opened} = 0;
        }
        elsif ($obj_data->{state} eq '0') {
            $params{opened} = 1;
        }
    }

    if ($flags->{lockable} and $obj_data->{state}) {
        if ($obj_data->{state} eq '2') {
            $params{locked} = 1;
        }
        else {
            $params{locked} = 0;
        }
    }

    # multi-state but not openable/etc...
    if ($obj_data->{linked} and !$preset_multistate) {
        my @descs = map { $obj_data->{"desc[$_]"} }
                    (0 .. $obj_data->{maxstate}||0);

        $params{descriptions} = \@descs;
        $params{state} = $obj_data->{state} || 0;
    }

    return %params;
}

sub expand_locations {
    my $expanded  = shift;
    my $locs      = shift;
    my $zone_name = shift;

    my %loc_objects;
    foreach my $loc_data (values %$locs) {

        my $key = sprintf q[%s@%s], $loc_data->{id}, $zone_name;

        my $loc_class;
        my %params = (
            title       => $loc_data->{title},
            description => $loc_data->{description},
            flags       => format_flags($loc_data->{flags}),
            moniker     => $key,
        );
        if (lc($key) eq 'store@blizzard') {
            $loc_class = AberMUD::Location->with_traits('Shop');
            $params{_stock_objects} = {
                torch => {
                    object => AberMUD::Object->with_traits(
                        'Getable',
                        'Lightable',
                    )->new(
                        name      => 'torch',
                        buy_value => 10,
                    ),
                },
                bread => {
                    object => AberMUD::Object->with_traits(
                        'Getable',
                        'Food',
                    )->new(
                        name      => 'bread',
                        buy_value => 10,
                    ),
                },
                sack => {
                    object => AberMUD::Object->with_traits(
                        'Getable',
                        'Container',
                    )->new(
                        name      => 'sack',
                        buy_value => 10,
                    ),
                },
            };
        }
        else {
            $loc_class = 'AberMUD::Location';
        }
        my $l = $loc_class->new(%params);


        $expanded->{loc}{lc $key} = $l;

    }
}

sub link_zone_data {
    my ($expanded, $info) = @_;

    # locations
    link_to_zones($expanded, $info);
    link_location_exits($expanded, $info);  # L->dir = L
    link_mobile_locations($expanded, $info); # M->location = L
    link_object_locations($expanded, $info); # O->location = L
}

sub link_to_zones {
    my ($expanded, $info) = @_;

    for (qw/mob obj loc/) {
        while (my ($id, $data) = each %{ $expanded->{$_} }) {
            (my $zone_name = $id) =~ s{.+@}{};
            $data->zone($expanded->{zone}{$zone_name});
        }
    }
}

sub link_location_exits {
    my ($expanded, $info) = @_;

    my %letter_map = map {; substr($_, 0, 1) => $_} qw(
                                                    north
                                                    south
                                                    east
                                                    west
                                                    up
                                                    down
                                                );

    while (my ($loc_id, $loc_data) = each %{ $expanded->{loc} }) {
        while (my ($letter, $direction) = each %letter_map) {
            my $linked_loc_id = $info->{loc}{$loc_id}{exits}{$letter};
            next unless $linked_loc_id;

            $linked_loc_id = lc $linked_loc_id;

            $linked_loc_id =~ /@/
                or $linked_loc_id .= '@' . $loc_data->zone->name;

            (my $linked_zone = $linked_loc_id) =~ s/.+@//;

            if ($linked_loc_id =~ /^\^/) {
                (my $door_id = lc($linked_loc_id)) =~ s/^\^//;

                my $linked_door_id
                    = lc($info->{obj}{$door_id}{linked}||'') or die "no linked for $door_id";

                $linked_door_id =~ /@/
                    or $linked_door_id .= '@' . $linked_zone;

                my $link_attr = "${direction}_link";

                do { warn "no object for $door_id"; next }
                    unless $expanded->{obj}{$door_id};

                do {warn $door_id; warn "no object for $linked_door_id"; next }
                    unless $expanded->{obj}{$linked_door_id};

                $expanded->{obj}{$door_id}->$link_attr(
                    $expanded->{obj}{$linked_door_id}
                );
            }
            elsif ($expanded->{loc}{$linked_loc_id}) {
                $expanded->{loc}{$loc_id}->$direction(
                    $expanded->{loc}{$linked_loc_id}
                );
            }
            else { warn "$linked_loc_id doesn't exist" }
        }
    }
}

sub link_object_locations {
    my ($expanded, $info) = @_;

    my %not_linked = map {; $_ => 1 } keys %{ $expanded->{obj} };

    # extremely naive elimination loop
    my $prev = -1;
    while (scalar keys %not_linked) {
        my $at_loop = 0;
        if ($prev == scalar keys %not_linked) {
            $at_loop = 1;
        }
        $prev = scalar keys %not_linked;
        for my $obj_id (keys %not_linked) {
            my $obj = $expanded->{obj}{$obj_id};
            if ($at_loop) {
                warn scalar(keys %not_linked);
                die "Hit a loop at $obj_id";
            }
            my $full_oloc = $info->{obj}{$obj_id}{location} or next;

            my ($loctype, $odest) = split /:/, $full_oloc;

            $odest ||= '';
            $odest =~ /@/ or $odest .= '@' . $obj->zone->name;

            my $location;
            if ($loctype eq 'IN_ROOM') {
                do { warn "no loc for $odest"; next }
                    unless $expanded->{loc}{lc $odest};

                $location = $expanded->{loc}{lc $odest};
            }
            elsif ($loctype eq 'IN_CONTAINER') {
                $expanded->{obj}{lc $odest}->put_in($obj);
                $location = $expanded->{obj}{lc $odest}->location;
            }
            elsif (
                $loctype eq 'CARRIED_BY'
                    or $loctype eq 'WIELDED_BY'
                    or $loctype eq 'WORN_BY'
                    or $loctype eq 'BOTH_BY'
            ) {

                do { warn "$odest can't be carried"; next }
                    unless $obj->can('held_by');

                do { warn "no mob called $odest"; next }
                    unless $expanded->{mob}{lc $odest};

                $expanded->{mob}{lc $odest}->take($obj);

                if ($loctype eq 'WORN_BY' or $loctype eq 'BOTH_BY') {
                    $obj->worn(1);
                }

                if ($loctype eq 'WIELDED_BY' or $loctype eq 'BOTH_BY') {
                    $obj->wielded(1);
                    $expanded->{mob}{lc $odest}->wielding($obj);
                }

                $location = $expanded->{mob}{lc $odest}->location;
            }
            elsif ($expanded->{loc}{lc $loctype}) {
                do { warn "no loc for $odest"; next }
                    unless $expanded->{loc}{lc $loctype};

                $location = $expanded->{loc}{lc $loctype};
            }
            else {
                # unsupported type or just no loc
                delete $not_linked{$obj_id};
            }

            if (defined $location) {
                $obj->location($location);
                $location->objects_in_room->insert($obj);
                delete $not_linked{$obj_id};
            }
        }
    }
}

sub link_mobile_locations {
    my ($expanded, $info) = @_;

    while (my ($mob_id, $mob) = each %{ $expanded->{mob} }) {
        my $mloc = $info->{mob}{$mob_id}{location} or next;
        $mloc =~ /@/ or $mloc .= '@' . $mob->zone->name;

        do { warn "no loc for $mloc"; next }
            unless $expanded->{loc}{lc $mloc};

        $mob->location($expanded->{loc}{lc $mloc});
    }
}

sub store_zone_data {
    my $expanded = shift;

    unlink 'abermud.db' if -e 'abermud.db';

    my $config = AberMUD::Config->new(
        location => $expanded->{loc}{+DEFAULT_START_LOC},
        input_states => [qw(Login::Name Game)],
    );

    my $universe = AberMUD::Universe->new;

    $universe->mobiles->insert(values %{ $expanded->{mob} });
    $universe->objects->insert(values %{ $expanded->{obj} });
    $universe->locations->insert(values %{ $expanded->{loc} }); # FIXME should be lazy-loadable

    $config->universe($universe);

    my $storage = AberMUD::Storage->new;

    $storage->build_universe(
        config    => $config,
        locations => set(values %{ $expanded->{loc} }),
    );


}
