#!/usr/bin/env perl
package AberMUD::Location;
use Moose;
use MooseX::ClassAttribute;
use KiokuDB::Class;

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
        is => 'rw',
        isa => 'AberMUD::Location',
        weak_ref => 1,
        traits => [ qw(KiokuDB::Lazy) ],
        predicate => "has_$_",
    );
}

sub show_exits {
    my $self = shift;
    my $output;
    for (@{$self->directions}) {
        next unless $self->${\"has_$_"};
        $output .= ucfirst($_) . ': ' . $self->$_->title . "\n";
    }
    return $output;
}

sub look {
    my $self = shift;
    my $output = $self->title . "\n";

    $output .= $self->description . "\n";
    $output .= $self->show_exits;

    return $output;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
