package AberMUD::Special::Plugin::Quest::Excalibur;
use Moose::Role;
use List::MoreUtils qw(any);

around command_blow => sub {
    my ($orig, $self) = (shift, shift);

    my $orig_result = $self->$orig(@_);
    return $orig_result if $orig_result;

    my $you  = shift;
    my $args = shift;

    my $obj = $you->universe->identify_object($you->location, $args);

    return 0 unless $obj;
    return 0 unless $obj->moniker and $obj->moniker eq 'horn@labyrinth';

    return 0 unless any {
        $you->location->moniker
            and $you->location->moniker eq "$_\@sea"
    } ( 1 .. 10);

    my $excal = $you->universe->get_object_by_moniker('excalibur@sea');
    $excal->location($you->location);
    $you->complete_quest('excalibur');

    return(1, "A hand breaks through the water holding up the sword Excalibur!");
};

no Moose::Role;

1;
