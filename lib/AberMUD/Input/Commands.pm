#!/usr/bin/env perl
package AberMUD::Input::Commands;
use Moose;
#use namespace::autoclean;
use Module::Pluggable
    search_path => ['AberMUD::Input::Command'],
    sub_name    => 'commands',
    require     => 1;

for (__PACKAGE__->commands) {
    (my $command = lc $_) =~ s/.+:://;

    Class::MOP::load_class($_);
    my $module = $_;
    __PACKAGE__->meta->add_method(
        $command => sub { shift; no strict 'refs'; &{"${module}::run"}(@_) },
    );
}

__PACKAGE__->meta->make_immutable;

1;

