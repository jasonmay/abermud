#!/usr/bin/env perl
package AberMUD::Test::Sugar;
use strict;
use warnings;
use AberMUD::Object;
use AberMUD::Location;
use AberMUD::Player;
use AberMUD::Container;
use AberMUD::Config;
use AberMUD::Storage;
use AberMUD::Universe::Sets;

sub build_game {
    my %data = @_;

    my $locs = $data{locations};
    my $default_loc = $data{default_location};
    my $dsn = $data{dsn};
    my $zone_name = $data{zone};

    my (@all_objects, @all_mobiles, %all_locations);
    foreach my $loc (keys %$locs) {
        my %loc_params = (
            title       => $locs->{$loc}{title},
            description => $locs->{$loc}{description},
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

        push @all_objects, @objects;
        push @all_mobiles, @mobiles;

        my $loc_node = AberMUD::Location->new(%loc_params);

        do { $_->location($loc_node) } for ((grep { $_->on_the_ground } @objects), @mobiles);
        $all_locations{$loc} = $loc_node;
    }

    foreach my $loc (keys %$locs) {
        next unless $locs->{$loc}{exits};

        foreach my $exit (keys %{ $locs->{$loc}{exits} }) {
            $all_locations{$loc}->$exit($all_locations{$locs->{$loc}{exits}{$exit}});
        }
    }

    #my $k = KiokuDB->connect('hash', create => 1);
    my $storage = AberMUD::Storage->new(dsn => $dsn);

    my $players = $data{players};

    my @all_players;
#    while ( my ($player_key, $player_data) = each %$players) {
#        my $player = AberMUD::Player->new(
#            name     => ucfirst $player_key,
#            password => crypt($player_data->{password}, lc($player_key)),
#            location => $all_locations{ $player_data->{location} },
#            storage  => $storage,
#        );
#        push @all_players, $player;
#    }

    my $config = AberMUD::Config->new(
        input_states => [qw(Login::Name Game)],
    );

    my $usets = AberMUD::Universe::Sets->new(
        all_objects => \@all_objects,
        all_mobiles => \@all_mobiles,
    );

    $storage->scoped_txn(
        sub {
            $storage->store('universe-sets' => $usets);
            $storage->store(config => $config);
            $storage->store(values %all_locations);

            # the only stuff with its self-managed ID
            #$k->store(map { 'player-' . $_->name => $_ } @all_players);
        }
    );

    my $c = AberMUD::Container->with_traits('AberMUD::Container::Role::Test')->new(
        test_storage => $storage,
    );

    $c->fetch('controller')->get->_load_objects();
    $c->fetch('controller')->get->_load_mobiles();
    #use Carp::REPL; die;

    return $c;
}

sub _handle_object {
    my ($obj_name, $obj_data) = @_;
    my @objects;
    my $description = $obj_data->{$obj_name}{description}
                    || "Here lies a normal $obj_name";

    my $examine = $obj_data->{$obj_name}{examine}
                || "It looks just like a normal $obj_name!";

    my @contained = _handle_container($obj_data);

    $obj_data->{covers} = +{ map {; $_ => 1 } @{ $obj_data->{covers} } };
    my %params = (
        name                => $obj_name,
        description         => $description,
        examine_description => $examine,
        open_description    => $obj_data->{open_description},
        closed_description  => $obj_data->{closed_description},
        locked_description  => $obj_data->{locked_description},
        buy_value           => $obj_data->{bvalue},
        flags               => $obj_data->{oflags},
        coverage            => $obj_data->{covers},
    );

    # delete all undef values (for default fallback)
    delete $params{$_} for grep {not defined $params{$_}} keys %params;

    my $obj_class;
    if ($obj_data->{traits}) {
        # TODO _trait_namespace in mx-traits can solve this
        my @traits = map { "AberMUD::Object::Role::$_" }
                        @{$obj_data->{traits}};
        $obj_class = AberMUD::Object->with_traits(@traits);
    }
    else {
        $obj_class = 'AberMUD::Object';
    }

    my $obj = $obj_class->new(%params);

    $_->contained_by($_->contained_by || $obj) for @contained;

    return(@contained, $obj);
}

sub _handle_container {
    my $data = shift;

    my @objects;
    if ($data->{contains}) {
        while (my ($inside, $inside_data) = each %{ $data->{contains} }) {
            push @objects, _handle_object($inside, $inside_data);
        }
    }

    return @objects;
}

sub _handle_mobile {
    my ($mob_name, $mob_data) = @_;
    my @mobiles;

    my $description = $mob_data->{$mob_name}{description}
                    || "Here stands a normal $mob_name";

    my $examine = $mob_data->{$mob_name}{examine}
                || "They look just like a normal $mob_name!";

    my @spells = (@{$mob_data->{sflags}||[]}, @{$mob_data->{pflags}||[]});

    my %params = (
        name                => $mob_name,
        display_name        => $mob_data->{pname},
        description         => $description,
        examine_description => $examine,
        aggression          => $mob_data->{open_description},
        damage              => $mob_data->{closed_description},
        armor               => $mob_data->{locked_description},
        speed               => $mob_data->{speed},
        spells              => { map {; $_ => 1 } @spells },
    );

    # delete all undef values (for default fallback)
    delete $params{$_} for grep {not defined $params{$_}} keys %params;

    my $mob = AberMUD::Mobile->new(%params);

    push @mobiles, $mob;

    my @carrying = _handle_carrying($mob_data);
    my @wielding = _handle_wielding($mob_data);
    my @wearing = _handle_wearing($mob_data);

    $_->held_by($mob) for @carrying, @wielding, @wearing;
    $_->worn(1)       for @wearing;
    $_->wielded(1)    for @wielding;

    return(
        objects => [@carrying, @wielding, @wearing],
        mobiles => [@mobiles],
    );
}

sub _handle_carrying {
    my $data = shift;

    my @objects;
    if ($data->{carrying}) {
        while (my ($inside, $inside_data) = each %{ $data->{carrying} }) {
            push @objects, _handle_object($inside, $inside_data);
        }
    }

    return @objects;
}

sub _handle_wearing {
    my $data = shift;

    my @objects;
    if ($data->{wearing}) {
        while (my ($inside, $inside_data) = each %{ $data->{wearing} }) {
            push @objects, _handle_object($inside, $inside_data);
        }
    }

    return @objects;
}

sub _handle_wielding {
    my $data = shift;

    my @objects;
    if ($data->{wielding}) {
        while (my ($inside, $inside_data) = each %{ $data->{wielding} }) {
            push @objects, _handle_object($inside, $inside_data);
        }
    }

    return @objects;
}

1;
