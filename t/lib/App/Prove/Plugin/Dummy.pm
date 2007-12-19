package App::Prove::Plugin::Dummy;

sub import {
    main::test_log_import( @_ );
}

1;
