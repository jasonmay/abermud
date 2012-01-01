package AberMUD::Input::Command::Directions;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

use AberMUD::Event::Command;

foreach my $direction (directions()) {
    command $direction, priority => -10, sub {
        my ($self, $e) = @_;

        if ($e->player->fighting) {
            return "You're in the middle of a fight! You'll have to flee.";
        }

        my $destination = $e->universe->move($e->player, $direction, announce => 1);

        my $look_event = AberMUD::Event::Command->new(
            universe  => $e->universe,
            player    => $e->player,
            arguments => '',
        );
        return $destination ? $self->trigger_command('look', $look_event) : "You can't go that way.";
    };
};

__PACKAGE__->meta->make_immutable;

1;
