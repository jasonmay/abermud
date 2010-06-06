#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Util;
use AberMUD::Location;
use AberMUD::Location::Util qw(directions direction_letters);
use File::Basename;
use File::Path qw(rmtree mkpath);
use Carp;
use String::Util ':all';
use KiokuDB;
use KiokuDB::Backend::DBI;
use AberMUD::Directory;
use AberMUD::Zone;
use AberMUD::Config;
use AberMUD::Universe::Sets;
use AberMUD::Mobile;
use AberMUD::Object;
use Data::Dumper;
#use namespace::autoclean;


my %mobiles;
my %objects;

my $parsing_objects = 0;

my @locations = (AberMUD::Location->new);
my %locations;
my %dir_locations;
my %loc_map;
my %loc_world_map;
my $total_locs = 0;

my %door_links;

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
    return [split ' ', lc $set_string];
}

sub get_ml {
    my $fh    = shift;
    my $input = shift || $_;

    my $delim;
    if (index($input, '"') >= 0 and index($input, '^') >= 0) {
        $delim = (index($input, '"') < index($input, '^')) ? '"' : '^';
    }
    elsif (index($input, '"') >= 0) {
        $delim = '"';
    }
    elsif (index($input, '^') >= 0) {
        $delim = '^';
    }
    else {
        die "Appropriate delimiter could not be found (input: $input)";
    }

    #warn $input if $parsing_objects;
    $delim = quotemeta $delim;

    my $return;
    my $quotes = () = $input =~ /$delim/g;

    if ($quotes >= 2) {
        # there are no escaped quotes :)
        ($return) = $input =~ /$delim(.*)$delim/;
        return $return;
    }

    ($return) = $input =~ /$delim(.*)/s;
    do {
        $_ = <$fh>;
        #warn $_ if $parsing_objects;
        ($return) .= $_;
    } until /$delim/;
    chop $return while $return && $return =~ /$delim$/s;
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
    do { $_ = <$fh> } until (!$_ || /^%objects/si);
    $parsing_objects = 1;

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
            my %multiline = map {; $_ => 1 } qw(desc[0] desc[1] desc[2] desc[3] examine);

            my ($datum) = map { lc } /^\s*(\S+)/ or do {
                chomp;
                die "($file) DATUM MISSING FROM STRING: $_";
                next;
            };
            #warn $datum if $parsing_objects;
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
                my $obj_name = "$current_data{name}\@$zone";
                $objects{$obj_name} = +{%current_data};
                %current_data = ();
            }

            $value =~ s/"(.+)"/$1/ if $datum eq 'pname';
            $current_data{$datum} = $value unless $datum eq 'end';
        }
    }
    close $fh;
    $parsing_objects = 0;
    #print "parsed $file\n";
}

sub calculate_object_traits {
    my $f = shift;

    #warn keys(%$f);
    my @traits;
    push @traits, 'Gateway'               if $f->{linked};
    push @traits, 'Openable', 'Closeable' if $f->{openable};
    push @traits, 'Pushable'              if $f->{pushable};
    push @traits, 'Food'                  if $f->{food};
    push @traits, 'Wearable'              if $f->{wearable} or $f->{armor};
    push @traits, 'Key'                   if $f->{key};
    push @traits, 'Lightable'             if $f->{lightable};
    push @traits, 'Weapon'                if $f->{weapon};
    push @traits, 'Container'             if $f->{container};

    return map { "AberMUD::Object::Role::$_" } @traits;
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
        next unless $_;
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
    #print "parsed $file\n";
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
        die "$file -> $_" unless $id;
        $loc->id($id);
        $locations{"$id\@$zone"}  = $loc;
        $dir_locations{"$zone$n"} = $loc;
        $loc->world_id("$zone$n");

        my @exit_nodes = split ' ', $exit_info;

        foreach my $exit_node (@exit_nodes) {
            # TODO check for doors
            my ($dir_letter, $exit_loc) = $exit_node =~ /(.+):(.+)/;
            $exit_loc .= "\@$zone" if $exit_loc !~ /@/;

            if ($exit_loc =~ s/^\^(.+)/obj:$1/) {
                #warn $exit_loc;
                my $obj = $1;
                $door_links{$obj} = $dir_letter;
            }
            else {
                $exit_loc =~ s/\@(.+)/'@' . lc $1/e;
                $loc_map{"$id\@$zone"}->{$dir_letter} = $exit_loc;
                $loc_world_map{"$zone$n"}->{$dir_letter} = $exit_loc;
            }
        }

        $_ = <$fh> while $_ && lc($_) !~ /^lflag/;
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
    #print "parsed $file for locations\n";
}

