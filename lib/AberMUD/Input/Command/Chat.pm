#!/usr/bin/env perl
package AberMUD::Input::Command::Chat;
use AberMUD::OO::Commands;

command 'chat', alias  => '0', sub {
    my ($self, $e) = @_;

    my $message = sprintf("&+M[Chat] %s:&* %s", $e->player->name, $e->arguments);
    $e->universe->broadcast($message, except => $e->player);

    return $message;
};

__PACKAGE__->meta->make_immutable;

1;
