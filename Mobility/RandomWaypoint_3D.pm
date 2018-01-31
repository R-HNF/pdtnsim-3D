#!/usr/bin/perl

package Mobility::RandomWaypoint_3D;

use List::Util qw(min max);
use Math::Vector::Real;
use strict;
use base qw(Mobility::RandomWalk_3D);
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
