use strict;
use warnings;
use lib '.';
use HtmlEditor;

my $ed = HtmlEditor->new();
$ed->show_all;
Gtk2->main;