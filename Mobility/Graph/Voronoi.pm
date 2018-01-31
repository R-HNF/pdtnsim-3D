#!/usr/bin/perl
#
#
# Copyright (c) 2011, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Voronoi.pm,v 1.15 2013/09/28 01:54:49 ohsaki Exp $
#

package Mobility::Graph::Voronoi;

use Graph::Enhanced;
use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Mobility::Graph::Grid);

# create an underlying graph representing paths
sub create_path {
    my ( $class, %opts ) = @_;

    my $width   = $opts{width};
    my $height  = $opts{height};
    my $npoints = $opts{npoints} || 100;

    # create underlying network topology
    my $g = new Graph::Enhanced( directed => 0, multiedged => 0 );
    $g->create_graph( 'voronoi', $npoints, $width, $height );

    # save the positions of vertices as Math::Vector object
    for my $v ( $g->vertices ) {
        my ( $x, $y ) = split( ',', $g->get_vertex_attribute( $v, 'pos' ) );
        $g->set_vertex_attribute( $v, 'xy', V( $x, $y ) );
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
