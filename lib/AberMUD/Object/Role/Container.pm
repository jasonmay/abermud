#!/usr/bin/env perl
package AberMUD::Object::Role::Container;
use Moose::Role;
use namespace::autoclean;
use KiokuDB::Util 'set';

sub container { 1 }

has contents => (
    is      => 'ro',
    handles => {containing => 'members'},
    default => sub { set() },
);

sub put_in {
    my $self = shift;
    my ($object) = @_;

    $self->contents->insert($object);
    $object->contained_by($self);
}

sub take_from {
    my $self = shift;
    my ($object) = @_;

    $self->contents->remove($object);
    $object->_clear_contained_by;
}

sub display_contents {
    my $self = shift;
    my $tabs = shift || 0;

    my $output = '';
    my $first_object = 1;
    my @contained_containers;
    my @contained = $self->containing;

    #warn map { $_->name } @contained;
    foreach (@contained) {
        next unless $_->containable;
        next unless $_->contained_by == $self;

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
        elsif ($self->containing) {
            $output .= sprintf(
                "\n%sThe %s contains:\n%s",
                '    ' x $tabs, $_->name, $_->display_contents($tabs + 1),
            );
        }
    }

    return $output;
}


1;

