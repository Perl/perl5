#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

# Required method - satisfied by class
{
    role Stringable {
        method to_string;
        method display { ">> " . $self->to_string . " <<" }
    }

    class Document :does(Stringable) {
        field $content :param;
        method to_string { "Doc($content)" }
    }

    my $d = Document->new(content => "hello");
    is($d->to_string, 'Doc(hello)',        'class satisfies required method');
    is($d->display,   '>> Doc(hello) <<',  'role method uses satisfied requirement');
}

# Required method - unsatisfied (class)
{
    ok(!eval q{
        use v5.36;
        use feature 'class';
        no warnings 'experimental::class';

        role NeedsToString {
            method to_string;
        }

        class NoToString :does(NeedsToString) {
            field $x :param;
        }
        1;
    }, 'unsatisfied required method croaks');
    like($@, qr/Method to_string is required by role NeedsToString but not provided by/,
        'correct error for unsatisfied required method');
}

# Required method - unsatisfied roles do NOT croak (propagated)
{
    role NeedsName {
        method name;
    }

    role Greeting :does(NeedsName) {
        method greet { "Hello, " . $self->name }
    }

    ok(1, 'role composing role with required method does not croak');
    ok(Greeting->can('greet'), 'role has its own method');
}

# Transitive required method - propagated through role, unsatisfied at class
{
    ok(!eval q{
        use v5.36;
        use feature 'class';
        no warnings 'experimental::class';

        role Inner2 {
            method required_method;
        }

        role Outer2 :does(Inner2) {
            method other { "other" }
        }

        class BadClass :does(Outer2) {
            field $x :param;
        }
        1;
    }, 'transitive unsatisfied required method croaks');
    like($@, qr/Method required_method is required by role/,
        'correct error for transitive unsatisfied requirement');
}

# Transitive required method - satisfied by class
{
    role NeedsId {
        method id;
    }

    role Trackable :does(NeedsId) {
        method track { "tracking:" . $self->id }
    }

    class Item :does(Trackable) {
        field $id :param;
        method id { $id }
    }

    my $i = Item->new(id => 42);
    is($i->id,    42,            'class satisfies transitive requirement');
    is($i->track, 'tracking:42', 'intermediate role method uses satisfied requirement');
}

# One role satisfies another role's requirement
{
    role NeedsLabel {
        method label;
    }

    role HasLabel {
        field $label :param;
        method label { $label }
    }

    role NeedsAndUsesLabel :does(NeedsLabel) {
        method display_label { "[" . $self->label . "]" }
    }

    class Widget :does(NeedsAndUsesLabel) :does(HasLabel) {
        field $x :param;
    }

    my $w = Widget->new(x => 1, label => "OK");
    is($w->label,         'OK',   'requirement satisfied by another role');
    is($w->display_label, '[OK]', 'method using cross-role satisfied requirement');
}

# Multiple required methods
{
    role Serializable {
        method serialize;
        method deserialize;
    }

    # Satisfy both
    class Data :does(Serializable) {
        field $value :param;
        method serialize { "s:$value" }
        method deserialize { "d:$value" }
    }

    my $d = Data->new(value => "test");
    is($d->serialize,   's:test', 'first required method satisfied');
    is($d->deserialize, 'd:test', 'second required method satisfied');
}

# Multiple required methods - partial satisfaction fails
{
    ok(!eval q{
        use v5.36;
        use feature 'class';
        no warnings 'experimental::class';

        role NeedsBoth {
            method alpha;
            method beta;
        }

        class OnlyAlpha :does(NeedsBoth) {
            field $x :param;
            method alpha { "a" }
        }
        1;
    }, 'partially satisfied requirements croak');
    like($@, qr/Method beta is required by role NeedsBoth/,
        'error names the unsatisfied method');
}

# Required method with :reader satisfying it
{
    role NeedsTitle {
        method title;
    }

    class Book :does(NeedsTitle) {
        field $title :param :reader;
    }

    my $b = Book->new(title => "Perl");
    is($b->title, 'Perl', ':reader satisfies required method');
}

# Deep transitive chain of requirements
{
    role Level3 {
        method deep;
    }

    role Level2 :does(Level3) {
        method mid { "mid:" . $self->deep }
    }

    role Level1 :does(Level2) {
        method top { "top:" . $self->mid }
    }

    class DeepClass :does(Level1) {
        field $x :param;
        method deep { "deep($x)" }
    }

    my $d = DeepClass->new(x => 7);
    is($d->deep, 'deep(7)',               'deeply required method satisfied');
    is($d->mid,  'mid:deep(7)',           'intermediate uses deep requirement');
    is($d->top,  'top:mid:deep(7)',       'top-level traverses full chain');
}

done_testing;
