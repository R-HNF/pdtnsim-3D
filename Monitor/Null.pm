#!/usr/bin/perl
#
# A dummy class without simulation monitoring.
# Copyright (c) 2011-2013, Hiroyuki Ohsaki.
# All rights reserved.
#
# $Id: Null.pm,v 1.2 2013/09/28 01:44:05 ohsaki Exp $
#

package Monitor::Null;

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

}

sub close {
    my ( $self, $agents_ref ) = @_;

}

1;
