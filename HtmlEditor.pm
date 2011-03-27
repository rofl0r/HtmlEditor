package HtmlEditor;

#example text editor
# Ryan Paul (SegPhault) - 07/12/2009
# http://arstechnica.com/open-source/guides/2009/07/how-to-build-a-desktop-wysiwyg-editor-with-webkit-and-html-5.ars

# converted to perl by rofl0r
# with a little help from http://cpansearch.perl.org/src/GRANTM/App-USBKeyCopyCon-1.02/lib/App/USBKeyCopyCon.pm

use strict;
use warnings;
use Gtk2 -init;
use Gtk2::WebKit;
use File::Slurp;

our @ISA = qw(Gtk2::Window);

sub new {
	my ($pkg) = @_;
	my $self = $pkg->SUPER::new();
	$self->set_title("Example Editor");
	$self->signal_connect(destroy => sub {Gtk2->main_quit; });
	$self->resize(600,600);
	$self->{filename} = undef;
	$self->{editor} = Gtk2::WebKit::WebView->new;
	$self->{editor}->set_editable(1);
	$self->{editor}->load_html_string("this is a test.", "file:///");
	$self->{scroll} = Gtk2::ScrolledWindow->new();
	$self->{scroll}->add($self->{editor});
	$self->{scroll}->set_policy('automatic','automatic');	

	bless $self, $pkg;
	$self->{ui} = $self->generate_ui();
	$self->add_accel_group($self->{ui}->get_accel_group());
	$self->{toolbar1} = $self->{ui}->get_widget("/toolbar_main");
	$self->{toolbar2} = $self->{ui}->get_widget("/toolbar_format");
	$self->{menubar} = $self->{ui}->get_widget("/menubar_main");

	$self->{layout} = Gtk2::VBox->new();
	$self->{layout}->pack_start($self->{menubar}, 0, 0, 0);
	$self->{layout}->pack_start($self->{toolbar1}, 0, 0, 0);
	$self->{layout}->pack_start($self->{toolbar2}, 0, 0, 0);
	$self->{layout}->pack_start($self->{scroll}, 1, 1, 0);
	$self->add($self->{layout});

	return $self;
}

sub generate_ui {
	my ($self) = @_;
	my $ui_def = <<'UI';
	<ui> 
	<menubar name="menubar_main"> 
		<menu action="menuFile"> 
		<menuitem action="new" /> 
		<menuitem action="open" /> 
		<menuitem action="save" /> 
		</menu> 
		<menu action="menuEdit"> 
		<menuitem action="cut" /> 
		<menuitem action="copy" /> 
		<menuitem action="paste" /> 
		</menu> 
		<menu action="menuInsert"> 
		<menuitem action="insertimage" /> 
		<menuitem action="insertvideo" /> 
		</menu> 
		<menu action="menuFormat"> 
		<menuitem action="bold" /> 
		<menuitem action="italic" /> 
		<menuitem action="underline" /> 
		<menuitem action="strikethrough" /> 
		<separator /> 
		<menuitem action="font" /> 
		<menuitem action="color" /> 
		<separator /> 
		<menuitem action="justifyleft" /> 
		<menuitem action="justifyright" /> 
		<menuitem action="justifycenter" /> 
		<menuitem action="justifyfull" /> 
		</menu> 
	</menubar> 
	<toolbar name="toolbar_main"> 
		<toolitem action="new" /> 
		<toolitem action="open" /> 
		<toolitem action="save" /> 
		<separator /> 
		<toolitem action="undo" /> 
		<toolitem action="redo" /> 
		<separator /> 
		<toolitem action="cut" /> 
		<toolitem action="copy" /> 
		<toolitem action="paste" /> 
	</toolbar> 
	<toolbar name="toolbar_format"> 
		<toolitem action="bold" /> 
		<toolitem action="italic" /> 
		<toolitem action="underline" /> 
		<toolitem action="strikethrough" /> 
		<separator /> 
		<toolitem action="font" /> 
		<toolitem action="color" /> 
		<separator /> 
		<toolitem action="justifyleft" /> 
		<toolitem action="justifyright" /> 
		<toolitem action="justifycenter" /> 
		<toolitem action="justifyfull" /> 
		<separator /> 
		<toolitem action="insertimage" /> 
		<toolitem action="insertvideo" /> 
		<toolitem action="insertlink" /> 
	</toolbar> 
	</ui> 
UI
	my $actions = Gtk2::ActionGroup->new("Actions");	

	my @menu_entries = (
		# name,       stock id,          label
		["menuFile", undef, "_File"],
		["menuEdit", undef, "_Edit"],
		["menuInsert", undef, "_Insert"],
		["menuFormat", undef, "_Format"],
		# name,       stock id,          label,               accelerator,  tooltip,                  action
		["new", "gtk-new", "_New", undef, undef, "new"],
		["open", "gtk-open", "_Open", undef, undef, "open"],
		["save", "gtk-save", "_Save", undef, undef, "save"],

		["undo", "gtk-undo", "_Undo", undef, undef, "action"],
		["redo", "gtk-redo", "_Redo", undef, undef, "action"],

		["cut", "gtk-cut", "_Cut", undef, undef, "action"],
		["copy", "gtk-copy", "_Copy", undef, undef, "action"],
		["paste", "gtk-paste", "_Paste", undef, undef, "paste"],

		["bold", "gtk-bold", "_Bold", "<ctrl>B", undef, "action"],
		["italic", "gtk-italic", "_Italic", "<ctrl>I", undef, "action"],
		["underline", "gtk-underline", "_Underline", "<ctrl>U", undef, "action"],
		["strikethrough", "gtk-strikethrough", "_Strike", "<ctrl>T", undef, "action"],
		["font", "gtk-select-font", "Select _Font", "<ctrl>F", undef, "select_font"],
		["color", "gtk-select-color", "Select _Color", undef, undef, "select_color"],

		["justifyleft", "gtk-justify-left", "Justify _Left", undef, undef, "action"],
		["justifyright", "gtk-justify-right", "Justify _Right", undef, undef, "action"],
		["justifycenter", "gtk-justify-center", "Justify _Center", undef, undef, "action"],
		["justifyfull", "gtk-justify-fill", "Justify _Full", undef, undef, "action"],

		["insertimage", "insert-image", "Insert _Image", undef, undef, "insert_image"],
		["insertvideo", "insert-video", "Insert _Video", undef, undef, "insert_video"],
		["insertlink", "insert-link", "Insert _Link", undef, undef, "insert_link"]
	);

	foreach my $item (@menu_entries) {
		if(exists $item->[5]) {
			my $action = 'on_' . $item->[5];
			$item->[5] = sub { $self->$action(@_) };
		}
	}

	$actions->add_actions(\@menu_entries, undef);
	$actions->get_action("insertimage")->set_property("icon-name", "insert-image");
	$actions->get_action("insertvideo")->set_property("icon-name", "insert-object");
	$actions->get_action("insertlink")->set_property("icon-name", "insert-link");

	my $ui = Gtk2::UIManager->new;
	$ui->insert_action_group($actions, 0);
	$ui->add_ui_from_string ($ui_def);
	return $ui;
}

