#
# $Id: Constants.pm,v 1.4 2001/06/29 14:40:15 cynthia Exp $
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
# These packages should probably be 'XML::TIX::Constants'
#

package JUNOS::TIX::Constants;

use strict;
use Carp;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $debug);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(Keyed Key Attrs Order Name dbgpr $debug);
%EXPORT_TAGS = (base => [ @EXPORT_OK ]);

$debug = 1;

#
# Constants
#  These strings are not valid tag names and are used as hash indices to
#  stuff additional information into node hashes.
#
sub Keyed () { "__Element Keyed__" }
sub Key   () { "key" }
sub Attrs () { "__Element Attributes__" }
sub Order () { "__Element Order__" }
sub Name  () { "__Element Name__" }

sub dbgpr
{
    print "DEBUG:: ", join(" ", @_), "\n";
}

1;
