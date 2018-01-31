#!/usr/bin/perl
#
# A monitor class for visualizing simulation with SDL.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: SDL.pm,v 1.6 2013/09/28 01:51:10 ohsaki Exp $
#

# http://sdl.perl.org/SDL-Video.html

package Monitor::SDL;

use Graph::Enhanced;
use SDL::GFX::Primitives;
use SDL::Rect;
use SDL::Surface;
use SDL::Video;
use SDL;
use Smart::Comments;
use diagnostics;
use feature qw(state);
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(width height graph pause video_file screen_w screen_h screen surface)
);

my $SCREEN_FLAG     = SDL_ASYNCBLIT | SDL_NOFRAME;
my $VERTEX_RADIUS   = 1;                             # radius of vertex/agent
my $PIXEL_PER_UNIT  = 900 / 1000;                    # pixels per unit length
my $VERTEX_COLOR    = 0x91e19fff;
my $EDGE_COLOR      = 0x38a838ff;
my $LINK_COLOR      = 0xfdb300ff;
my $SUS_AGENT_COLOR = 0x87ceebff;
my $SUS_RANGE_COLOR = 0x67aeeb7f;
my $INF_AGENT_COLOR = 0xff8700ff;
my $INF_RANGE_COLOR = 0xffd7007f;
my $WAIT_AGENT_MASK = 0xffffff3f;

my $TMPDIR = '/tmp/epidemic';

# meter-to-pixel conversion
sub unit2pixel {
    return $_[0] * $PIXEL_PER_UNIT;
}

# draw a graph on the surface
sub draw_graph {
    my ( $surface, $g ) = @_;

    my ( %xpos, %ypos );
    for my $v ( $g->vertices ) {
        my $pv = $g->get_vertex_attribute( $v, 'xy' );
        my ( $x, $y ) = ( unit2pixel( $pv->[0] ), unit2pixel( $pv->[1] ) );
        SDL::GFX::Primitives::filled_circle_color( $surface, $x, $y, 3,
            $VERTEX_COLOR );
        $xpos{$v} = $x;
        $ypos{$v} = $y;
    }
    for my $e ( $g->edges ) {
        SDL::GFX::Primitives::line_color(
            $surface,
            $xpos{ $e->[0] },
            $ypos{ $e->[0] },
            $xpos{ $e->[1] },
            $ypos{ $e->[1] },
            $EDGE_COLOR
        );
    }
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;

    $self->{screen_w} = unit2pixel( $self->{width} );
    $self->{screen_h} = unit2pixel( $self->{height} );
    $self->{video_file} = $ENV{DTNSIM_VIDEO_FILE};
    return $self;
}

sub open {
    my ( $self, $agents_ref ) = @_;

    # SDL initialization
    SDL::init(SDL_INIT_VIDEO);
    $self->screen(
        SDL::Video::set_video_mode(
            $self->screen_w, $self->screen_h, 16, $SCREEN_FLAG
        )
    );
    # draw the mobility constrains as a graph
    $self->surface(
        SDL::Surface->new(
            $SCREEN_FLAG, $self->screen_w, $self->screen_h, 16, 0, 0, 0, 0
        )
    );
    draw_graph( $self->surface, $self->graph ) if defined $self->graph;

    # make sure temporary directory is empty
    if ( $self->video_file ) {
        mkdir $TMPDIR or die "mkdir: $TMPDIR: $!\n";
        system "rm -f $TMPDIR/*";
    }
}

sub display {
    my ( $self, $time, $agents_ref ) = @_;

    state $frames = 0;
    # first draw the mobility constrains
    my $rect = SDL::Rect->new( 0, 0, $self->screen_w, $self->screen_h );
    SDL::Video::blit_surface( $self->surface, $rect, $self->screen, $rect );

    my ( $tx_total, $dup_total, $nreceived ) = ( 0, 0, 0 );
    # draw every agent in different colors according to its status
    for my $agent (@$agents_ref) {
        my $v = $agent->mobility->current;
        my ( $x, $y ) = ( unit2pixel( $v->[0] ), unit2pixel( $v->[1] ) );
        my $agent_color
            = defined $agent->received->{1}
            ? $INF_AGENT_COLOR
            : $SUS_AGENT_COLOR;
        $agent_color &= $WAIT_AGENT_MASK if ( $agent->mobility->wait > 0 );
        my $range_color
            = defined $agent->received->{1}
            ? $INF_RANGE_COLOR
            : $SUS_RANGE_COLOR;
        $range_color &= $WAIT_AGENT_MASK if ( $agent->mobility->wait > 0 );
        SDL::GFX::Primitives::filled_circle_color( $self->screen, $x, $y,
            unit2pixel( $agent->range ), $range_color );
        SDL::GFX::Primitives::filled_circle_color( $self->screen, $x, $y,
            unit2pixel(3), $agent_color );
        $tx_total  += $agent->tx_count;
        $dup_total += $agent->dup_count;
        $nreceived += keys %{ $agent->received };

        # draw wired communication link among wired agents
        next unless $agent->isa("Agent::Wired");
        for my $friend ( @{ $agent->friends } ) {
            my $v2 = $friend->mobility->current;
            my ( $x2, $y2 )
                = ( unit2pixel( $v2->[0] ), unit2pixel( $v2->[1] ) );
            SDL::GFX::Primitives::line_color( $self->screen, $x, $y, $x2, $y2,
                $LINK_COLOR );
        }
    }

    # draw simulation information
    SDL::GFX::Primitives::string_color( $self->screen, 0, 8,
        sprintf( "TIME %9.2f", $time ), 0xffffffff );
    SDL::GFX::Primitives::string_color( $self->screen, 0, 16,
        sprintf( "TX  %7d", $tx_total ), 0xffffffff );
    SDL::GFX::Primitives::string_color( $self->screen, 0, 24,
        sprintf( "DUP %7d", $dup_total ), 0xffffffff );
    SDL::GFX::Primitives::string_color( $self->screen, 0, 32,
        sprintf( "RECV%7d", $nreceived ), 0xffffffff );
    SDL::Video::update_rects( $self->screen, $rect );
    select( undef, undef, undef, $self->pause ) if defined $self->pause;

    # export frame buffer as bitmap file
    if ( $self->video_file ) {
        SDL::Video::save_BMP( $self->screen,
            sprintf( '%s/%08d.bmp', $TMPDIR, $frames++ ) );
    }
}

sub close {
    my ( $self, $agents_ref ) = @_;

    # convert seiries of BMP files into AVI video
    if ( $self->video_file ) {
        my $file = $self->video_file;
        system
            "mencoder mf://$TMPDIR/*.bmp -ovc lavc -lavcopts vbitrate=8192 -o $file";
    }
}

1;
