#!/usr/bin/env perl
package AberMUD::Input::Command::Say;
use AberMUD::OO::Commands;

command 'say', alias => q['], sub {
    my ($self, $e) = @_;
    my $args = $e->arguments;
    my $output = q{};

    $e->player->say(
        $e->player->name . " says &+Y'$args'&*\n",
        except => $e->player,
    );

    return "You say, &+Y'$args'";
};

__PACKAGE__->meta->make_immutable;

1;
