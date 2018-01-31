#!/usr/bin/perl

package Mobility::RandomWalk_3D;

use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Mobility::Fixed_3D);
__PACKAGE__->mk_accessors(qw(speed pause velocity));

# update the agent's velocity.
sub update_velocity {
    my $self = shift;

    my $vel   = $self->speed->();
    my $alpha = rand(2 * 3.141592);
    my $beta  = rand(2 * 3.141592);
    my $gamma = rand(2 * 3.141592);
    $self->velocity($vel * V(cos($alpha), cos($beta), cos($gamma)));
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = $class->SUPER::new(%opts);
    $self->{wait} = 0;
    return $self;
}

# move the agent for the duration of DELTA.
sub move {
    my ($self, $delta) = @_;

    $self->update_velocity;
    $self->current($self->current + $self->velocity * $delta);
    
}

1;
