#!/usr/bin/env perl
package AberMUD::Input::Command::Drop;
use AberMUD::OO::Commands;

command drop => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments;

    my @objects = $e->universe->get_objects;
    my $pit;
    # XXX eventually hardcode a pit into the universe
    for my $obj (@objects) {
        next unless $obj->flags->{pit};
        next unless $e->player->in($obj->location);
        next unless $obj->on_the_ground;
        $pit = $obj;
        last;
    }

    my ($interrupt, @hook_results);
    my $drop_block = sub {
        my $object = shift;
        my $drop_object = sub {
            $e->player->drop($object);
            $object->dropped(1) if $object->flags->{getflips};
        };
        #$object->dropped(1) if $objects->dropped_description; #XXX in 'drop foo'
        if ($pit) {
            ($interrupt, @hook_results) = $self->special->call_hooks(
                type => 'sacrifice',
                when => 'before',
                universe => $e->universe,
                arguments => [
                    object   => $object,
                    player   => $e->player,
                    universe => $e->universe,
                ],
            );
            unless ($interrupt) {
                $drop_object->();
                $object->change_location($e->universe->pit_location);
                (undef, @hook_results) = $self->special->call_hooks(
                    type => 'sacrifice',
                    when => 'after',
                    universe => $e->universe,
                    arguments => [
                        object   => $object,
                        player   => $e->player,
                        universe => $e->universe,
                    ],
                );
            }
        }
        else {
            $e->universe->change_location($object, $e->player->location);
            $drop_object->();
        }
    };

    if (!@args) {
        return "Drop what?";
    }
    elsif ($args[0] eq 'all') {
        for ($e->player->carrying_loosely) {
            $drop_block->($_);
        }

        $e->universe->send_to_location(
            $e->player,
            sprintf(
                "%s drops everything he can.\n",
                $e->player->name,
            ),
            except => $e->player,
        );
        return $pit ?
            "You drop all you can into the pit." :
            "You drop everything you can.";
    }
    else {
        my @matching_objects = grep {
            $_->can('held_by') and $_->held_by
            and $_->held_by == $e->player
            and lc($_->name) eq lc($args[0])
        } $e->player->carrying;

        if (@matching_objects) {
            $drop_block->($matching_objects[0]);
            $e->universe->send_to_location(
                $e->player,
                sprintf(
                    "%s drops a %s.\n",
                    $e->player->name, $matching_objects[0]->name
                ),
                except => $e->player,
            );
            return sprintf(
                $pit ? "You drop the %s into the pit." : "You drop the %s.",
                $matching_objects[0]->name
            );
        }

        return "No object of that name is here.";
    }
};

__PACKAGE__->meta->make_immutable;

1;
