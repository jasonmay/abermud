#!/usr/bin/env perl
package AberMUD::Location;
use KiokuDB::Class;
use namespace::autoclean;
use AberMUD::Location::Util qw(directions);
use KiokuDB::Util qw(weak_set);

has id => (
    is  => 'rw',
    isa => 'Str',
);

has title => (
    is  => 'rw',
    isa => 'Str',
);

has description => (
    is  => 'rw',
    isa => 'Str',
);

has zone => (
    is     => 'rw',
    isa    => 'AberMUD::Zone',
    traits => [ qw(KiokuDB::Lazy) ],
);

has flags => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

has active => (
    is  => 'rw',
    isa => 'Bool',
);

has universe => (
    is => 'rw',
    isa => 'AberMUD::Universe',
    weak_ref => 1,
);

has moniker => (
    is  => 'rw',
    isa => 'Str',
);

has [ directions() ] => (
    is        => 'rw',
    isa       => 'AberMUD::Location',
    weak_ref  => 1,
    traits    => [ qw(KiokuDB::Lazy) ],
);

has objects_in_room => (
    is => 'rw',
    #isa => 'Set::Object',
    #weak_ref => 1,
    lazy => 1,
    builder => '_build_objects_in_room',
);

sub _build_objects_in_room {
    my $self = shift;

    my $set = weak_set(
        grep {
            $_->location &&
            $_->location == $self
        } $self->universe->get_objects
    );

    return $set;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

AberMUD::Location - "rooms" that players see when they play

=head1 SYNOPSIS

  my $loc = AberMUD::Location->new(
      zone  => $zone,
      north => $north_loc,
      east  => $east_loc,
      ...
      title       => 'A path',
      description => 'This place is awesome. It is sunny.',
  );
