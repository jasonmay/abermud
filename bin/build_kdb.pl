#!/usr/bin/env perl
use strict;
use warnings;
use Regexp::Grammars;
use JSON;
use File::Slurp;
use File::Basename;
use autodie;

use KiokuDB;

use lib 'dep/mud/dep/iomi/lib';
use lib 'dep/mud/lib';
use lib 'lib';
use AberMUD::Util;
use AberMUD::Universe::Sets;
use AberMUD::Config;
use AberMUD::Zone;
use AberMUD::Mobile;
use AberMUD::Location;
use AberMUD::Object;

my $parser = qr{
    <logfile:debug.log>
#        <debug:run>
    (
        <.ZoneDirective>?
        <[ZoneData]>*
        <Zone>?
    )+

    ############################################
    ############################################
    ############################################

    <token: eol>
        \n

    <token: ws>
        \s*

    <rule: ZoneDirective>
        %zone: <ZoneName=Word>

    <rule: ZoneData>
        %<zone_key=ZoneFields> : <zone_value=Word>

    <token: ZoneFields>
        rainfall | latitude

    <rule: Zone>
        (?: <Mobiles> | <Objects> | <Locations> )+

    <rule: Mobiles>
        %(?i:mobiles)
        <[Mobile]>+

    <rule: Objects>
        %(?i:objects)
        <[Object]>+

    <rule: Locations>
        %(?i:locations)
        <[Location]>+

    # MOBILES
    #################################################
    <rule: Mobile>
        <[Statement]>+
        [Ee]nd = <StmtValue>

    <rule: Statement>
    <key=Keyword> =? (?: <value=StmtValue> | <value=Flag> )

    <token: Keyword>
        (?![Ee]nd)<.Word>

    <token: StmtValue>
        <.Number> | <.FullLocID> | <.Word> | <Quoted>

    <token: Flag>
        \{<.ws>?<[FlagItem]>*<.ws>?\}

    <token: FlagItem>
        <Word> <.ws>?

    <token: Word>
        [\w\[\]]+

    <token: Quoted>
           <ApostropheString> | <QuoteString> | <CaretString>

    <token: ApostropheString>
        ' <Inside=ApostropheInside> '

    <token: ApostropheInside>
        (?: <.escape> | <.NonApostrophe> )*

    <token: NonApostrophe>
        [^']

    <token: QuoteString>
        " <Inside=QuoteInside> "

    <token: QuoteInside>
        (?: <.escape> | <.NonQuote> )*

    <token: NonQuote>
        [^"]

    <token: CaretString>
        \^ <Inside=CaretInside> \^

    <token: CaretInside>
        (?: <.escape> | <.NonCaret>)*

    <token: NonCaret>
        [^^]+

    <token: escape>
        \\ .

    # OBJECTS
    #################################################
    <rule: Object>
        <[ObjectStatement]>+
        [Ee]nd = <StmtValue>

    <rule: ObjectStatement>
        <key=Keyword> =? (?: <value=ObjectStmtValue> | <value=Flag> )

    <token: ObjectStmtValue>
        <.Number> | <.ObjectLocation> | <.Word> | <Quoted>

    <token: ObjectLocation>
        (?: <.LocationOptions> : )? <.FullLocID>

    <token: ObjectID>
        <.Word>

    <token: LocationOptions>
        IN_ROOM | CARRIED_BY | WIELDED_BY | WORN_BY | BOTH_BY | IN_CONTAINER

    # LOCATIONS
    #################################################
    <rule: Location>
        <Map>
        <AltitudeLine>?
        <LocFlags>
        <LocTitle> <LocDescription>

    <rule: Map>
        <LocID> <[Exit]>* ;

    <rule: AltitudeLine>
        Altitude = <alt=Number>

    <rule: LocFlags>
        (?i:lflags?) <lflags=Flag>

    <rule: Exit>
        <ExitLetter> : (?: <exit_dest=Door> | <exit_dest=FullLocID> )

    <token: ExitLetter>
        [nsewudNSEWUD]

    <token: LocID>
        <.Word>

    <token: FullLocID>
        (?: <.Word> @ )? <.LocID>

    <token: Door>
        \^ <.ObjectID>

    <rule: LocTitle>
        <.NonCaret>

    <rule: LocDescription>
        <CaretString>

    <token: Number>
        [-\d]+

}xs;

no Regexp::Grammars;

###########################################
###########################################
###########################################

my @zone_files;

@zone_files = @ARGV
    or @zone_files = get_all_zone_files();

my $json = JSON->new->pretty or die $!;
my (%expanded, %info);
foreach my $file (@zone_files) {
    my $contents = read_file($file);
    print STDERR "$file... ";
    $contents =~ s{/\* .*? \*/}{}gmsx;

    (my $zone_name = lc $file) =~ s{zones/(.+?)\.zone}{$1}s or die "invalid zone";
    my $zone_info;

    print STDERR "parsing... ";

    if ( -e "data/json/$zone_name.json") {
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

    }
    elsif ($contents =~ $parser) {
        my %results = %/;

        $zone_info = construct_info_from_parsed(\%info, \%results, $zone_name);

        print STDERR "caching... ";
        write_file("data/json/$zone_name.json", $json->encode($zone_info));
    }

    print STDERR "expanding... ";

    if ($zone_info) {
        expand_zone_data(\%expanded, $zone_info, $zone_name);
    }

    print STDERR "\n";
}

link_zone_data(\%expanded, \%info);

###########################################
###########################################
###########################################

sub get_all_zone_files {
    opendir(my $dh, 'zones');
    my @dirs = map { "zones/$_" } grep { substr($_,-5) eq '.zone' and -f "zones/$_" } readdir($dh);
    closedir($dh);
    return @dirs;
}

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
        $result{$_} = 1 for @$flags;
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

        $expanded->{mob}{sprintf q[%s@%s], $mob_data->{name}, $zone_name} = $m;
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
        my %params = (
            ungetable           => $oflags->{noget},
            flags               => $oflags,
            name                => $obj_data->{name},
            examine_description => $obj_data->{examine},
            alt_name            => $obj_data->{altname},
        );

        delete $params{$_} for grep { not defined $params{$_} } keys %params;

        my $key = $obj_data->{name} . '@' . $zone_name;

        my %extra_params = calculate_rolebased_params($expanded, $obj_data);

        $expanded->{obj}{$key} = $oclass->new(%params, %extra_params);
    }
}

