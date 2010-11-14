package AberMUD::Data::Levels;
use Moose;

use constant WizLevels => {
    Male => [
        undef, qw(
            Apprentice Emeriti    Wizard
            Istari     ArchWizard DemiGod Shalafi
            God        Creator 
        ),
    ],
    Female => [
        undef, qw(
            Apprentice Emeriti    Wizardess
            Istari     ArchWizard DemiGoddess Shalafi
            Goddess    Padishah
        ),
    ],
};


use constant mage_levels => [
    undef, qw!
        Guest       Novice      Trickster
        Cabalist    Visionist   Phantasmist
        Shadowist   Spellbinder Illusionist
        Evoker      Conjurer    Theurgist
        Thaumaturge Magician    Enchanter
        Warlock     Mage(1st)   Mage(2nd)
        Mage(3rd)   Mage(4th)   Mage(5th)
        Wizard
    !
];

use constant warrior_levels => [
    undef, qw!
        Rookie    Private   Soldier
        Mercenary Vetran    Warrior
        Swordsman Hero      Myrmidon
        Champion  Superhero Knight
        Guardian  Legend    Baron
        Duke      Lord(1st) Lord(2nd)
        Lord(3rd) Lord(4th) Lord(5th)
        High Lord
    !
];

use constant priest_levels => [
    undef, qw!
        Believer    Acolyte     Adept
        Priest      Curate      Canon
        Low Lama    Lama        High Lama
        Great Lama  Patriarch   Priest(1st) 
        Priest(2nd) Priest(3rd) Priest(4th)
        Priest(5th) High Priest Saint
        Angel(1st)  Angel(2nd)  Angel(3rd)
        ArchAngel
    !
];

use constant thief_levels => [
    undef, qw!
        Vagabond    Footpad      Cutpurse
        Robber      Burglar      Filcher
        Sharper     Magsman      Rogue
        High Rogue  Chief Rogue  Prime Rogue
        Low Thief   Thief(1st)   Thief(2nd)
        Thief(3rd)  Thief(4th)   Thief(5th)
        High Thief  Executioner  Assassin
        Guildmaster
    !
];

use constant level_points => [
    qw(
        0      2000   4000   8000
        14000  22000  36000  42000
        56000  72000  90000  110000
        132000 156000 182000 210000
        240000 272000 308000 322000
        356000 400000
    )
];

__PACKAGE__->meta->make_immutable;
no Moose;

1;
