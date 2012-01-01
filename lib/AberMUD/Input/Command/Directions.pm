package AberMUD::Input::Command::Directions;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

foreach my $direction (directions()) {
    command $direction, priority => -10, sub {
        my ($self, $e) = @_;

        if ($e->player->fighting) {
            return "You're in the middle of a fight! You'll have to flee.";
        }

        my $destination = $e->universe->move($e->player, $direction, announce => 1);

        return $destination ? $e->universe->look($e->player->location, except => $e->player) : "You can't go that way.";
    };
};

__PACKAGE__->meta->make_immutable;

1;