sub calculate_object_traits {
    my $data = shift;
    my $flags = format_flags($data->{oflags});

    my @traits;
    push @traits, 'Gateway'               if $flags->{linked};
    push @traits, 'Openable', 'Closeable' if $flags->{openable};
    push @traits, 'Pushable'              if $flags->{pushable};
    push @traits, 'Food'                  if $flags->{food};
    push @traits, 'Wearable'              if $flags->{wearable}
                                          or $flags->{armor};
    push @traits, 'Key'                   if $flags->{key};
    push @traits, 'Lightable'             if $flags->{lightable};
    push @traits, 'Weapon'                if $flags->{weapon};
    push @traits, 'Container'             if $flags->{container};

    push @traits, 'Gateway'               if $data->{linked};

    return map { "AberMUD::Object::Role::$_" } @traits;
}

sub calculate_rolebased_params {
    my $obj_data = shift;

    my %data = (
        openable => {
            open_description   => 0,
            closed_description => 1,
        },
        lockable => {
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

    foreach my $flag (keys %data) {
        if ($obj_data->{flags}{$flag}) {
            foreach my $attr (keys %{ $data{$flag} }) {
                my $legacy_attr = 'desc[' . $data{$flag}{$attr} . ']';
                $obj_data->{$legacy_attr} and
                    $params{$attr} = $obj_data->{$legacy_attr}
            }
        }
    }

    return %params;
}

sub expand_locations {
    my $expanded      = shift;
    my $locs      = shift;
    my $zone_name = shift;

    my %loc_objects;
    foreach my $loc_data (values %$locs) {

        my $l = AberMUD::Location->new(
            title       => $loc_data->{title},
            description => $loc_data->{description},
            flags       => format_flags($loc_data->{flags}),
        );

        my $key = sprintf q[%s@%s], $loc_data->{id}, $zone_name;

        $expanded->{loc}{$key} = $l;

    }
}

sub link_zone_data {
    my ($expanded, $info) = @_;

    # locations
    link_to_zones($expanded, $info);
    link_location_exits($expanded, $info);  # L->dir = L
#    link_object_locations($expande, $info); # O->location = L
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

sub link_mobiles_to_zones {
    my ($expanded, $info) = @_;

    while (my ($loc_id, $loc_data) = each %{ $expanded->{mob} }) {
        (my $zone_name = $loc_id) =~ s{.+@}{};
        $loc_data->zone($expanded->{zone}{$zone_name});
    }
}

sub link_objects_to_zones {
    my ($expanded, $info) = @_;

    while (my ($loc_id, $loc_data) = each %{ $expanded->{loc} }) {
        (my $zone_name = $loc_id) =~ s{.+@}{};
        $loc_data->zone($expanded->{zone}{$zone_name});
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


            if ($linked_loc_id =~ /^\^/) {
                (my $door_id = lc($linked_loc_id)) =~ s/^\^//;

                my $linked_door_id
                    = lc($info->{obj}{$door_id}{linked}||'') or die "no linked for $door_id";

                $linked_door_id =~ /@/
                    or $linked_door_id .= '@' . $loc_data->zone->name;


                my $link_attr = "${direction}_link";

                warn "no object for $door_id", next
                    unless $expanded->{obj}{$door_id};

                do { warn "no object for $linked_door_id"; next }
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

sub store_zone_data {
    unlink 'abermud';
}
