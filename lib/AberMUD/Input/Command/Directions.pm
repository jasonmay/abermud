package AberMUD::Input::Command::Directions;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

foreach my $direction (directions()) {
    command $direction, priority => -10, sub {
        my $you   = shift;

        if ($you->fighting) {
            return "You're in the middle of a fight! You'll have to flee.";
        }

        my $go_direction = "go_$direction";
        my $destination = $you->$go_direction();

        return $destination ? $you->look : "You can't go that way.";
    };
};

__PACKAGE__->meta->make_immutable;

1;
