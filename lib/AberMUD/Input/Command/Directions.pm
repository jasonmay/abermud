package AberMUD::Input::Command::Directions;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

foreach my $direction (directions()) {
    command $direction, priority => -10, sub {
        my ($universe, $you) = @_;

        if ($you->fighting) {
            return "You're in the middle of a fight! You'll have to flee.";
        }

        my $destination = $universe->move($you, $direction, announce => 1);

        return $destination ? $universe->look($you->location) : "You can't go that way.";
    };
};

__PACKAGE__->meta->make_immutable;

1;
