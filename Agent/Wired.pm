#!/usr/bin/perl
#
# A wired nodes connected with wired communication channel.
# Copyright (c) 2011, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Wired.pm,v 1.4 2013/09/28 01:07:45 ohsaki Exp $
#

package Agent::Wired;

use List::Util qw(max min);
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Agent::P_BCAST);
__PACKAGE__->mk_accessors(qw(friends));

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    $self->{friends} = [];
    return $self;
}

# receive a message from the specified agent
sub recvmsg {
    my ( $self, $agent, $msg ) = @_;

    $self->rx_count( $self->rx_count + 1 );
    $self->dup_count( $self->dup_count + 1 )
        if defined $self->received->{$msg};
    $self->received->{$msg}++;

    # simply infect friends connected with wired links
    for my $friend ( @{ $self->friends } ) {
        $friend->received->{$msg}++;
    }
}

1;
