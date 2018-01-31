#!/usr/bin/perl
#
# A monitor class for visualizing simulation with OpenGL.
# Install freeglut3-dev from apt-get
#

package Monitor::3D_OpenGL;

use OpenGL qw(:all);
use OpenGL::Shader;
use Smart::Comments;
use diagnostics;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(width height height3d cube_w cube_h cube_d)
);

my $SCREEN_W = 1000;
my $SCREEN_H = 700;
my $CUBE_SIZE = 30;		# defalut cube size
my $AGENT_SIZE = 0.25;
my $SCALING = 15;	      # small -> expansion, large -> reduction
my $CUBESCALE_PER_UNIT = 100 / 1000;

my @Light_position = ( $CUBE_SIZE, $CUBE_SIZE, $CUBE_SIZE, 1.0 ); #Default
my @LIGHT_AMBIENT  = ( 0.1, 0.1, 0.1, 1.0 );
my @LIGHT_DIFFUSE  = ( 1.0, 1.0, 1.0, 1.0 );

my @CUBE_COLOR = (1.0, 1.0, 1.0, 1.0);

my @SPHERE_DETAILE = 10;

my @SUS_AGENT_COLOR = (0.0, 1.0, 1.0, 1.0);
my @SUS_RANGE_COLOR = (0.0, 0.0, 1.0, 0.5);
my @INF_AGENT_COLOR = (1.0, 1.0, 0.0, 1.0);
my @INF_RANGE_COLOR = (1.0, 1.0, 0.0, 0.5);
my @WAIT_RANGE_COLOR = (0.3, 0.3, 0.3, 0.5);


# unit-to-cubescale conversion
sub unit2cubescale {
    return $_[0] * $CUBESCALE_PER_UNIT;
}

sub displayFunc {
    my ( $self, $time, $agents_ref ) = @_;
    
    # Light Setting --------------------
    glLightfv_p(GL_LIGHT0, GL_POSITION, @Light_position);
    glLightfv_p(GL_LIGHT0, GL_AMBIENT,  @LIGHT_AMBIENT);
    glLightfv_p(GL_LIGHT0, GL_DIFFUSE,  @LIGHT_DIFFUSE);
    glEnable(GL_LIGHT0);

    # 3D Setting --------------------
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, $SCREEN_W, $SCREEN_H);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective($SCALING, $SCREEN_W / $SCREEN_H, 1.0, 500.0); # Scaling
    glMatrixMode(GL_MODELVIEW);

    # magnification for OpenGL --------------------
    my $magx=$self->{cube_w}/$CUBE_SIZE;
    my $magy=$self->{cube_h}/$CUBE_SIZE;
    my $magz=$self->{cube_d}/$CUBE_SIZE;
    
    # Cube --------------------
    glLoadIdentity();
    # camera
    gluLookAt(150.0, 100.0, -200.0,
    	      0.0, 0.0, 0.0,
    	      0.0, 1.0, 0.0);
    glScalef($magx ,$magy, $magz);
    glMaterialfv_p(GL_FRONT, GL_DIFFUSE, @CUBE_COLOR);
    glutWireCube($CUBE_SIZE);


    # agents --------------------
    for my $agent (@$agents_ref) {
	
	my $range=unit2cubescale( $agent->{range} );
	
	# agent color --------------------
	my @agent_color
            = defined $agent->received->{1}
            ? @INF_AGENT_COLOR
            : @SUS_AGENT_COLOR;
        if ( $agent->mobility->wait > 0 ){
	    $agent_color[0] -= 0.3;
	    $agent_color[1] -= 0.3;
	    $agent_color[2] -= 0.3;
	}

	# range color --------------------
        my @range_color
            = defined $agent->received->{1}
            ? @INF_RANGE_COLOR
            : @SUS_RANGE_COLOR;
	if ( $agent->mobility->wait > 0 ){
	    @range_color = @WAIT_RANGE_COLOR
	}
	
	# agent coordinate --------------------
	my $v = $agent->mobility->current;
        my ( $x, $y, $z ) = (
	    unit2cubescale($v->[0])-($self->{cube_w}/2), 
	    unit2cubescale($v->[1])-($self->{cube_h}/2), 
	    unit2cubescale($v->[2])-($self->{cube_d}/2) 
	    );
       
	# agent --------------------
	glLoadIdentity();
	# camera
    	gluLookAt(150.0, 100.0, -200.0,
    		  0.0, 0.0, 0.0,
    		  0.0, 1.0, 0.0);
	glMaterialfv_p(GL_FRONT, GL_DIFFUSE, @agent_color);
    	glTranslatef($x,$y,$z); #w,h,d
    	glutSolidSphere($AGENT_SIZE, @SPHERE_DETAILE, @SPHERE_DETAILE);
	
	# agent range --------------------
	glLoadIdentity();
	# camera
    	gluLookAt(150.0, 100.0, -200.0,
    		  0.0, 0.0, 0.0,
    		  0.0, 1.0, 0.0);
    	glMaterialfv_p(GL_FRONT, GL_DIFFUSE, @range_color);
    	glTranslatef($x,$y,$z);
    	glutSolidSphere($range, @SPHERE_DETAILE, @SPHERE_DETAILE);
    }
    glutSwapBuffers();
}


# create and initialize the object
sub new {
    my ( $class, %opts ) = @_;

    my $self = {%opts};
    bless $self, $class;

    # 2D height -> 3D depth
    $self->{cube_w} = unit2cubescale( $self->{width} );
    $self->{cube_h} = unit2cubescale( $self->{height3d} );
    $self->{cube_d} = unit2cubescale( $self->{height} ); 
    
    return $self;
}

sub open {
    my ( $self, $agents_ref ) = @_;

    $Light_position[0]=$self->cube_w;
    $Light_position[1]=$self->cube_d;
    $Light_position[2]=$self->cube_h;

    # OpenGL Initialization --------------------
    glutInit();
    glutInitWindowSize($SCREEN_W , $SCREEN_H);
    glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);
    glutCreateWindow("DTN simulation");
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glEnable(GL_BLEND);
    glEnable(GL_LIGHTING);

}
sub display {
    my ( $self, $time, $agents_ref ) = @_;
    
    displayFunc($self, $time, $agents_ref);
    glutMainLoopEvent();
    
}

sub close {
    my ( $self, $agents_ref ) = @_;

}

1;