my $zones_dir = 'zones';
opendir(my $dh, $zones_dir);
foreach my $zone_file (sort readdir($dh)) {
    next unless lc($zone_file) =~ /pirate\.zone$/;
    #next unless lc($zone_file) =~ /\.zone$/;
    parse_locations "$zones_dir/$zone_file";
    parse_mobiles "$zones_dir/$zone_file";
    parse_objects "$zones_dir/$zone_file";
}
closedir $dh;

unlink 'abermud';
my $kdb = KiokuDB->connect(AberMUD::Util::dsn, create => 1);
my $scope = $kdb->new_scope;
my %dir = map { substr($_, 0, 1) => $_ } directions();

my %mobmap;
my $m = 0;
while (my ($mob_at_zone, $data) = each %mobiles) {
    $m++;
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

    warn "$m mobiles loaded..." if $m % 100 == 0;
    $mobmap{$mob_at_zone} = $mobile;
}

$kdb->store(values %mobmap);

while (my ($dir_key, $dir_value) = each %dir_locations) {
    eval { $kdb->store("location-$dir_key" => $dir_value); } or warn $@
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
    next unless $locations{$mob_loc_id};
    $mobmap{$_}->location($locations{$mob_loc_id});
}
$kdb->update(values %mobmap);

my %objmap;
while (my ($obj_at_zone, $data) = each %objects) {
    my ($name, $zone) = split /@/, $obj_at_zone;
    my $oflags = $data->{oflags};
    $oflags->{$_} = lc $oflags->{$_} for keys %$oflags;
    my @traits = calculate_object_traits($oflags);

    my %traits = map {; $_ => 1 } calculate_object_traits;
    $traits{'AberMUD::Object::Role::Gateway'} = 1 if $data->{linked};

    #warn "@{[keys %traits]} <-- $data->{name}" if $data->{linked};
    my %constructor_params;

    $constructor_params{ungetable} = 1 if $oflags->{noget};
    my $object = %traits
               ? AberMUD::Object->new_with_traits(traits => [keys %traits], %constructor_params)
               : AberMUD::Object->new(%constructor_params);

    $data->{$_} ||= 0  for qw(damage armor);
    $data->{$_} ||= '' for qw(description examine);

    $data->{linked} .= "\@$zone" if $data->{linked} && $data->{linked} !~ /@/;

    $object->name($data->{name});
    $object->examine_description($data->{examine}) if $data->{examine};
    #$object->display_name($data->{pname} || ucfirst $data->{name});
    $object->alt_name($data->{altname}) if $data->{altname};

    if ($data->{location} =~ /IN_ROOM:(.+)/) {
        my $location = $1;
        $location .= "\@$zone" unless $location =~ /@/;
        #warn "GOGOGOO " . $location if $object->name eq 'mess_door';
        if ($locations{$location}) {
            #    warn 'sdklj';
            $object->location($locations{$location});
        }
    }

    $object->flags->{$_} = $oflags->{$_} for keys %$oflags;

    # TODO door logic

    #warn join ' ', map { $_->name } $object->meta->calculate_all_roles
    #    if $obj_at_zone eq 'ladder2Cove@pirate';
    $objmap{$obj_at_zone} = $object;
}
my @objects = values %objmap;
my @obj_ids = $kdb->store(@objects);

my %kdbid_to_obj;
@kdbid_to_obj{@obj_ids} = @objects;
# update other entries(?) linking to objects
$usets->all_objects( +{%kdbid_to_obj} );
$kdb->update($usets);

my $gateway_role = 'AberMUD::Object::Role::Gateway';
my %lettermap;
@lettermap{direction_letters()} = directions();

#require YAML; die YAML::Dump(\%objmap);
foreach my $object (keys %door_links) {
    if (!$objmap{$object} or !$objmap{$object}->does($gateway_role)) {
        warn "$object not found";
        next;
    }

    if (!$objects{$object} || !$objmap{$objects{$object}{linked}}) {
        warn "$objects{$object}{linked} ...also not found";
        next;
    }

    my $link_attr = $lettermap{ $door_links{$object} } . '_link';
    warn "$link_attr => $object";
    $objmap{$object}->$link_attr($objmap{$objects{$object}{linked}});
}

$kdb->update(values %objmap);

print( "\n" x 20 );

my $config = AberMUD::Config->new(
    location => $locations{'church@start'} || $locations{(keys %locations)[0]},
    input_states => [qw(Login::Name Game)],
);

$kdb->store(config => $config);
