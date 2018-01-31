#!/usr/bin/perl
#
# An agent class implementing SA-BCAST.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: SA_BCAST.pm,v 1.9 2013/09/27 16:07:49 ohsaki Exp $
#

package Agent::SA_BCAST;

use List::Util qw(max min);
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Agent::P_BCAST);
__PACKAGE__->mk_accessors(qw(c min_p n_th));

# default control parameters for SA-BCAST
my $C     = 1.5;
my $MIN_P = 0.01;
my $N_TH  = 50;

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    $opts{c}     ||= $C;
    $opts{min_p} ||= $MIN_P;
    $opts{n_th}  ||= $N_TH;
    my $self = $class->SUPER::new(%opts);
    return $self;
}

# try to deliver its carrying message to all neighbor nodes
sub forward {
    my ( $self, $agents_ref ) = @_;

    # find encouter nodes (i.e., newly visible nodes)
    my $neighbors_ref  = $self->neighbors($agents_ref);
    my $encounters_ref = $self->encounters($neighbors_ref);
    $self->last_neighbors($neighbors_ref);
    return unless @$encounters_ref;

    # forward only when N-th% of neighbors has changed
    my $change_ratio = scalar(@$encounters_ref) / scalar(@$neighbors_ref);
    return unless ( $change_ratio >= $self->n_th / 100 );

    for my $msg ( keys %{ $self->received } ) {
        # change forwarding probability based on the number of duplicates
        my $dups = max( $self->received->{$msg} - 1, 0 );
        my $p    = max( 1 / $self->c**$dups,         $self->min_p );
        for my $agent (@$encounters_ref) {
            $self->sendmsg( $agent, $msg ) if ( rand() <= $p );
        }
    }
}

1;
