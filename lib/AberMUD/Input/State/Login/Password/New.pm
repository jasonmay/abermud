package AberMUD::Input::State::Login::Password::New;
use Moose;

with 'AberMUD::Input::State';

sub entry_message { 'Please enter a new password for your character: ' }

sub run {
    my $self = shift;
    my ($controller, $conn, $pass) = @_;

    return $self->entry_message unless $pass;

    my $crypted = crypt($pass, $conn->name_buffer);
    $conn->password_buffer($crypted);

    $conn->shift_state;
    return $conn->input_state->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
