#!/usr/bin/perl
#
# An agent class implementing P-BCAST (PUSH-based BroadCAST) for 3D.
#

package Agent::P_BCAST_3D;

use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Agent::P_BCAST);

sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    
    return $self;
}

sub neighbors {
    my ( $self, $agents_ref ) = @_;

    my ( $x, $y, $z ) = @{ $self->{mobility}->{current} };
    
    my $range = $self->{range};

    my @neighbors;
    my ( $p, $dx, $dy, $dz);
    for my $agent (@$agents_ref) {
        next if ( $self eq $agent );
        $p  = $agent->{mobility}->{current};
        $dx = $x - $p->[0];
        next if ( $dx > $range or -$dx > $range );
        $dy = $y - $p->[1];
        next if ( $dy > $range or -$dy > $range );
	$dz = $z - $p->[2];
        next if ( $dz > $range or -$dz > $range );
	next if ( sqrt( $dx * $dx + $dy * $dy + $dz * $dz) >= $range );
	
        push( @neighbors, $agent );
    }

    return \@neighbors;
}

1;
