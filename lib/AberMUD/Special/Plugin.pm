package AberMUD::Special::Plugin;
use base 'Exporter';

BEGIN {
    my @functions = qw(
        before_command
        after_command
        before_change_location
        after_change_location
        before_death
        after_death
        before_sacrifice
        after_sacrifice
    );
    our @EXPORT = @functions;
    for (@functinos) {
        *$_ = sub {};
    }
}

1;
