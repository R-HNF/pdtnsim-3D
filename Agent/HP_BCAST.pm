#!/usr/bin/perl
#
# An agent class implementing HP-BCAST.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: HP_BCAST.pm,v 1.4 2013/09/27 16:07:42 ohsaki Exp $
#

package Agent::HP_BCAST;

use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Agent::P_BCAST);
__PACKAGE__->mk_accessors(qw(history));

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    $self->{history} = {};
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

    for my $msg ( keys %{ $self->received } ) {
        for my $agent (@$encounters_ref) {
            # do not forward if encounter node already has the message
            next if ( exists $self->history->{$msg}->{$agent} );
            $self->sendmsg( $agent, $msg );
            $self->history->{$msg}->{$agent} = 1;
            # receiver then knows sender has the message
            $agent->history->{$msg}->{$self} = 1;
            # sender transfers its history with piggy backing
            for ( keys %{ $self->history->{$msg} } ) {
                $agent->history->{$msg}->{$_} = 1;
            }
        }
    }
}

1;
