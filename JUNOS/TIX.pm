#
# $Id: TIX.pm,v 1.4 2001/06/29 14:40:14 cynthia Exp $
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


#
# This file implements a set of packages that constitute 'TIX', the
# Trivial Interface to XML. This is a truely simple, perl-based API
# to allow natural language constructs to access XML data sets.
#
# These packages should probably be 'XML::TIX'
#

#BEGIN { $Exporter::Verbose = 1; }

package JUNOS::TIX::Node;

use strict;

use JUNOS::TIX::Constants qw(:base);

sub new
{
    my($class, $tag) = @_;
    my $self = {};

    $self->{&Order} = [];
    $self->{&Name} = $tag;

    $class = ref($class) || $class;
    bless $self, $class;
}

sub dump
{
    my($self, $indent) = @_;
    my $order = $self->{&Order};

     dbgpr($indent, "DUMP::Node: $self ->", $self->{&Name});
     for (my $i = 0; $i <= $#{$order}; $i++) {
	 my $xx = ${$order}[ $i ];
	 if (ref $xx) {
	     $xx->dump($indent . "  ");
	 } else {
	     dbgpr($indent, "DUMP::data $xx ->", $self->{$xx}) if $debug;
	 }
     }
}

#
# ----------------------------------------------------------------------
#

package JUNOS::TIX;

use strict;
use JUNOS::TIX::Constants qw(:base);

sub new
{
    my($class, $name) = @_;
    my $self = {};

    $class = ref($class) || $class;
    bless $self, $class;

    # The stack is an array of open objects
    $self->{Stack} = [];

    # Root is the top of the tree; Current is the current node
    my $cur = new JUNOS::TIX::Node($name);
    $self->{Root} = $self->{Current} = $cur;

    # Name is a user defined tag used by the caller/creator
    $self->{Name} = $name;

    # Last is the name of the last tag received
    $self->{Last} = $name;

    dbgpr("TIX::new: made ${name}") if $debug;

    return $self;
}

sub data
{
    my($self, $data) = @_;
    my $cur = $self->{Current};
    my $tmp = $self->{Tmp};
    my $last = $self->{Last};

    $self->dump(1, "before data") if $debug;

    dbgpr("TIX::data: $cur -> $last -> $data") if $debug;

    if ($tmp) {
	# tmp being set clues us in to this being a keyed object under
	# construction. We finish construction by moving the tmp object
	# under the right parent and filling in the key value.
	dbgpr("TIX::data: tmp $tmp") if $debug;

	$cur->{$data} = $tmp;
	$tmp->{$last} = $data;

	# Now we toss the old parent object onto the stack.
	push @{$self->{Stack}}, $cur;

	# Add the new (tmp) object to the parent order listing
	push @{$cur->{&Order}}, $last;

	# Save the new (tmp) object as the current node
	$self->{Current} = $tmp;

    } elsif (not defined $cur->{$last}) {
	dbgpr("TIX::data: new data") if $debug;
	$cur->{$last} = $data;
	push @{$cur->{&Order}}, $last;

    } elsif (tag_match($cur->{&Order}, $last)) {
	# If we are under the same tag name, just append the data
	dbgpr("TIX::data: appending data") if $debug;

	$cur->{$last} .= $data;

    } else {
	dbgpr("TIX::data: dead data") if $debug;

	# XXX This is _not_ the right code for this spot. We should
	# be making a new tag and inserting this data under it.
	$cur->{$last} .= $data;
    }

    $self->dump(1, "after data") if $debug;
}

sub open
{
    my($self, $tag, @attrs) = @_;

    $self->dump(1, "before open") if $debug;

    # If tmp is set, something is very very wrong....
    die "tmp defined: ", $self->{Tmp}->{&Name} if $self->{Tmp};

    # Pull some fields out of $self into local variables.
    my $cur = $self->{Current};
    my $last = $self->{Last};
    my $new_tag = $last;

    # Turn the (name,value) array into an associative one
    my %attrs = @attrs;

    dbgpr("TIX::open: open $cur -> $last -> $tag ",
	  $attrs{Key} ? "(key=" . $attrs{Key} . ")" : "") if $debug;

    if ($attrs{Key}) {
	# This is a keyed object so we cannot create the real object yet.
	# We make a temporary one (Tmp) and insert it into the tree
	# when we get the data content.
	dbgpr("TIX::open: open $cur -> $last -> $tag") if $debug;
	
	$self->{Tmp} = new JUNOS::TIX::Node($last);
	$self->{Last} = $tag;
	$self->{Tmp}->{&Attrs} = %attrs;
	return $self;

    } elsif ($cur->{$last}) {
	# The current tag already exists and we do not want to clobber
	# the current data. So we fake up a new tag in an illegal form
	# that the data cannot contain.
	for (my $i = 0; not $cur->{$new_tag}; $i++) {
	    $new_tag = "$last #$i";
	}

	dbgpr("TIX::open: building new tag $last -> $new_tag") if $debug;
    }

    my $new = new JUNOS::TIX::Node($last);
    $self->{Current} = $new;
    $cur->{$new_tag} = $new;
    $new->{&Attrs} = %attrs;
    push @{$cur->{&Order}}, $new;
    push @{$self->{Stack}}, $cur;
    $self->{Last} = $tag;

    $self->dump(1, "after open") if $debug;
}

