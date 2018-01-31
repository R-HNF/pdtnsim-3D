#!/usr/bin/perl
#
# An agent class implementing P-BCAST (PUSH-based BroadCAST).
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: P_BCAST.pm,v 1.13 2013/09/28 01:57:42 ohsaki Exp $
#

package Agent::P_BCAST;

use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(id range mobility last_neighbors received tx_count rx_count dup_count)
);

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;
    $self->{last_neighbors} = [];
    $self->{received}       = {} unless defined $self->{received};
    $self->{tx_count}       = 0;
    $self->{rx_count}       = 0;
    $self->{dup_count}      = 0;
    $self->{encount_to}     = {};
    return $self;
}

# find neighbor nodes within the communication range
sub neighbors {
    my ( $self, $agents_ref ) = @_;

    my ( $x, $y ) = @{ $self->{mobility}->{current} };
    my $range = $self->{range};
    my @neighbors;
    my ( $p, $dx, $dy );
    for my $agent (@$agents_ref) {
        next if ( $self eq $agent );
        # check if the agent is in the communication range
        # FIXME: this code is not efficient; should use more efficient
        # pruning such as zoning.
        $p  = $agent->{mobility}->{current};
        $dx = $x - $p->[0];
        next if ( $dx > $range or -$dx > $range );
        $dy = $y - $p->[1];
        next if ( $dy > $range or -$dy > $range );
        next if ( sqrt( $dx * $dx + $dy * $dy ) >= $range );
        push( @neighbors, $agent );
    }
    return \@neighbors;
}

# return newly encoutered neighbor nodes
sub encounters {
    my ( $self, $neighbors_ref ) = @_;

    my %seen;
    for my $agent ( @{ $self->last_neighbors } ) {
        $seen{$agent} = 1;
    }
    my @encouters;
    for my $agent (@$neighbors_ref) {
        if ( !exists $seen{$agent} ) {
            push( @encouters, $agent );
            $self->{encount_to}->{ $agent->id }++;
        }
    }
    return \@encouters;
}

# send a message to the specified agent
sub sendmsg {
    my ( $self, $agent, $msg ) = @_;

    $self->tx_count( $self->tx_count + 1 );
    $agent->recvmsg( $self, $msg );
}

# receive a message from the specified agent
sub recvmsg {
    my ( $self, $agent, $msg ) = @_;

    $self->rx_count( $self->rx_count + 1 );
    $self->dup_count( $self->dup_count + 1 )
        if defined $self->received->{$msg};
    $self->received->{$msg}++;
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
            $self->sendmsg( $agent, $msg );
        }
    }
}

# dump the internal variables of the agent to STDERR
sub dump {
    my ( $self, %opts ) = @_;

    my $id = $self->{id};
    for my $key (qw(tx_count rx_count dup_count)) {
        print "# $id\t$key\t$self->{$key}\n";
    }
    for my $msg ( sort keys %{ $self->received } ) {
        print "# $id\treceived\t$msg\t$self->{received}->{$msg}\n";
    }
    return unless $opts{verbose};
    for my $to_id ( sort { $a <=> $b } keys %{ $self->{encount_to} } ) {
        print "# $id\tencount_to\t$to_id\t$self->{encount_to}->{$to_id}\n";
    }
}

1;
