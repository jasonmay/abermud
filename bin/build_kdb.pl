#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Util;
use AberMUD::Location;
use AberMUD::Location::Util qw(directions);
use File::Basename;
use Carp;
use String::Util ':all';
use KiokuDB;
use KiokuDB::Backend::DBI;
use AberMUD::Directory;
use AberMUD::Zone;
use AberMUD::Config;
use AberMUD::Universe::Sets;
use AberMUD::Mobile;
use Data::Dumper;
#use namespace::autoclean;


my %mobiles;
my %objects;

my @locations = (AberMUD::Location->new);
my %locations;
my %dir_locations;
my %loc_map;
my %loc_world_map;
my $total_locs = 0;

sub get_simple {
    my $input = shift || $_;

    my ($return) = /^.+?\s*=\s*(.+)/;
    return $return;
}

sub get_flags {
    my $input = shift || $_;

    return [] if $input !~ /\s/;
    my ($set_string) = $input =~ /^.+?\s+(?:=\s*)?(.+)/;
    $set_string =~ s/\{(.*)\}/$1/;
    return [split ' ', $set_string];
}

sub get_ml {
    my $fh    = shift;
    my $input = shift || $_;

    my $return;
    my $quotes = () = $input =~ /"/g;

    if ($quotes >= 2) {
        # there are no escaped quotes :)
        ($return) = $input =~ /"(.+)"/;
        return $return;
    }

    ($return) = $input =~ /"(.+)/s;
    do {
        $_ = <$fh>;
        ($return) .= $_;
    } until /"/;
    chop $return while $return && $return =~ /"$/s;
    chomp $return; #once more to rid the "

    return $return;
}

sub parse_objects {
    my $file = shift;
    my $zone_file = lc(basename $file);
    my $zone = $zone_file;
    local $_;
    $zone =~ s/\.zone$//;
    my $zone_obj = AberMUD::Zone->new(name => $zone);
    return unless -f $file;
    open my $fh, '<', $file;
    my $title;
    my $prev_line;
    my $n = 0;
    my %current_data;
    #$_ = <$fh>;
    do {$_ = <$fh>;warn $_ if $zone =~ /awiz/} until (!$_ || /^%objects/si);

    if ($_) {
        while (<$fh>) {
            #    next if /^%objects/i;
            if (/^%zone:(\S+)/i) {
                $zone = $1;
                $zone_obj = AberMUD::Zone->new(name => $zone);
                $_ = <$fh> while $_ && !/^%objects/;
                $_ = <$fh>; # skip
                $n = 1;
            }
            next if /^\s*$/;
            last if /^%(?:locations|mobiles)/i;
            next if /^%(?!objects)/i;
            $n++;
            #warn $_;
#        my @simple_keys = qw(
#        name pname location
#        strength damage armor
#        aggression speed end
#        );
            my %flag      = map {; $_ => 1 } qw(oflags);
            my %multiline = map {; $_ => 1 } qw(description examine);

            my ($datum) = map { lc } /^\s*(.+?)\b/;
            my $value;
            if ($flag{$datum}) {
                $value = get_flags;
                my @a = @$value;
                $value = +{ map {; $_ => 1 } @a };
            }
            elsif ($multiline{$datum}) {
                $value = get_ml($fh);
            }
            else {
                $value = get_simple;
            }
            if ($datum eq 'end') {
                $current_data{zone} = $zone;
                $objects{"$current_data{name}\@$zone"} = +{%current_data};
                %current_data = ();
            }

            $value =~ s/"(.+)"/$1/ if $datum eq 'pname';
            $current_data{$datum} = $value unless $datum eq 'end';
        }
    }
    close $fh;
    print "parsed $file\n";
}

sub parse_mobiles {
    my $file = shift;
    my $zone_file = lc(basename $file);
    my $zone = $zone_file;
    local $_;
    $zone =~ s/\.zone$//;
    my $zone_obj = AberMUD::Zone->new(name => $zone);
    return unless -f $file;
    open my $fh, '<', $file;
    my $title;
    my $prev_line;
    my $n = 0;
    $_ = <$fh> until $_ && /^%mobiles/i || !$_;
    my %current_data;
    while (<$fh>) {
        next if /^%mobiles/i;
        if (/^%zone:(\S+)/i) {
            $zone = $1;
            $zone_obj = AberMUD::Zone->new(name => $zone);
            $_ = <$fh> while $_ && !/^%mobiles/;
            $_ = <$fh>; # skip
            $n = 1;
        }
        next if /^\s*$/;
        last if /^%(?:locations|objects)/i;
        next if /^%(?!mobiles)/i;
        $n++;
        #warn $_;
#        my @simple_keys = qw(
#        name pname location
#        strength damage armor
#        aggression speed end
#        );
        my %flag      = map {; $_ => 1 } qw(sflags pflags mflags eflags);
        my %multiline = map {; $_ => 1 } qw(description examine);

        my ($datum) = map { lc } /^\s*(.+?)\b/;
        my $value;
        if ($flag{$datum}) {
            $value = get_flags;
            my @a = @$value;
            $value = +{ map {; $_ => 1 } @a };
        }
        elsif ($multiline{$datum}) {
            $value = get_ml($fh);
        }
        else {
            $value = get_simple;
        }
        if ($datum eq 'end') {
            $current_data{zone} = $zone;
            $mobiles{"$current_data{name}\@$zone"} = +{%current_data};
            %current_data = ();
        }

        $value =~ s/"(.+)"/$1/ if $datum eq 'pname';
        $current_data{$datum} = $value unless $datum eq 'end';
    }
    close $fh;
    print "parsed $file\n";
}

