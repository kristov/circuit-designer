package CircuitDesigner::Object;

use Moose::Role;

has x => (
    is  => 'rw',
    isa => 'Num',
    default => 1,
);

has y => (
    is  => 'rw',
    isa => 'Num',
    default => 1,
);

has highlighted => (
    is  => 'rw',
    isa => 'Bool',
    default => 1,
);

1;
