package AberMUD::Special::Plugin::Quest::Excalibur;
use AberMUD::Special::Plugin;
use List::MoreUtils qw(any);

sub setup {
    before_command blow => sub {
        my %args = @_;
        my $e = $args{event};
        my $obj = $e->universe->identify_object(
            $e->player->location,
            $e->arguments,
        );

        return 0 unless $obj;
        return 0 unless $obj->moniker and $obj->moniker eq 'horn@labyrinth';

        return 0 unless any {
            $e->player->location->moniker
                and $e->player->location->moniker eq "$_\@sea"
        } ( 1 .. 10);

        my $excal = $e->universe->get_object_by_moniker('excalibur@sea');
        $excal->location($e->player->location);
        $e->universe->complete_quest($e->player, 'excalibur');

        return(1, "A hand breaks through the water holding up the sword Excalibur!");
    };
}

1;
