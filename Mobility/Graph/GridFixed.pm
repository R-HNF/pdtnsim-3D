#!/usr/bin/perl
#
# A mobility class for stationary agents on a grid.
# Copyright (c) 2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: GridFixed.pm,v 1.1 2013/09/27 14:32:38 ohsaki Exp $
#

package Mobility::Graph::GridFixed;

use Graph::Enhanced;
use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(graph current current_edge current_offset wait));

# randomly choose an offset between zero and the edge length
sub random_offset {
    my ( $self, $edge_ref ) = @_;

    return rand( $self->graph->get_edge_weight_by_id( @$edge_ref, 0 ) );
}

# pick a random point, which is defined by the edge and the offset, on paths
sub random_point {
    my $self = shift;

    # FIXME: must choose an edge with a probability proportional to
    # its length
    my $edge_ref = $self->graph->random_edge;
    return ( $edge_ref, $self->random_offset($edge_ref) );
}

# return the coordinate of the point specified by the EDGE and OFFSET
sub get_coordinate {
    my ( $self, $edge_ref, $offset ) = @_;

    my $pu = $self->graph->get_vertex_attribute( $edge_ref->[0], 'xy' );
    my $pv = $self->graph->get_vertex_attribute( $edge_ref->[1], 'xy' );
    my $length = $self->graph->get_edge_weight_by_id( @$edge_ref, 0 );
    return $pu + ( $pv - $pu ) * $offset / $length;
}

# compute and store the current coordinate for later use
sub update_current_cache {
    my $self = shift;

    $self->current(
        $self->get_coordinate( $self->current_edge, $self->current_offset ) );
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;
    ( $self->{current_edge}, $self->{current_offset} ) = $self->random_point;
    $self->update_current_cache;
    $self->{wait} = 1;
    return $self;
}

# move the agent for the duration of DELTA
sub move {
    my ( $self, $delta ) = @_;
}

# create an underlying graph representing paths
sub create_path {
    my ( $class, %opts ) = @_;

    my $width  = $opts{width};
    my $height = $opts{height};
    my $n      = $opts{n} || 10;

    # create underlying network topology
    my $g = new Graph::Enhanced( directed => 0, multiedged => 0 );
    $g->create_graph( 'lattice', 2, $n );

    # save the positions of vertices as Math::Vector object
    for my $j ( 1 .. $n ) {
        for my $i ( 1 .. $n ) {
            my $v = Graph::Enhanced::_lattice_vertex( 2, $n, $i, $j );
            my ( $x, $y ) = (
                ( 0.5 + $i - 1 ) / $n * $width,
                ( 0.5 + $j - 1 ) / $n * $height
            );
            $g->set_vertex_attribute( $v, 'xy', V( $x, $y ) );
        }
    }

    # pre-compute the lengths of edges
    for my $e ( $g->unique_edges ) {
        my ( $u, $v ) = @$e;
        my $length = abs( $g->get_vertex_attribute( $u, 'xy' )
                - $g->get_vertex_attribute( $v, 'xy' ) );
        $g->set_edge_weight_by_id( $u, $v, 0, $length );
        $g->set_edge_weight_by_id( $v, $u, 0, $length );
    }
    return $g;
}

1;
