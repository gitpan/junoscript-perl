#
# $Id: Database.pm,v 1.5 2001/06/29 14:40:15 cynthia Exp $
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


# This is the device database for JUNOScript hosts, giving us access
# methods and login information to reachability to a network of JUNOS
# systems.
#

package JUNOS::Device::Database;

use strict;
use XML::DOM;
use JUNOS::Trace;
use vars qw($VERSION @ISA @EXPORT $database_file);

@ISA = qw(Exporter);
@EXPORT = qw(getAllDevices);

$database_file = "devices.xml";

sub open_file
{
    my($self, $file) = @_;

    my $parser = $self->{DOM_Parser};
    $file = $database_file unless $file;
    my $doc = $parser->parsefile ($file);
    $self->{DOM_Document} = $doc;
}

sub new
{
    my($class, %args) = @_;
    my $self = {};

    bless $self, $class;

    my $parser = new XML::DOM::Parser;
    $self->{DOM_Parser} = $parser;

    $self->open_file($args{filename}) if $args{filename};

    return $self;
}

sub getAllDevices
{
    my($self) = @_;
    my $doc = $self->{DOM_Document};

    my $nodes = $doc->getElementsByTagName("device-list", 0);
    my $node = $nodes->item(0);

    my $devices = $node->getElementsByTagName("device", 0);

    print "getAllDevices: ", $devices->getLength(), "\n";

    for my $dev (@$devices) {
	print $dev, " -> ", $dev->getNodeName, "\n";
	print "    ", $dev->getTagName, "\n";
	my $kids = $dev->getChildNodes;
	print "    children: ", $#$kids, "\n";
	for my $kid (@$kids) {
	    print "      ", $kid->getNodeTypeName, "\n";
	    if ($kid->isElementNode) {
		print "        ", $kid->getNodeName, "\n";
		my $gk = $kid->getChildNodes;
		for my $baby (@$gk) {
		    print "          ", $baby->getNodeTypeName, "\n";
		    print "            ", $baby->getData, "\n"
			if $baby->getNodeType == TEXT_NODE;
		}
	    }
	}
    }

    wantarray ? @{ $devices } : $devices;
}

sub getDevices
{
    my($self, $match) = @_;
    my $doc = $self->{DOM_Document};
    my @hosts;
    my $hosts = {};

    my $nodes = $doc->getElementsByTagName("device-list", 0);
    my $node = $nodes->item(0);

    my $devices = $node->getElementsByTagName("device", 0);

    trace("DDB", "getAllDevices: ", $devices->getLength());

    tracept("DDB");

    for my $dev (@$devices) {
	my $host = {};

	for my $kid ($dev->getChildNodes) {
	    next unless $kid->isElementNode;

	    my $name = $kid->getNodeName;
	    $name =~ s/-/_/g;

	    my $val;
	    for my $baby ($kid->getChildNodes) {
		$val .= $baby->getData if $baby->getNodeType == TEXT_NODE;
	    }

	    trace("DDB", "JUNOS::Device::Database: $name -> $val");
	    $host->{ $name } = $val;
	}

	my $hostname = $host->{hostname};
	next unless $hostname;
	next if $match and not $hostname =~ /^$match$/;

	if (wantarray) {
	    push(@hosts, $host);
	} else {
	    $hosts->{ $hostname } = $host;
	}
    }

    tracept("DDB");

    wantarray ? @hosts : $hosts;
}

1;

__END__

=head1 NAME

JUNOS::Device::Database - A perl module for maintaining databases
of JUNOScript hosts

=head1 SYNOPSIS

use JUNOS::Device::Database;

$ddb = new JUNOS::Device::Database(filename => $path_to_db);
@all = $ddb->getDevices();
for my $host (@all) {
    for my $key (keys(%$host)) {
	print $key, " --> ", $host->{$key}, "\n";
    }
}

$all = $ddb->getDevices();

$login = $all->{$my_host_name}->{login};

=head1 DESCRIPTION

This is all a very lame attempt at making a host database. More later.....

=cut