sub on_action {
	my($self, $action) = @_;
	my $cmd = sprintf("document.execCommand('%s', false, false);", $action->get_name());
	$self->{editor}->execute_script($cmd);
}

sub on_paste {
	my($self, $action) = @_;
	$self->{editor}->paste_clipboard();
}

sub on_new {
	my($self, $action) = @_;
	$self->{editor}->load_html_string("", "file:///"); 
}

sub on_select_font {
	my($self, $action) = @_;
	my $dialog = Gtk2::FontSelectionDialog->new("Select a font");
	if ($dialog->run() eq "ok") {
		my $font = $dialog->get_font_name();
		my $fd = Pango::FontDescription->from_string($font);
		my $fname = $fd->get_family();
		my $fsize = $fd->get_size();
		my $cmd = sprintf("document.execCommand('fontname', null, '%s');", $fname);
		$self->{editor}->execute_script($cmd);
		$cmd = sprintf("document.execCommand('fontsize', null, '%s');", $fsize);
		$self->{editor}->execute_script($cmd);
	}
	$dialog->destroy();
}

sub on_select_color {
	my($self, $action) = @_;
	my $dialog = Gtk2::ColorSelectionDialog->new("Select Color");
	if ($dialog->run() eq "ok") {
		my $gc = $dialog->colorsel->get_current_color();
		my $color = sprintf("#%02x%02x%02x", $gc->red % 256, $gc->green % 256 , $gc->blue % 256);
		my $cmd = sprintf("document.execCommand('forecolor', null, '%s');", $color);
		$self->{editor}->execute_script($cmd);
	}
	$dialog->destroy();
}

sub on_insert_link {
	my($self, $action) = @_;
	my $dialog = Gtk2::Dialog->new("Enter a URL:", $self, [qw(modal destroy-with-parent)],
		"gtk-cancel" => 'cancel', "gtk-ok" => 'ok');
	my $entry = Gtk2::Entry->new();
	$dialog->vbox->pack_start($entry,0,0,0);
	$dialog->show_all();
	if ($dialog->run() eq "ok") {
		my $cmd = sprintf("document.execCommand('createLink', true, '%s');", $entry->get_text());
		$self->{editor}->execute_script($cmd);
	}
	$dialog->destroy();
}

sub on_insert_image {
	my($self, $action) = @_;
	my $dialog = Gtk2::FileChooserDialog->new("Select an image file", $self, 'open',
		"gtk-cancel" => 'cancel', "gtk-open" => 'ok');
	if ($dialog->run() eq "ok") {
		my $fn = $dialog->get_filename();
		if (-e $fn) {
			my $cmd = sprintf("document.execCommand('insertImage', null, '%s');", $fn);
			$self->{editor}->execute_script($cmd);
		}
	}
	$dialog->destroy();
}

sub on_insert_video {
	my($self, $action) = @_;
}

sub on_open {
	my($self, $action) = @_;
	my $dialog = Gtk2::FileChooserDialog->new("Select a HTML file", $self, 'open',
		"gtk-cancel" => 'cancel', "gtk-open" => 'ok');
	if ($dialog->run() eq "ok") {
		my $fn = $dialog->get_filename();
		if (-e $fn) {
			$self->{filename} = $fn;
			$self->{editor}->load_html_string(read_file($fn), "file:///");
		}
	}
	$dialog->destroy();
}

sub on_save {
	my($self, $action) = @_;
	if(defined($self->{filename})) {
		write_file($self->{filename}, $self->get_html());
	} else {
		my $dialog = Gtk2::FileChooserDialog->new("Select a HTML file", $self, 'save',
			"gtk-cancel" => 'cancel', "gtk-save" => 'ok');
		if($dialog->run() eq "ok") {
			$self->{filename} = $dialog->get_filename();
			write_file($self->{filename}, $self->get_html());
		}
		$dialog->destroy();
	}
}

sub get_html {
	my($self) = @_;
	$self->{editor}->execute_script("oldtitle=document.title;document.title=document.documentElement.innerHTML;");
	my $html = $self->{editor}->get_main_frame()->get_title();
	$self->{editor}->execute_script("document.title=oldtitle;");
	return $html;
}
