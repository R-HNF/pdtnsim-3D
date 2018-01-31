#!/usr/bin/perl
#
# A dummy class without simulation monitoring.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Log.pm,v 1.2 2013/09/28 01:44:00 ohsaki Exp $
#

package Monitor::Log;

use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors();

sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;
    return $self;
}

sub open {
    my ( $self, $agents_ref ) = @_;
}

sub display {
    my ( $self, $time, $agents_ref ) = @_;

    my ( $tx_total, $rx_total, $dup_total, $nreceived ) = ( 0, 0, 0, 0 );
    for my $agent (@$agents_ref) {
        $tx_total  += $agent->tx_count;
        $rx_total  += $agent->rx_count;
        $dup_total += $agent->dup_count;
        $nreceived += keys %{ $agent->received };
    }
    print join( "\t", $time, $tx_total, $rx_total, $dup_total, $nreceived ),
        "\n";
}

sub close {
    my ( $self, $agents_ref ) = @_;

    for my $agent (@$agents_ref) {
        $agent->dump( verbose => 1 );
    }
}

1;
