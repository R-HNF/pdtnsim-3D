#!/usr/bin/perl
#
# A mobility class for stationary agents.
# Copyright (c) 2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Fixed.pm,v 1.3 2013/09/27 14:32:19 ohsaki Exp $
#

package Mobility::Fixed;

use Math::Vector::Real;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(width height current wait));

# pick a random coordinate on the field
sub random_coordinate {
    my $self = shift;

    return V( rand( $self->width ), rand( $self->height ) );
}

# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;
    $self->{current} = $self->random_coordinate;
    $self->{wait}    = 1;
    return $self;
}

# move the agent for the duration of DELTA
sub move {
    my ( $self, $delta ) = @_;

}

# create an underlying graph representing paths
sub create_path {
    my $self = shift;

    return undef;
}

1;
