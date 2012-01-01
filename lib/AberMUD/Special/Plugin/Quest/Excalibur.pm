package AberMUD::Special::Plugin::Quest::Excalibur;
use base 'AberMUD::Special::Plugin';
use AberMUD::Special::Hooks;
use List::MoreUtils qw(any);

sub setup {
    before_command blow => sub {
        my ($self, $e) = @_;
        my $obj = $e->universe->identify_object(
            $e->player->location,
            $e->arguments,
        );

        return 0 unless $obj;
        return 0 unless $obj->moniker and $obj->moniker eq 'horn@labyrinth';

        return 0 unless any {
            $you->location->moniker
                and $you->location->moniker eq "$_\@sea"
        } ( 1 .. 10);

        my $excal = $e->universe->get_object_by_moniker('excalibur@sea');
        $excal->location($e->player->location);
        $e->player->complete_quest('excalibur');

        return(1, "A hand breaks through the water holding up the sword Excalibur!");
    };
}

1;
