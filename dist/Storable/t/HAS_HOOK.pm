package HAS_HOOK;

our ($thawed_count, $loaded_count);
sub STORABLE_thaw {
  ++$thawed_count;
}

++$loaded_count;

1;
