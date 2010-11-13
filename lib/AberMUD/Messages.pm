package AberMUD::Messages;
use Moose;
use Clone;

# I'm not sure I like this

use constant WeaponHit => {
    miss => [
        "%a swing%s %g %w at %p %b, missing entirely.",
        "%a lunge%s at %p %b but %q sidestep%t the blow.",
        "%d ward%t off a fierce attack!",
        "%d narrowly evade%t a vicous attack!",
        "%d parry%t %e bungled blow.",
        "%d dodge%t a mighty lunge!",
        "%a lunge%s at %d with %g %w, but %q parry%t the blow!",
        "%a run%s at %d with bright &+Rred&N eyes, but %q evade%t the attack.",
        "%a &+Yswing%s&N at %d with %g &+W%w&N, but %q sidestep%t %a!",
        "%a come%s charging at %d with the %w, but fail%s.",
        "%a come%s very close to hitting %d with %g %w.",
        "%a aim%s for %p %b but the attack fails.",
        "%a run%s at %p %b, but the attempt misses.",
        "%a swing%s %g %w at %p %b, but it it misses by an inch!",
        "%a ward%s off %p fierce attack to %r!",
        "%a lunge%s at %d with %g %w but does not contact!",
        "%a ferociously aim%s for %p %b but %g dodges the blow!",
        "%a &+Rgrowl%s&N, and run%s at %p %b, but the shot is deflected!",
    ],
    futile => [
        "%a hit%s %d with %g %w, but it is absorbed by %r.",
        "%r absorbs %e blow from the %w.",
        "%a hit%s %d, but it is absorbed by %r."
    ],
    weak => [
        "%a hit%s %r weakly with the %w.",
        "%a barely hit%s %r with the %w.",
        "%a braise%s %p %b with the %w.",
        "%a hit%s %r very weakly with the %w.",
        "%a run%s at %r with the %w, but barely make%s contact.",
    ],
    med =>  [
        "%a deliver%s a good hit to %p %b.",
        "%a hit%s %p %b firmly with the &+Y%w.",
        "%a pierce%s %p %b with an average hit from the &+Y%w.",
        "%a hit%s %p %b hard with %e &+Y%w."
    ],
    strong => [
        "%a &+CTOTALLY MASSACRE%S&N %d with the %w!",
        "%a &+CUTTERLY DESTROY%S&N %d with the %w!",
        "%a &+CANNIHILATE%S&N %d with %g %w!",
        "%a &+CBEAT%S&N %d with %g %w!",
        "%a &+CCUT%S&N %d up with %g %w!",
        "%a &+CTEAR%S&N %d up with a forceful hit!"
    ],
};

use constant BareHit => {
    miss => [
        "%d evade%t %e weak punch.",
        "%a curl%s %g fist, charge%s at %p %b, and trip%s.",
        "%a attempt%s to headbutt %d but fall%s.",
        "%d easily parry%t a pathetic punch.",
        "%d narrowly dodge%t a blow to %p %b.",
        "%d luckily evade%t %e fierce hit to %r!"
    ],
    futile => [
        "%a hit%s %d, but it's absorbed by %r.",
        "%a punch%s %p %b, but %r absorbs the blow.",
        "%a weakly hit%s %p %b, but there is no effect."
    ],
    weak => [
        "%a deliver%s a weak punch to %p %b.",
        "%a barely hit%s %p %b with %g bare hands.",
        "A bungled uppercut by %a barely braises %p %b.",
        "A weak jab by %a barely touches %p %b.",
    ],
    med => [
        "%a hit%s %d with %g hand.",
        "%a attack%s %p %b with %g hand.",
        "%a give%s %d a mediocre punch to the %b.",
        "%a throw%s an average punch to %p %b.",
        "%a connect%s with a decent cut to %p %b.",
    ],
    strong => [
        "%a hit%s %d with a powerful uppercut!",
        "%a drive%s forward, hitting %d forcefully with %g hand!",
        "%a deliver%s a mighty blow to %p %b!",
        "%d reel%t as %a jab%s %p %b!",
        "%d stagger%t as %a give%s a brutal punch!"
    ],
};

use constant Death => [
    "%a gutt%s %d with the %w!",
    "%a impale%s %d with %g %w!",
    "%a slice%s %d to bits with the %w! Oh, the humanity!!",
    "%a flay%s, tar%s and feather%s %d!",
    "%a hit%s %d with a fatal blow!",
];

use constant BodyPart => {
    head       =>  "&+Rhead&N",
    right_arm  =>  "&+mright arm&N",
    left_arm   =>  "&+mleft arm&N",
    right_leg  =>  "&+Gright leg&N",
    left_leg   =>  "&+Gleft leg&N",
    right_foot =>  "&+yright foot&N",
    left_foot  =>  "&+yleft foot&N",
    right_hand =>  "&+Bright hand&N",
    left_hand  =>  "&+Bleft hand&N",
    chest      =>  "&+Cchest&N",
    back       =>  "&+gback&N",
    face       =>  "&+rface&N",
    neck       =>  "&+Yneck&N",
};

sub format_fight_message {
    my $msg  = Clone::clone(shift);
    my %data = @_;

    my $attacker = $data{attacker};
    my $victim   = $data{victim};

    my $bodypart = $data{bodypart};

    my $p = $data{perspective};

    my %possessive = (
        Male    => 'his',
        Female  => 'her',
        neither => 'their',
    );

    # indirect object
    my %i_o = (
        Male    => 'he',
        Female  => 'she',
        neither => 'they',
    );

    # substitutions

    $msg =~ s/%b/BodyPart->{$bodypart}/eg;
    $msg =~ s/%r/_outermost_part(bodypart => $bodypart, victim => $victim)/eg;
    $msg =~ s/%w/$attacker->wielding->name/eg;

    if ($p eq 'attacker') {
        $msg =~ s/%g/your/g;
        $msg =~ s/%a/you/g;
        $msg =~ s/%e/your/g;
        $msg =~ s/%[Ss]//g;
    }
    else {
        $msg =~ s!%g!$possessive{$attacker->gender // 'neither'}!eg;
        $msg =~ s/%a/$attacker->formatted_name/eg;
        $msg =~ s/%e/$attacker->formatted_name . q['s]/eg;

        $msg =~ s/%s/s/g;
        $msg =~ s/%S/S/g;
    }

    if ($p eq 'victim') {
        $msg =~ s/%[dq]/you/g;
        $msg =~ s/%p/your/g;
        $msg =~ s/%[Tt]//g;
    }
    else {
        $msg =~ s!%q!$i_o{$victim->gender // 'neither'}!eg;
        $msg =~ s!%d!$victim->formatted_name!eg;
        $msg =~ s/%p/$victim->formatted_name . q['s]/eg;

        $msg =~ s/%t/s/g;
        $msg =~ s/%T/S/g;
    }

    return ucfirst($msg);
}

# body part, or any armor covering it
sub _outermost_part {
    my %args = @_;

    my ($victim, $bodypart) = @args{'victim', 'bodypart'};

    my %cov = $victim->coverage;

    if ($cov{$bodypart}) {
        return $cov{$bodypart}->name;
    }
    else {
        return BodyPart->{$bodypart};
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
