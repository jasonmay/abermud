#!/usr/bin/env perl
use strict;
use warnings;
use Regexp::Grammars;
use JSON;
use File::Slurp;
use File::Basename;
use autodie;

use KiokuDB;

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
foreach my $file (@zone_files) {
    my $contents = read_file($file);
    print STDERR "$file...";
    $contents =~ s{/\* .*? \*/}{}gmsx;
    if ($contents =~ $parser) {
        warn " parsed!";
        my %results = %/;

        (my $zone_name = $file) =~ s{zones/(.+?)\.zone}{$1}s or die "invalid zone";

        my $info = construct_info_from_parsed(\%results);

        my $json = JSON->new->pretty;

        #write_pretty_json('results.out' => \%results);
        #write_pretty_json("json/$zone_name.json" => $info);
        my %expanded = %{ expand_zone_data($info, $zone_name) };
        use Carp::REPL; die;
    }
}

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
    my $results = shift;

    my @locs = map {
        $_->{LocFlags}{lflags} = +{ FlagItem => [] }
        if $_->{LocFlags}{lflags}
            and not ref $_->{LocFlags}{lflags};

        +{
            id          => $_->{Map}{LocID},
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

    my @mobs = map {
        +{ create_map_from_statements( @{ $_->{Statement} } ) },
    } @{ $results->{Zone}{Mobiles}{Mobile} };

    my @objs = map {
        +{ create_map_from_statements( @{ $_->{ObjectStatement} } ) },
    } @{ $results->{Zone}{Objects}{Object} };

    return +{mob => \@mobs, obj => \@objs, loc => \@locs};
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

sub expand_zone_data {
    my $info      = shift;
    my $zone_name = shift;

    return +{
        mob => expand_mobiles($info->{mob}, $zone_name),
        obj => expand_objects($info->{obj}, $zone_name),
        loc => expand_objects($info->{loc}, $zone_name),
    };
}

sub expand_mobiles {
    my $mobs = shift;
    my $zone_name = shift;

    my %mob_objects;
    foreach my $mob_data (@$mobs) {
        warn $mob_data->{name};
        my $mob_object = AberMUD::Mobile->new;

        $mob_object->$_($mob_data->{$_}) for grep { $mob_data->{$_} } qw[
           name
           damage
           armor
           aggression
           speed
           description
        ];

        $mob_object->examine_description($mob_data->{examine}) if $mob_data->{examine};
        $mob_object->display_name($mob_data->{pname} || ucfirst $mob_data->{name});
        $mob_object->basestrength($mob_data->{strength}) if $mob_data->{strength};
        $mob_object->intrinsics( format_flags(@{$mob_data}{'pflags', 'eflags'}) );
        $mob_object->spells( format_flags($mob_data->{sflags}) );

        $mob_objects{sprintf q[%s@%s], $mob_data->{name}, $zone_name} = $mob_object;
    }

    return \%mob_objects;
}

sub format_flags {
    my %result;

    foreach my $flags (@_) {
        next unless ref $flags eq 'ARRAY';
        $result{$_} = 1 for @$flags;
    }

    return \%result;
}

sub expand_objects {
    my $objs = shift;
    return +{};
}

sub expand_locations {
    my $locs = shift;
    return +{};
}

sub store_zone_data {
    unlink 'abermud';
}
