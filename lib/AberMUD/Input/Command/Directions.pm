package AberMUD::Input::Command::Directions;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

foreach my $direction (directions()) {
    command $direction, priority => -10, sub {
        my $you   = shift;
        return "You are somehow nowhere." unless defined $you->location;

            my $go_direction = "go_$direction";
        return $you->$go_direction();
    };
};

__PACKAGE__->meta->make_immutable;

1;
