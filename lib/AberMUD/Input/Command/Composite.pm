#!/usr/bin/env perl
package AberMUD::Input::Command::Composite;
use Moose;
use namespace::clean -except => [qw/meta commands command/];

use Module::Pluggable
search_path => ['AberMUD::Input::Command'],
except      => [__PACKAGE__],
sub_name    => 'commands',
require     => 1;

foreach my $command_class (__PACKAGE__->commands) {
    Class::MOP::load_class($command_class);
    next unless $command_class->meta;

    $command_class->meta->isa('AberMUD::Meta::Command::Composite')
        and next;

    my $method_metaclass = $command_class->meta->method_metaclass;

    foreach my $method ($command_class->meta->get_all_methods) {

        next unless $method->meta->can('does_role');
        next unless $method->meta->does_role('AberMUD::Role::Command');

        __PACKAGE__->meta->add_method(
            $method->name => $method,
        );
    }
};

__PACKAGE__->meta->make_immutable;

1;

