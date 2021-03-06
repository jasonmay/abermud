#!/usr/bin/env perl
package AberMUD::Input::Command::Take;
use AberMUD::OO::Commands;

command take => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments;

    if (!@args) {
        return "Take what?";
    }
    elsif (@args == 1) {
        if ($args[0] eq 'all') {
            my @objects_you_can_take = grep {
                $_->on_the_ground
                    and $_->local_to($e->player)
                    and $_->getable
            }  $e->universe->get_objects;

            $e->player->take($_) for @objects_you_can_take;

            $e->universe->send_to_location(
                $e->player,
                sprintf(
                    "%s takes everything he can.\n",
                    $e->player->name
                ),
                except => $e->player,
            ) if @objects_you_can_take;

            return @objects_you_can_take
                ? "You take everything you can."
                : "There is nothing here for you to take.";
        }
        my @matching_objects = grep {
            $_->local_to($e->player)
                and $_->name_matches($args[0])
        } $e->universe->get_objects;

        if (@matching_objects) {
            if ($matching_objects[0]->can('held_by')) {
                if ($matching_objects[0]->held_by) {
                    return "You are already carrying that!"
                        if $matching_objects[0]->held_by == $e->player;

                    return "The " . $matching_objects[0]->name
                        . " is not on the ground for you to take.";
                }
                $e->player->take($matching_objects[0]);
                $e->universe->send_to_location(
                    $e->player,
                    sprintf(
                        "%s picks up a %s.\n",
                        $e->player->name, $matching_objects[0]->name
                    ),
                    except => $e->player,
                );
                return sprintf("You take the %s.", $matching_objects[0]->name);
            }
        }

        return "No object of that name is here.";
    }
    elsif (@args == 3 and lc($args[1]) eq 'from') {
        my $object    = $e->universe->identify_object($e->player->location, $args[0])
            or return "I don't know what that is.";

        my $container = $e->universe->identify_object($e->player->location, $args[2])
            or return "I don't know what that is.";

        $container->container or return "That's not a container!";

        $container->getable and $container->contained_by
            and return "You need to take the " .
                $container->name . " out of the " .
                $container->contained_by->name . " first.";

        if ($object->containable and $object->contained_by == $container) {
            $container->take_from($object);
            $e->player->take($object);
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
