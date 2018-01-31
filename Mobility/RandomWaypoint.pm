#!/usr/bin/perl
#
# A mobility class for RWP (Random WayPoint) mobility model.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: RandomWaypoint.pm,v 1.12 2013/09/28 01:07:55 ohsaki Exp $
#

package Mobility::RandomWaypoint;

use List::Util qw(min max);
use Math::Vector::Real;
use strict;
use base qw(Mobility::RandomWalk);
__PACKAGE__->mk_accessors(qw(goal));

# update the agent's velocity.
sub update_velocity {
    my $self = shift;

    $self->velocity( $self->speed->() * ( $self->goal - $self->current ) /
            abs( $self->goal - $self->current ) );
}

# randomly choose the goal in the field
sub goal_coordinate {
    my $self = shift;
    $self->random_coordinate;
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    $self->{goal}    = $self->goal_coordinate;
    return $self;
}

# move the agent for the duration of DELTA
sub move {
    my ( $self, $delta ) = @_;

    # sleep until wait time expires
    $self->wait( max( $self->wait - $delta, 0 ) );
    return if ( $self->wait > 0 );

    $self->update_velocity;
    $self->current( $self->current + $self->velocity * $delta );

    # if close enough to the goal, randomly choose another goal
    my $epsilon = abs( $self->velocity ) * $delta;
    if ( abs( $self->goal - $self->current ) <= $epsilon ) {
        $self->goal( $self->goal_coordinate );
        $self->update_velocity;
        $self->{wait} = $self->pause->();
    }
}

1;
