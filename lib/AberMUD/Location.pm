#!/usr/bin/env perl
package AberMUD::Location;
use KiokuDB::Class;
use namespace::autoclean;

use MooseX::ClassAttribute;

has id => (
    is  => 'rw',
    isa => 'Str',
);

has world_id => (
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

use constant _directions => qw(north south east west up down);

class_has directions => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [ _directions ] },
);

for (_directions) {
    has $_ => (
        is        => 'rw',
        isa       => 'AberMUD::Location',
        weak_ref  => 1,
        traits    => [ qw(KiokuDB::Lazy) ],
        predicate => "has_$_",
    );
}

sub show_exits {
    my $self = shift;
    my $output;
    $output = "&+CObvious exits are:&*\n";
    for (@{$self->directions}) {
        next unless $self->$_;
        $output .= sprintf("%-5s &+Y: &+G%s&*\n", ucfirst($_), $self->$_->title);
    }
    return $output;
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
