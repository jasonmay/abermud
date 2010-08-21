#!/usr/bin/env perl
package AberMUD::Object;
use KiokuDB::Class;
use Moose::Util qw(apply_all_roles);;
use Data::Dumper;
use namespace::autoclean;

with qw(
    MooseX::Traits
    AberMUD::Role::InGame
);

has alt_name => (
    is => 'rw',
    isa => 'Str',
);

has buy_value => (
    is => 'rw',
    isa => 'Int',
);

has description => (
    is => 'rw',
    isa => 'Str',
);

has flags => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
);

has examine_description => (
    is => 'rw',
    isa => 'Str',
);

# methods wrapped by roles
sub in_direct_possession { 0 }
sub on_the_ground { 1 }

sub getable     { 0 }
sub wearable    { 0 }
sub wieldable   { 0 }
sub edible      { 0 }
sub containable { 0 }
sub container   { 0 }
sub openable    { 0 }
sub closeable   { 0 }
sub gateway     { 0 }
sub pushable    { 0 }

sub o_does {
    my $self = shift;
    my $base = shift;
    $self->does("AberMUD::Object::Role::$base");
}

around name_matches => sub {
    my ($orig, $self) = (shift, shift);
    return 1 if $self->$orig(@_) or (
        $self->alt_name
        and lc($self->alt_name) eq lc($_[0])
    );

    return 0;
};

sub formatted_name {
    my $self = shift;

    my $name = $self->name;

    if ($self->edible) {
        $name = "&+G$name&*";
    }

    return $name;
}

sub name_in_inv {
    my $self = shift;
    $self->getable or return '';

    my $name = $self->formatted_name;

    $self->edible       and $name = "&+G$name&*";
    $self->wieldable and $name .= " &+M<weapon>&*";
    $self->wearable  and $name .= " &+C<armor>&*";
    $self->container and $name .= " &+y<cont>&*";

    return $name;
}

sub final_location {
    my $self = shift;

    my $o = $self;

    $o = $o->contained_by
        while $o->getable and $o->contained_by;

    return $o->held_by->location
        if $o->getable and $o->held_by;

    return $o->location;
}

sub in {
    my ($self, $location) = @_;

    return ($self->final_location && $self->final_location == $location);
};

sub display_container_contents {
    my $self      = shift;
    my $container = shift;

    return undef unless $container->container;

    return $self->_show_container_contents($container, 0);
}

sub _show_container_contents {
    my $self = shift;

    my ($object, $tabs) = @_;

    my $output = '';
    my $first_object = 1;
    my @contained_containers;
    my @contained = $self->objects_contained_by($object);

    #warn map { $_->name } @contained;
    foreach (@contained) {
        next unless $_->containable;
        next unless $_->contained_by($object);

        if ($first_object) {
            $output .= '    ' x $tabs;
        }
        else {
            $output .= ' ';
        }

        $output .= $_->name;

        push @contained_containers, $_ if $_->container;
    }

    foreach (@contained_containers) {
        if ($_->openable and !$_->opened) {
            $output .= sprintf(
                "\n%sThe %s is closed.",
                '    ' x $tabs, $_->name,
            );
        }
        elsif ($self->objects_contained_by($_)) {
            $output .= sprintf(
                "\n%sThe %s contains:\n%s",
                '    ' x $tabs, $_->name, $self->_show_container_contents($_, $tabs + 1),
            );
        }
    }

    return $output;
}


__PACKAGE__->meta->make_immutable;

1;

