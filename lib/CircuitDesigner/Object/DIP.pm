package CircuitDesigner::Object::DIP;

use Moose;
use Data::Dumper;
use Math::Trig qw( pi );
use constant PIN_DIST => 2.54;
with 'CircuitDesigner::Object';

my $PIN_CONF = {
    thin => {
        width   => 7.62,
        nr_pins => [ qw( 4 6 8 14 16 18 20 24 28 ) ],
    },
    wide => {
        width   => 15.24,
        nr_pins => [ qw( 24 28 32 36 40 48 52 64 ) ],
    },
};

has nr_pins => (
    is  => 'ro',
    isa => 'Int',
    required => 1,
    documentation => 'Number of pins on the chip',
);

has wide => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => 'Wide DIP package',
);

has pins => (
    is  => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    builder => '_build_pins',
);

sub _build_pins {
    my ( $self ) = @_;

    my $nr_pins_per_side = $self->nr_pins / 2;

    my $size_key = $self->wide ? 'wide' : 'thin';
    my $pin_width = $PIN_CONF->{$size_key}->{width};

    my $half_width = $pin_width / 2;
    my $half_pin_height = ( ( $nr_pins_per_side * PIN_DIST ) - PIN_DIST ) / 2;

    my $add = 1;
    my $x = 0;
    my $y = 0;
    my @points;
    for my $pin_nr ( 1 .. $self->nr_pins ) {
        push @points, {
            coords  => [ $x - $half_width, $y - $half_pin_height ],
            pin_nr  => $pin_nr,
        };
        if ( $pin_nr >= $nr_pins_per_side ) {
            if ( $add ) {
                $x += $pin_width;
                $add = 0;
            }
            else {
                $y -= PIN_DIST;
            }
        }
        else {
            $y += PIN_DIST;
        }
    }

    return \@points;
}

has bounding_box => (
    is  => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    builder => '_build_bounding_box',
);

sub _build_bounding_box {
    my ( $self ) = @_;

    my $min = [ 0, 0 ];
    my $max = [ 0, 0 ];

    my $pins = $self->pins;
    for my $pin ( @{ $pins } ) {
        for my $i ( 0, 1 ) {
            $max->[$i] = $pin->{coords}->[$i] if $pin->{coords}->[$i] > $max->[$i];
            $min->[$i] = $pin->{coords}->[$i] if $pin->{coords}->[$i] < $min->[$i];
        }
    }

    return [ $min, $max ];
}

sub render_cairo {
    my ( $self, $app, $cr ) = @_;
    $cr->save;

    my $x = $self->x;
    my $y = $self->y;

    my $pins = $self->pins;
    for my $pin ( @{ $pins } ) {
        my $p = $app->translate( [ $pin->{coords}->[0] + $x, $pin->{coords}->[1] + $y ] );
        $self->normal_pad( @{ $p }, $cr );
    }

    if ( $self->highlighted ) {
        my $bbox = $self->bounding_box;
        $cr->set_line_width( 1 );
        $cr->set_source_rgb( 0.3, 0.3, 1 );
        my $s = $app->translate( [ $bbox->[0]->[0] + $x, $bbox->[0]->[1] + $y ] );
        $cr->move_to( @{ $s } );
        my $p;
        $p = $app->translate( [ $bbox->[0]->[0] + $x, $bbox->[1]->[1] + $y ] );
        $cr->line_to( @{ $p } );
        $p = $app->translate( [ $bbox->[1]->[0] + $x, $bbox->[1]->[1] + $y ] );
        $cr->line_to( @{ $p } );
        $p = $app->translate( [ $bbox->[1]->[0] + $x, $bbox->[0]->[1] + $y ] );
        $cr->line_to( @{ $p } );
        $cr->line_to( @{ $s } );
        $cr->stroke();
    }
    $cr->restore;
}

sub normal_pad {
    my ( $self, $x, $y, $cr ) = @_;
    return unless ( defined $x && defined $y );
    $cr->set_line_width( 1 );
    $cr->set_source_rgb( 0, 1, 0 );
    $cr->move_to( $x, $y );
    $cr->arc( $x, $y, 1, 0, 2 * Math::Trig::pi );
    $cr->stroke();
}

__PACKAGE__->meta->make_immutable;
