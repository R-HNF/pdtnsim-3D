#!/usr/bin/perl
#
# A monitor class for visualizing simulation with curses.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Curses.pm,v 1.4 2013/09/28 01:43:50 ohsaki Exp $
#

# http://www.faqs.org/docs/Linux-HOWTO/NCURSES-Programming-HOWTO.html
# http://notes.benv.junerules.com/all/software/ncurses-magic-are-you-a-magician/

package Monitor::Curses;

use Curses;
use Graph::Enhanced;
use Smart::Comments;
use Term::ANSIColor;
use List::Util qw(min max);
use diagnostics;
use feature qw(state);
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(width height graph pause screen_w screen_h curses));

my $CHAR_PER_UNIT = 50 / 1000;    # characters per unit length
my $VERTEX_CHAR   = '.';
my $AGENT_CHAR    = 'O';

# meter-to-pixel conversion
sub unit2char {
    return $_[0] * $CHAR_PER_UNIT;
}

# draw a graph on the screen
sub draw_graph {
    my $self = shift;

    $self->curses->attron( COLOR_PAIR(1) );
    my ( %xpos, %ypos );
    for my $v ( $self->graph->vertices ) {
        my $pv = $self->graph->get_vertex_attribute( $v, 'xy' );
        my ( $x, $y ) = ( unit2char( $pv->[0] ), unit2char( $pv->[1] ) );
        $self->curses->addstr( $y, $x, 'x' );
        $xpos{$v} = $x;
        $ypos{$v} = $y;
    }

    for my $e ( $self->graph->edges ) {
        my $p1 = $self->graph->get_vertex_attribute( $e->[0], 'xy' );
        my ( $x1, $y1 ) = ( unit2char( $p1->[0] ), unit2char( $p1->[1] ) );
        my $p2 = $self->graph->get_vertex_attribute( $e->[1], 'xy' );
        my ( $x2, $y2 ) = ( unit2char( $p2->[0] ), unit2char( $p2->[1] ) );
        my $steps = max( abs( $x2 - $x1 ), abs( $y2 - $y1 ) );
        for ( 1 .. $steps - 1 ) {
            $self->curses->addstr( $y1 + ( $y2 - $y1 ) * $_ / $steps,
                $x1 + ( $x2 - $x1 ) * $_ / $steps, '.' );
        }
    }
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;

    $self->{screen_w} = $self->{width} * $CHAR_PER_UNIT;
    $self->{screen_h} = $self->{height} * $CHAR_PER_UNIT;
    return $self;
}

sub open {
    my ( $self, $agents_ref ) = @_;

    $self->curses( Curses->new );
    initscr;
    start_color();
    init_pair( 1, COLOR_GREEN, COLOR_BLACK );
    init_pair( 2, COLOR_WHITE, COLOR_BLUE );
    init_pair( 3, COLOR_WHITE, COLOR_RED );
}

sub display {
    my ( $self, $time, $agents_ref ) = @_;

    # first draw the mobility constrains
    $self->curses->erase;
    $self->draw_graph if defined $self->{graph};

    my ( $tx_total, $dup_total, $nreceived ) = ( 0, 0, 0 );
    # draw every agent in different colors according to its status
    for my $agent (@$agents_ref) {
        my $v = $agent->mobility->current;
        my ( $x, $y ) = ( unit2char( $v->[0] ), unit2char( $v->[1] ) );
        my $color
            = defined $agent->received->{1}
            ? 3
            : 2;
        $self->curses->attron( COLOR_PAIR($color) );
        $self->curses->addstr( $y, $x, sprintf( '%2d', $agent->id ) );
        $tx_total  += $agent->tx_count;
        $dup_total += $agent->dup_count;
        $nreceived += keys %{ $agent->received };
    }

    # display simulation information
    $self->curses->attron( COLOR_PAIR(1) );
    $self->curses->addstr( 0, 0, sprintf( "TIME %9.2f", $time ) );
    $self->curses->addstr( 1, 0, sprintf( "DUP %7d",    $dup_total ) );
    $self->curses->addstr( 2, 0, sprintf( "TX  %7d",    $tx_total ) );
    $self->curses->addstr( 2, 0, sprintf( "RECV%7d",    $nreceived ) );
    select( undef, undef, undef, $self->pause ) if defined $self->pause;
    $self->curses->move( 0, 0 );
    $self->curses->refresh;
}

sub close {
    my ( $self, $agents_ref ) = @_;

}

1;
