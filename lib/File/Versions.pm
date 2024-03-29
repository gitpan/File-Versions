=head1 NAME

File::Versions - Emacs-like versioned file names

=head1 SYNOPSIS

    use File::Versions 'make_backup';
    my $backup = make_backup ('file');
    # If the environment variable 'VERSION_CONTROL' is set to
    # 'numbered', 'file' is moved to 'file.~1~'. The value of the new
    # file name is put into '$backup'.

=head1 DESCRIPTION

This module duplicates the behaviour of programs like the Emacs text
editor under Unix, where the environment variables C<VERSION_CONTROL>
and C<SIMPLE_VERSION_CONTROL> allow one to make numbered backups of a
file.

=cut

package File::Versions;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/backup_name make_backup/;
use warnings;
use strict;
use Carp;
use List::Util qw/max/;

our $VERSION = 0.07;

# Get the type of version control. Not exported.

sub get_version_control
{
    return $ENV{VERSION_CONTROL};
}

sub get_file_max_version_number
{
    my ($file, $options) = @_;

    # The list of files which look like backups of this file.

    my @backup_files;

    # The version numbers of the files.

    my @version_numbers;

    # Get a list of candidate files using "glob".

    @backup_files = <$file.~*~>;

    for my $backup_file (@backup_files) {
        if ($backup_file =~ /^$file.~(\d+)~$/) {
            my $version_number = $1;
            push @version_numbers, $version_number;
        }
    }
    my $max;
    if (@version_numbers) {
        $max = max @version_numbers;
    }
    return $max;
}

# Look at the files in the current directory and find the next
# possible file. Not exported.

sub find_next_numbered
{
    my ($file, $options) = @_;

    my $max_version_number = get_file_max_version_number ($file, $options);
    my $next = 1;
    if ($max_version_number) {
        $next = $max_version_number + 1;
    }
    my $next_file = "$file.~$next~";

    # Test that this file really does not exist.

    if (-f $next_file) {
        die "There is a bug in this program. A file exists which is not supposed to.";
    }
    return $next_file;
}

# Find out what to use for the value of the suffix for simple backups.

sub simple_backup_suffix
{
    my $suffix;
    $suffix = $ENV{SIMPLE_BACKUP_SUFFIX};
    if (! $suffix) {
        $suffix = '~';
    }
    return $suffix;
}

# Make a simple backup of the file, copy it to a file with the same
# name plus the extension '~' or the value of SIMPLE_BACKUP_SUFFIX.

sub simple_backup
{
    my ($file, $options) = @_;
    my $suffix = simple_backup_suffix ($options);
    my $backup = "$file$suffix";
    return $backup;
}

# Make numbered backups of files that already have them, otherwise
# simple backups.

sub default_backup
{
    my ($file, $options) = @_;
    my $backup;
    my $max_version_number = get_file_max_version_number ($file, $options);
    if ($max_version_number) {
        $backup = find_next_numbered ($file, $options);
    }
    else {
        $backup = simple_backup ($file, $options);
    }
}


=head2 backup_name

     my $backup = backup_name ('file');

=cut

sub backup_name
{
    my ($file, $options) = @_;

    my $backup_file;

    if (! -f $file) {
        $backup_file = $file;
    }
    else {
        my $version_control = get_version_control ($options);

        if (! $version_control ||
            $version_control eq 'existing' ||
            $version_control eq 'nil') {
            $backup_file = default_backup
        }
        if ($version_control eq 'numbered' ||
            $version_control eq 't') {
            $backup_file = find_next_numbered ($file, $options);
        }
        elsif ($version_control eq 'simple' ||
               $version_control eq 'never') {
            $backup_file = simple_backup ($file, $options);
        }
        else {
            croak __PACKAGE__, ": I don't know how to do the type of version control '$version_control' in your environment.\n";
        }
    }
    return $backup_file;
}

=head2 make_backup

     make_backup ($file);

Make a backup of the file specified by C<$file>. 

This subroutine dies on error. If it succeeds, the return value is the
name of the backup file.

=cut

sub make_backup
{
    my ($file, $options) = @_;
    if (! -f $file) {
        croak "Asked to make a backup of a file '$file' which does not exist";
    }
    my $backup_file = backup_name ($file);
    if (-f $backup_file) {
        unlink $backup_file or croak "unlink $backup_file failed: $!";
    }
    rename $file, $backup_file or croak "rename $file, $backup_file failed: $!";
    return $backup_file;
}

1;

=head2 SEE ALSO

There is something similar to this module in the source code of the
"rename" utility which comes with Perl.

=cut

=head1 AUTHOR

Ben Bullock, bkb@cpan.org

=head1 COPYRIGHT & LICENCE

Copyright (c) 2010, 2013, 2014 Ben Bullock 

You can use, modify and redistribute this software library under the
standard Perl licences (Gnu General Public Licence or Artistic
licence).

=cut

