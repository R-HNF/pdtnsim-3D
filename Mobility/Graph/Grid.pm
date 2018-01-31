#!/usr/bin/perl
#
# A mobility class for CRWP (Constrained Random Waypoint) model on a grid.
# Copyright (c) 2011, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Grid.pm,v 1.7 2013/09/28 01:54:38 ohsaki Exp $
#

package Mobility::Graph::Grid;

use Graph::Enhanced;
use List::Util qw(min max);
use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Mobility::Graph::GridFixed);
__PACKAGE__->mk_accessors(
    qw(speed pause velocity goal goal_edge goal_offset));

# update the agent's velocity
sub update_velocity {
    my $self = shift;

    $self->velocity( $self->speed->() );
}

# compute and store the goal coordinate for later use
sub update_goal_cache {
    my $self = shift;

    $self->goal(
        $self->get_coordinate( $self->goal_edge, $self->goal_offset ) );
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    ( $self->{goal_edge}, $self->{goal_offset} ) = $self->random_point;
    $self->update_goal_cache;
    $self->update_velocity;
    return $self;
}

# move the agent for the duration of DELTA
sub move {
    my ( $self, $delta ) = @_;

    # sleep until wait timer expires
    $self->wait( max( $self->wait - $delta, 0 ) );
    return if ( $self->wait > 0 );

    my ( $u, $v ) = @{ $self->current_edge };
    my $length = $self->graph->get_edge_weight_by_id( $u, $v, 0 );

    # advance the agent by SPEED * DELTA
    $self->current_offset( $self->current_offset + $self->velocity * $delta );
    # if very close to the corner, choose the next direction
    if ( abs( $self->current_offset - $length ) < $self->velocity * $delta
        or $self->current_offset > $length )
    {
        # find the vertex whose angle is closest to that of the goal
        my $pv = $self->graph->get_vertex_attribute( $v, 'xy' );
        my $next;
        my $min_angle;
        for my $w ( $self->graph->neighbors($v) ) {
            # never goes back to the coming direction
            next if ( $w == $u );
            my $pw = $self->graph->get_vertex_attribute( $w, 'xy' );
            if (  !defined $min_angle
                or abs( atan2( $self->goal - $pv, $pw - $pv ) ) < $min_angle )
            {
                $min_angle = abs( atan2( $self->goal - $pv, $pw - $pv ) );
                $next = $w;
            }
        }
        # if the next vertex is not determined, force to go back
        $next = $u unless defined $next;

        $self->current_edge( [ $v, $next ] );
        $self->current_offset(0);
    }
    $self->update_current_cache;

    # if close enough to the goal, randomly choose another goal
    my $epsilon = $self->velocity * $delta;
    if ( abs( $self->goal - $self->current ) <= $epsilon ) {
        ( $self->{goal_edge}, $self->{goal_offset} ) = $self->random_point;
        $self->update_goal_cache;
        $self->update_velocity;
        $self->{wait} = $self->pause->();
    }
}

1;
