#!/usr/bin/env perl
use strict;
use warnings;
# PODNAME: build_kdb.pl

use Regexp::Grammars;
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

use File::Basename;

use constant DEFAULT_START_LOC => 'church@start';

my $parser = qr{
#<logfile:debug.log>
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
        <.Word> (?: @ <.Word> )?

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
        (?i:Altitude) = <alt=Number>

    <rule: LocFlags>
        (?i:lflags?) <lflags=Flag>

    <rule: Exit>
        <ExitLetter> : (?: <exit_dest=Door> | <exit_dest=FullLocID> )

    <token: ExitLetter>
        (?i:[nsewud]|n[ew]|s[we])

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

    (my $zone_name = lc basename($file)) =~ s{(.+?)\.zone}{$1}s or die "invalid zone";
    my $zone_info;

    print STDERR "parsing... ";

    if ($contents =~ $parser) {
        my %results = %/;

        $zone_info = construct_info_from_parsed(\%info, \%results, $zone_name);

        print STDERR "caching... ";
        write_file("data/json/$zone_name.json", $json->encode($zone_info));
    }

    print STDERR "\n";
}

###########################################
###########################################
###########################################

sub get_all_zone_files {
    defined(my $dir = $ENV{ABERMUD_ZONE_DIR})
        or die "ABERMUD_ZONE_DIR env var must be set\n";

    opendir(my $dh, $dir);
    my @dirs = map { "$dir/$_" } grep { substr($_,-5) eq '.zone' and -f "$dir/$_" } readdir($dh);
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
        $result{lc $_} = 1 for @$flags;
    }

    return \%result;
}
