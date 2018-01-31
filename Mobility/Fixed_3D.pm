#!/usr/bin/perl

package Mobility::Fixed_3D;

use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Mobility::Fixed);
__PACKAGE__->mk_accessors(qw(height3d));

# pick a random coordinate on the field
sub random_coordinate {
    my $self = shift;
    return V( rand( $self->width ),
	      rand( $self->height3d ),
	      rand( $self->height )
	);
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    return $self;
}

1;
