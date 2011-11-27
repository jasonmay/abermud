#!/usr/bin/env perl
package AberMUD::Input::Command::Take;
use AberMUD::OO::Commands;

command take => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (!@args) {
        return "Take what?";
    }
    elsif (@args == 1) {
        if ($args[0] eq 'all') {
            my @objects_you_can_take = grep {
                $_->on_the_ground
                    and $_->local_to($you)
                    and $_->getable
            }  $universe->get_objects;

            $you->take($_) for @objects_you_can_take;

            $universe->send_to_location(
                $you,
                sprintf(
                    "%s takes everything he can.\n",
                    $you->name
                ),
                except => $you,
            ) if @objects_you_can_take;

            return @objects_you_can_take
                ? "You take everything you can."
                : "There is nothing here for you to take.";
        }
        my @matching_objects = grep {
            $_->local_to($you)
                and $_->name_matches($args[0])
        } $universe->get_objects;

        if (@matching_objects) {
            if ($matching_objects[0]->can('held_by')) {
                if ($matching_objects[0]->held_by) {
                    return "You are already carrying that!"
                        if $matching_objects[0]->held_by == $you;

                    return "The " . $matching_objects[0]->name
                        . " is not on the ground for you to take.";
                }
                $you->take($matching_objects[0]);
                $universe->send_to_location(
                    $you,
                    sprintf(
                        "%s picks up a %s.\n",
                        $you->name, $matching_objects[0]->name
                    ),
                    except => $you,
                );
                return sprintf("You take the %s.", $matching_objects[0]->name);
            }
        }

        return "No object of that name is here.";
    }
    elsif (@args == 3 and lc($args[1]) eq 'from') {
        my $object    = $universe->identify_object($you->location, $args[0])
            or return "I don't know what that is.";

        my $container = $universe->identify_object($you->location, $args[2])
            or return "I don't know what that is.";

        $container->container or return "That's not a container!";

        $container->getable and $container->contained_by
            and return "You need to take the " .
                $container->name . " out of the " .
                $container->contained_by->name . " first.";

        if ($object->containable and $object->contained_by == $container) {
            $object->take_from($container);
            $you->take($object);
            return sprintf(
                'You take the %s out of the %s.',
                $object->name, $container->name,
            );
        }
        else {
            return "That isn't inside the " . $container->name;
        }
    }
    else {
        return "That command syntax is not recognized.";
    }
};

__PACKAGE__->meta->make_immutable;

1;
