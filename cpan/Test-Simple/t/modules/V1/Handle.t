use Test2::V1 -Ppi, -target => 'Test2::V1::Handle';

isa_ok($CLASS, ['Test2::Handle'], "subclassed properly");

is($CLASS->DEFAULT_HANDLE_BASE, 'Test2::V1::Base', "Got correct handle base");

done_testing;
