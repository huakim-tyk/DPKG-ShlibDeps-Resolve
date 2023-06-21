package DPKG::ShlibDeps::Resolve;
no warnings 'deprecated';
use DPKG::Parse::Info
use Dpkg::Shlibs::Objdump;
use Dpkg::Shlibs qw(find_library);
use Algorithm::Loops qw(NestedLoops);
use List::Util qw(sum);
use File::Spec;
use File::Find;

=head1 NAME

DPKG::ShlibDeps::Resolve - Library for resolving debian shared library
dependencies

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

A little code snippet.

    use DPKG::ShlibDeps::Resolve qw (find_libraries find_missed_libraries scan_shared_lib)
    use DPKG::Parse::Info;

    my $foo1 = find_libraries(['/bin/bash']);
    
    my $foo2 = find_missed_libraries($foo2, ['/mount']);
    
    my $info = DPKG::Parse::Info->new();
    $info->parse();
    
    my $foo3 = find_missed_libraries($info, ['/bin/bash'], ['/mount']);
    ...

=head1 EXPORT

find_libraries 
find_missed_libraries 
scan_shared_lib

=head1 SUBROUTINES/METHODS


=item find_libraries ( I<paths>, [I<dict>])

find libraries needed by objects from I<paths>
I<paths> can be array or single object of filenames or instances
of Dpkg::Shlibs::Objdump::Object

I<dict> is optional, indicates an hash which will be returned

return hash with needed libraries
=cut


use Exporter 'import';
our @EXPORT_OK = qw(find_libraries find_missed_libraries scan_shared_lib);

sub find_libraries{
    
    my $obj = shift;
    my $hsh = shift || {};
    
    if (defined $obj) {
        my @vars;
    
        if (ref($obj) eq 'ARRAY'){
            @vars=@$obj;
            goto singleloop2;
        }
        
        while (defined $obj){
            my @objs = ();
            
            if (!$obj->isa('Dpkg::Shlibs::Objdump::Object')){
                my $file = "$obj";
                if (-e $file){
                    find(sub {
                        if ( -f $_ && defined 
                            Dpkg::Shlibs::Objdump::get_format($_)) {
                            $_ = Dpkg::Shlibs::Objdump::Object->new($_);
                            if ($_ && $_->{exec_abi}){
                                push @objs, $_;
                            }
                        }
                    }, $file);
                    goto singleloop;
                };
            } 
            
            while (defined $obj){
                my @names = $obj->get_needed_libraries;
                my $abi = $obj->{exec_abi};
                for my $name (@names) {
                    if (! defined $hsh->{$name}){
                        $hsh->{$name} = 
                            [find_library($name, [], $abi, '')];
                    }
                }
                    
                singleloop:
                $obj = shift @objs;
            }
            singleloop2:
            $obj = shift @vars;
        }
    }
    return $hsh;
}

=item find_missed_libraries ( I<paths>, [I<dict>])

find missed libraries needed by objects from I<paths>
I<paths> can be array or single object of filenames or instances
of Dpkg::Shlibs::Objdump::Object

I<dir> is an pathes where libraries are located

return hash with missed libraries
=cut


sub find_missed_libraries {
    no warnings;
    my $var = shift;
    my $dir = shift;
    if (defined $dir){
        while (my ($key, $value) = each(%$var)){
            my $list = [NestedLoops([$dir, $value], sub {
                return (-e File::Spec->catfile(@_))
            })];
            
            if (sum(@$list)){
                delete $var->{$key};
            }
        }
    }
    return $var;
}




=item resolve_shlibs ( I<dpkginfo>, I<path> )

Scans dpkg file lists for files, whose needed by shared library.
Returns a (possibly empty) list of packages containing needed libraries.

=cut

sub scan_shared_lib
{
    my ( $class, $path, $extra) = @_;

    my $s = Set::Scalar->new;
    
    my $libs = find_libraries($path);
    
    if (defined $extra){
        $libs = find_missed_libraries($libs, $extra);
    }
    
    for (values %$libs){
        $s->insert(@$_);
    }
    
    return $class->scan_full_paths($s);
}

1;

=head1 AUTHOR

huakim-tyk, C<< <fijik19 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dpkg-shlibdeps-resolve at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=DPKG-ShlibDeps-Resolve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DPKG::ShlibDeps::Resolve


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DPKG-ShlibDeps-Resolve>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/DPKG-ShlibDeps-Resolve>

=item * Search CPAN

L<https://metacpan.org/release/DPKG-ShlibDeps-Resolve>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by huakim-tyk.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of DPKG::ShlibDeps::Resolve
