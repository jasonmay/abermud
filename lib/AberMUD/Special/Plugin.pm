package AberMUD::Special::Plugin;
use base 'Exporter';

BEGIN {
    my @functions = qw(
        before_command
        after_command
        before_change_location
        after_change_location
        before_kill_mobile
        after_kill_mobile
    );
    our @EXPORT = @functions;
    for (@functinos) {
        *$_ = sub {};
    }
}

1;