sub close
{
    my($self, $tag) = @_;

    $self->dump(1, "before close") if $debug;

    die "tmp defined: ", $self->{Tmp}->{&Name} if $self->{Tmp};

    $self->{Current} = pop @{$self->{Stack}};
    $self->{Last} = $self->{Current}->{&Name};
    $self->dump(1, "after close") if $debug;
}

sub dump
{
    my($self, $full, $tag) = @_;

    dbgpr "DUMP:: $tag TIX object $self";

    dbgpr "DUMP:: Name", $self->{Name};
    dbgpr "DUMP:: Root", $self->{Root}, "->", $self->{Root}->{&Name};
    dbgpr "DUMP:: Current", $self->{Current},
	       "->", $self->{Current}->{&Name};
    dbgpr "DUMP:: Last", $self->{Last} if $self->{Last};
    dbgpr "DUMP:: Tmp", $self->{Tmp} if $self->{Tmp};

    dbgpr "DUMP:: Stack depth is", $#{$self->{Stack}};
    if ($full) {
	for (my $i = 0; $i <= $#{$self->{Stack}}; $i++) {
	    my $xx = $self->{Stack}->[ $i ];
	    dbgpr "DUMP:: Stack", $i, $xx, "->", $xx->{&Name};
	}
    }

    if ($full > 1) {
	$self->{Root}->dump();
    }
}

# ----------------------------------------------------------------------
#
# Define a subparser for XML::Parser. We register it as a valid
# subparser, and define the methods that will be called by the
# XML::Parser functions. The '$self' that we get will be the
# instance of XML::Parser (or some underlaying class). We hang
# an instance of our JUNOS_TIX class off the parser.
#

package XML::Parser::JUNOS_TIX;
$XML::Parser::Built_In_Styles{JUNOS_TIX} = 1;

sub Init
{
    my($parser) = @_;

    $parser->{TIX} = new JUNOS::TIX("XML (Top Level)");
}

sub Final
{
    my($parser) = @_;
    my $rc = $parser->{TIX};
    undef $parser->{TIX};
    return $rc;
}

sub XMLDecl
{
    my($parser, $version, $encoding, $standalone) = @_;

    die "Unsupported encoding ($encoding)"
	if $encoding && $encoding ne "us-ascii";

    die "Non-standalone document unsupported ($standalone)"
	if $standalone && $standalone ne "YES";
}

sub Start
{
    my($parser, $tag, @attrs) = @_;
    my $tix = $parser->{TIX};

    $tix->open($tag, @attrs);
}

sub End
{
    my($parser, $tag) = @_;
    my $tix = $parser->{TIX};

    $tix->close($tag);
}

sub Char
{
    my($parser, $data) = @_;
    my $tix = $parser->{TIX};

    $tix->data($data);
}

sub Default
{
    die;
}

my $parser = {};
Init($parser);
Start($parser, "rpc-reply");
Start($parser, "configuration");
Start($parser, "system");
Start($parser, "host-name");
Char($parser, "foo");
End($parser, "host-name");
End($parser, "system");
End($parser, "configuration");
End($parser, "rpc-reply");

my $xx = Final($parser);
print "xx $xx\n";
$xx->dump(2);

#$error->{message} = "test";
#$res->{configuration}->{system}->{login}->{user}->{phil}->{name}->{__ATTRIBUTES__}->{replace} = "replace";
#
#$test = "
#<configuration>
#  <system>
#    <host-name>foofer</host-name>
#    <login>
#      <message>testing</message>
#      <user>
#        <name key=\"key\">phil</name>
#        <class>foo</class>
#      </user>
#    </login>
#  </system>
#</configuration>
#";

1;
