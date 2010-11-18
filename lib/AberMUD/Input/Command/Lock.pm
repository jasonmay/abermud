package AberMUD::Input::Command::Lock;
use Moose;
use AberMUD::OO::Commands;

command unlock => sub {
    my $you = shift;
    my $args = shift;

    my $obj = $you->universe->identify_object($you->location, $args)
        or return "Nothing of that name is here.";

    $obj->lockable or return "You can't unlock that!";
    $obj->locked   or return "It's already unlocked.";

    my $key = $you->carrying_key
        or return "You need a key to unlock things.";

    $obj->unlock();

    return $obj->lock_text || sprintf(
        'You use your %s to unlock the %s.',
        $key->formatted_name,
        $obj->formatted_name,
    );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
