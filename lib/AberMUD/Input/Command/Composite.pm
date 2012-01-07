#!/usr/bin/env perl
package AberMUD::Input::Command::Composite;
use Moose;
use namespace::clean -except => [qw/meta commands command/];

use Module::Pluggable
search_path => ['AberMUD::Input::Command'],
except      => [__PACKAGE__],
sub_name    => 'commands',
require     => 1;

has special => (
    is       => 'ro',
    isa      => 'AberMUD::Special',
    required => 1,
);

sub get_command_methods {
    my @methods;
    foreach my $command_class (__PACKAGE__->commands) {
        Class::MOP::load_class($command_class);

        $command_class->meta->isa('AberMUD::Meta::Command::Composite')
            and next;

        my $method_metaclass = $command_class->meta->method_metaclass;

        foreach my $method ($command_class->meta->get_all_methods) {

            next unless $method->meta->can('does_role');
            next unless $method->meta->does_role('AberMUD::Role::Command');

            push @methods, $method;
        }
    }

    return @methods;
}

sub trigger_command {
    my ($self, $command, $e) = @_;
    my $meth = $self->meta->find_method_by_name($command);
    return unless $meth->meta->can('does_role');
    return unless $meth->meta->does_role('AberMUD::Role::Command');

    my $response = $meth->body->($self, $e);

    return $response;
}

sub get_command_names {
    my $class = shift;
    map { $_->name } $class->get_command_methods;
}

foreach my $method (__PACKAGE__->get_command_methods) {
    __PACKAGE__->meta->add_method($method->name => $method)
}

__PACKAGE__->meta->make_immutable;

1;