sub parse_locations {
    my $file = shift;
    my $zone_file = lc(basename $file);
    my $zone = $zone_file;
    local $_;
    $zone =~ s/\.zone$//;
    my $zone_obj = AberMUD::Zone->new(name => $zone);
    return unless -f $file;
    open my $fh, '<', $file;
    my $title;
    my $prev_line;
    my $n = 0;
    $_ = <$fh> until $_ && /^%locations/i;

    while (<$fh>) {
        next if /^%locations/i;
        if (/^%zone:(\S+)/) {
            $zone = $1;
            $zone_obj = AberMUD::Zone->new(name => $zone);
            $_ = <$fh> while $_ && !/^%locations/i;
            $_ = <$fh>; # skip
            $n = 1;
        }
        next if /^\s*$/;
        last if /^%(?!locations)/i;
        $n++;
        my ($id, $exit_info) = /(\S+)\s*(.*);/;
        $id = trim $id;
        my $loc = AberMUD::Location->new(zone => $zone_obj);
        croak "$file -> $_" unless $id;
        $loc->id($id);
        $locations{"$id\@$zone"}  = $loc;
        $dir_locations{"$zone$n"} = $loc;
        $loc->world_id("$zone$n");

        my @exit_nodes = split ' ', $exit_info;

        foreach my $exit_node (@exit_nodes) {
            # TODO check for doors
            my ($dir_letter, $exit_loc) = $exit_node =~/\^?(.+):(.+)/;
            $exit_loc .= "\@$zone" if $exit_loc !~ /@/;
            $exit_loc =~ s/\@(.+)/'@' . lc $1/e;
            $loc_map{"$id\@$zone"}->{$dir_letter} = $exit_loc;
            $loc_world_map{"$zone$n"}->{$dir_letter} = $exit_loc;
        }

        $_ = <$fh> while $_ && lc($_) !~ /^lflags/;
        last unless $_;

        my ($flags) = /\{(.+)\}/;

        #do something with lflags later
        $loc->flags(+{map { $_ => 1 } split(' ', lc $flags)}) if $flags;

        $_ = <$fh>;
        die $_ unless /\^/;
        my ($title) = /(.+)\^/;
        $loc->title($title) if $title;

        $_ = <$fh>; last unless $_;

        while ($_ && $_ !~ /^\^/) {
            $loc->description(($loc->description||'') . $_);
            $_ = <$fh>;
        }
    }
    close $fh;
    print "parsed $file for locations\n";
}

my $zones_dir = 'zones';
opendir(my $dh, $zones_dir);
foreach my $zone_file (readdir($dh)) {
    next unless lc($zone_file) =~ /\.zone$/;
    parse_locations "$zones_dir/$zone_file";
    parse_mobiles "$zones_dir/$zone_file";
    parse_objects "$zones_dir/$zone_file";
}
closedir $dh;

unlink qw(abermud abermud-journal);
my $ad = AberMUD::Directory->new;
my $kdb = KiokuDB->connect('dbi:SQLite:dbname=abermud', create => 1);
my $scope = $kdb->new_scope;
my %dir = map { substr($_, 0, 1) => $_ } directions();

my %mobmap;
while (my ($mob_at_zone, $data) = each %mobiles) {
    my ($name, $zone) = split /@/, $mob_at_zone;
    my $mobile = AberMUD::Mobile->new;
    $data->{$_} ||= 0 for qw(damage armor speed aggression);
    $data->{$_} ||= '' for qw(description examine);
    $mobile->$_($data->{$_})
    for qw(
           name
           damage
           armor
           aggression
           speed
           description
    );

    $mobile->examine_description($data->{examine});
    $mobile->display_name($data->{pname} || ucfirst $data->{name});
    $mobile->basestrength($data->{strength});
    $mobile->intrinsics(
        +{
            %{ $data->{pflags} || {} },
            %{ $data->{eflags} || {} },
        }
    );

    $mobile->spells($data->{sflags}||{});

    $mobmap{$mob_at_zone} = $mobile;
}

$kdb->store(values %mobmap);

while (my ($dir_key, $dir_value) = each %dir_locations) {
    $kdb->store("location-$dir_key" => $dir_value);
}

while (my ($loc_id, $loc) = each %locations) {
    next unless exists $loc_map{$loc_id};
    while (my ($dir_letter, $exit) = each %dir) {
        next unless exists $loc_map{$loc_id}->{$dir_letter};
        next unless exists $locations{$loc_map{$loc_id}->{$dir_letter}};

        my $loc_dir = $locations{$loc_map{$loc_id}{$dir_letter}};
        $loc->$exit($loc_dir);
    }
}

$kdb->update($_) foreach values %dir_locations;

my @mob_keys = keys %mobmap;
my $usets = AberMUD::Universe::Sets->new;
$kdb->store('universe-sets' => $usets);

my @mob_ids = $kdb->store(@mobmap{@mob_keys});
my %mobile_objects;
@mobile_objects{@mob_ids} = @mobmap{@mob_keys};
$usets->all_mobiles(\%mobile_objects);
$kdb->update($usets);

for (keys %mobiles) {
    my $mob_loc_id = "$mobiles{$_}{location}\@$mobiles{$_}{zone}";
    #warn keys(%locations);
    next unless $locations{$mob_loc_id};
    $mobmap{$_}->location($locations{$mob_loc_id});
}
$kdb->update(values %mobmap);

my $config = AberMUD::Config->new(
    location => $locations{'church@start'},
    input_states => [qw(Login::Name Game)],
);

$kdb->store(config => $config);
