#
# $Id: Transform.pm,v 1.5 2001/06/29 14:40:14 cynthia Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, Juniper Networks, Inc.  
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#


package JUNOS::Transform;

use strict;
use XML::DOM;
use JUNOS::Trace;

sub simple
{
    my(%args) = @_;

    my $top = $args{DOM};
    my $mapping = $args{Mapping};
    my $flush = $args{Flush};

    my @ancestors;
    my ($point, $last, $mark, $next);
    my $data = {};

    tracept("Transform");

    thing: for ($mark = $top; $mark; $mark = $next) {

	my $type = $mark->getNodeType;

	trace("Noise", " " x ($#ancestors + 1), $mark->getNodeName,
	    "::", $mark->getNodeValue);

	if ($type == ELEMENT_NODE) {
	    my $name = $mark->getNodeName;
	    $name = $mapping->{$name} || $name;
	    my $oname = $name;
	    $name =~ s/-/_/g;

	    my $text;
	    my $val;

	    for my $kid ($mark->getChildNodes) {
		next unless $kid->getNodeType == TEXT_NODE;
		$val = $kid->getData;
		next if $val =~ /^[\n\s]*$/s;
		$text .= $val;
	    }

	    if (defined($data->{$name}) || $flush->{$oname}) {
		trace("Noise", "calling callback during");
		&{$args{Callback}}($data);
	    }

	    $text =~ s/^\n+//m;
	    $text =~ s/\n+$//m;

	    $text = $name unless defined $text;
	    trace("Transform", "$name --> $text");
	    $data->{$name} = $text;

	} elsif ($type == ATTRIBUTE_NODE) {

	} elsif ($type == TEXT_NODE) {

	}

	for ($next = $mark->getFirstChild; $next;
	     	$next = $next->getNextSibling) {
	    
	    next if $next->getNodeType == TEXT_NODE;

	    push(@ancestors, $mark);
	    next thing;
	}

	for (;;) {
	    $next = $mark->getNextSibling;
	    next thing if $next;

	    $mark = pop(@ancestors);
	    $next = undef, last unless $mark;

	    if ($flush->{$mark->getNodeName}) {
		trace("Noise", "calling callback flush");
		&{$args{Callback}}($data);
	    }
	}
    }

    trace("Noise", "calling callback after");
    &{$args{Callback}}($data);
}

1;
