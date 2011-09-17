#!/usr/bin/env perl
package AberMUD::Input::Command::Chat;
use AberMUD::OO::Commands;

command 'chat', alias  => '0', sub {
    my ($universe, $you, $args) = @_;

    my $message = sprintf("&+M[Chat] %s:&* %s", $you->name, $args);
    $universe->broadcast($message, except => $you);

    return $message;
};

__PACKAGE__->meta->make_immutable;

1;
