#!./perl

BEGIN {
    package BaseClass; #forward package declaration for base.pm

    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
}

{
    package BaseClass;

    sub method {
    }
}

{
    package Class;
    use base qw(BaseClass +readonly);

    sub mtest {
        Class->method;

        my Class $obj = bless {};

        $obj->method;
    }

}

{
    package Class2;
    use base qw(BaseClass);

    sub mtest {
        Class2->method;

        my Class2 $obj = bless {};

        $obj->method;
    }
}

use Test;

plan tests => 2;

use B ();

sub cv_root {
    B::svref_2object(shift)->ROOT;
}

sub method_in_tree {
    my $op = shift;
    if ($$op && ($op->flags & B::OPf_KIDS)) {
	for (my $kid = $op->first; $$kid; $kid = $kid->sibling) {
            return 1 if $kid->ppaddr =~ /method/i;
	    return 1 if method_in_tree($kid);
	}
    }
    return 0;
}

ok ! method_in_tree(cv_root(\&Class::mtest));
ok   method_in_tree(cv_root(\&Class2::mtest));
