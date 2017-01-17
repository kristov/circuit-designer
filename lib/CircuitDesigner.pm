package CircuitDesigner;

use Moose;
use GtkZ::App;
use CircuitDesigner::Object::DIP;
extends 'GtkZ::App::Graphical::Cairo';

my $DIP = CircuitDesigner::Object::DIP->new( { nr_pins => 16, wide => 0 } );

has dotfile => (
    is => 'ro',
    isa => 'Str',
    default => '.circuit-designer',
);

has board_width => (
    is  => 'rw',
    isa => 'Int',
    default => 100,
);

has board_height => (
    is  => 'rw',
    isa => 'Int',
    default => 100,
);

has objects => (
    is  => 'rw',
    isa => 'ArrayRef',
    default => sub { return []; }
);

sub _build_layer_renderers {
    my ( $self ) = @_;
    return [
        sub {
            my ( $self, $cr ) = @_;
            $self->render_board( $cr );
            my $objects = $self->objects;
            for my $object ( @{ $objects } ) {
                $object->render_cairo( $self, $cr );
            }
        },
        sub {
            my ( $self, $cr ) = @_;
            $DIP->x( $self->rel_mouse_x );
            $DIP->y( $self->rel_mouse_y );
            $DIP->render_cairo( $self, $cr );
        }
    ];
}

sub render_board {
    my ( $self, $cr ) = @_;
    $cr->save;
    $cr->set_line_width( 2 );
    $cr->set_source_rgb( 0, 0, 1 );

    my $lines = [
        [ $self->board_width, 0 ],
        [ $self->board_width, $self->board_height ],
        [ 0, $self->board_height ],
        [ 0, 0 ],
    ];
    my $start = $self->translate( [ 0, 0 ] );
    $cr->move_to( $start->[0], $start->[1] );
    for my $line ( @{ $lines } ) {
        my $point = $self->translate( $line );
        $cr->line_to( $point->[0], $point->[1] );
    }
    $cr->stroke();
    $cr->restore;
}

sub mouse_moved {
    my ( $self ) = @_;
    $self->invalidate_da;
}

sub left_click {
    my ( $self ) = @_;
    my $objects = $self->objects;
    push @{ $objects }, CircuitDesigner::Object::DIP->new( {
        nr_pins => 64,
        wide    => 1,
        x       => $self->rel_mouse_x,
        y       => $self->rel_mouse_y,
    } );
}

__PACKAGE__->meta->make_immutable;
