package AberMUD::OO::Command::Method::Meta::Role::Specials;
use Moose::Role;

around wrap => sub {
    my ($orig, $self) = (shift, shift);
    my $code = shift;
    my %args = @_;

    my $method = "command_$args{name}";
    my $method_before = "command_$args{name}_BEFORE";
    my $method_after = "command_$args{name}_AFTER";

    my $applied_code = sub {
        my ($player) = @_;
        warn $player;
        my $special = $player->special_composite;
        warn $special;

        # XXX I want to do the check only one time but
        # outside the closure is way too early :(
        for ($method, $method_before, $method_after) {
            die "$_ not found in AberMUD::Special"
                unless $special->can($_);
        }

        $special->$method_before(@_);

        my ($result, $message) = $special->$method(@_);

        my $orig_code_result = $code->(@_);

        # FIXME this is gonna print stuff before the
        # command response is printed
        $special->$method_after(@_);

        return $message if $result;
        return $orig_code_result;
    };

    my $wrap = $self->$orig($applied_code, @_);
    return $wrap;
};

no Moose::Role;

1;
