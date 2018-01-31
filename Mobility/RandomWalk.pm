#!/usr/bin/perl
#
# A mobility class for random walk.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: RandomWalk.pm,v 1.4 2013/09/28 01:07:52 ohsaki Exp $
#

package Mobility::RandomWalk;

use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Mobility::Fixed);
__PACKAGE__->mk_accessors(qw(speed pause velocity));

# update the agent's velocity.
sub update_velocity {
    my $self = shift;

    my $vel   = $self->speed->();
    my $theta = rand(2 * 3.141592);
    $self->velocity($vel * V(cos($theta), sin($theta)));
}

# create and initialize the object.
sub new {
    my ($class, %opts) = @_;

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
