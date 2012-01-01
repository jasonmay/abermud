#!/usr/bin/env perl
package AberMUD::Input::Command::Drop;
use AberMUD::OO::Commands;

command drop => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments;

    if (!@args) {
        return "Drop what?";
    }
    elsif ($args[0] eq 'all') {
        for ($e->player->carrying_loosely) {
            $e->universe->change_location($_, $e->player->location);
            $e->player->drop($_);
            $_->dropped(1) if $_->flags->{getflips};
        }

        $e->universe->send_to_location(
            $e->player,
            sprintf(
                "%s drops everything he can.\n",
                $e->player->name,
            ),
            except => $e->player,
        );
        return "You drop everything you can.";
    }
    else {
        my @matching_objects = grep {
            $_->can('held_by') and $_->held_by
            and $_->held_by == $e->player
            and lc($_->name) eq lc($args[0])
        } $e->universe->get_objects;

        if (@matching_objects) {
            $e->player->drop($matching_objects[0]);
            $matching_objects[0]->dropped(1) if $matching_objects[0]->dropped_description;
            $e->universe->change_location($matching_objects[0], $e->player->location);
            $e->universe->send_to_location(
                $e->player,
                sprintf(
                    "%s drops a %s.\n",
                    $e->player->name, $matching_objects[0]->name
                ),
                except => $e->player,
            );
            return sprintf("You drop the %s.", $matching_objects[0]->name);
        }

        return "No object of that name is here.";
    }
};

__PACKAGE__->meta->make_immutable;

1;
