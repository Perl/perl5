package BaseIncMandatory;

BEGIN { package main;
    is $INC[-1], '.', 'trailing dot remains in @INC during mandatory module load from base';
    is 0+(grep ref eq 'CODE', @INC), 1, '... and no dummy hook is present';
}

1;
