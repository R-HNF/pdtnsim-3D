#!/usr/bin/perl
#
# A mobility class for Levy walk.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: LevyWalk.pm,v 1.4 2013/09/28 01:07:50 ohsaki Exp $
#

package Mobility::LevyWalk;

use List::Util qw(min max);
use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Mobility::RandomWaypoint);
__PACKAGE__->mk_accessors(qw(scale shape));

# Generate a random variable with Pareto distribution.  Mean of the
# Pareto distribution is given by shape * scale / (shape - 1).
sub pareto {
    my ( $scale, $shape ) = @_;

    return $scale / ( rand()**( 1 / $shape ) );
}

# randomly choose the goal in the field so that the distance from the
# current coordinate follows Pareto distribution
sub goal_coordinate {
    my $self = shift;

    my $length = pareto( $self->scale, $self->shape );
    my $theta  = rand( 2 * 3.141592 );
    my $goal   = $self->current + $length * V( cos($theta), sin($theta) );
    # FIXME: the goal coordinate is simply limited with the field
    # boundaries.  A node should *bounce back* with the boundaries.
    return V(
        max( 0, min( $goal->[0], $self->width ) ),
        max( 0, min( $goal->[1], $self->height ) )
    );
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    $opts{scale} = 100 unless defined $opts{scale};
    $opts{shape} = 1.5 unless defined $opts{shape};
    my $self = $class->SUPER::new(%opts);
    return $self;
}

1;
