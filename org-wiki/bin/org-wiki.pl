#!/usr/bin/perl
##! @description: usage
##! @version: 1
##! @author: crackcell <tanmenglong@gmail.com>
##! @date:   Sun Mar 18 11:58:27 2012

use strict;
use Getopt::Std;
use HTML::Template;
use Date::Manip;
use POSIX qw(strftime);
use File::Basename;
use File::Find::Rule;
use Storable qw(dclone);
use File::Spec;
use Loglib;
use JSON;

#--------------- global variable --------------

my @keyword_dict;

#------------------ function ------------------


##! @todo: Show help messag
sub usage {
    print("org-wiki.pl\n");
    print("Usage: -h -i -t -d -o -s\n");
    print("  -h                   : show help message\n");
    print("  -i \$org_file_folder : specify path for .org files", "\n");
    print("  -t \$template_path   : specify path for .tmpl files", "\n");
    print("  -o \$output_path     : specify path for output files", "\n");
    print("  -b \$base_url        : specify base url", "\n");
    print("  -d \$file            : keyword dict", "\n");
    print("  -s                   : launch a simple http server", "\n");
}

##! @todo: Dump a list for debug
sub dump_list {
    my $list_ref = shift;
    foreach my $item (@{$list_ref}) {
        print($item, "\n");
    }
}

##! @todo: Dump meta
##! @param: 0 => meta ptr
sub dump_post_meta {
    my $meta_ref = shift;
    print "==\n";
    print "titile: ", $meta_ref->{"title"}, "\n";
    print "raw_date", $meta_ref->{"raw_date"}, "\n";
    print "org_file: ", $meta_ref->{"org_file"}, "\n";
    print "org_html_file: ", $meta_ref->{"org_html_file"}, "\n";
    print "org_img_path: ", $meta_ref->{"org_img_path"}, "\n";
    print "org_filename: ", $meta_ref->{"org_filename"}, "\n";
    print "basename: ", $meta_ref->{"basename"}, "\n";
    print "category: ", $meta_ref->{"category"}, "\n";
    print "post_path: ", $meta_ref->{"post_path"}, "\n";
    print "post_file: ", $meta_ref->{"post_file"}, "\n";
    print "post_img_path: ", $meta_ref->{"post_img_path"}, "\n";
    print "url_path: ", $meta_ref->{"url_path"}, "\n";
    print "url: ", $meta_ref->{"url"}, "\n";
    print "abs_url: ", $meta_ref->{"abs_url"}, "\n";
    print "url_img_path: ", $meta_ref->{"url_img_path"}, "\n";
    print "keywords: ", $meta_ref->{"keywords"}, "\n";
    print "description: ", $meta_ref->{"description"}, "\n";
}

##! @todo: Dump category meta
##! @param: 0 => category meta ptr
sub dump_category_meta {
    my $category_meta_dict_ref = shift;
    print "==========category\n";
    foreach my $level (keys %{$category_meta_dict_ref}) {
        print "===", $level, "\n";
        foreach my $post_meta_ref (@{$category_meta_dict_ref->{$level}}) {
            print $post_meta_ref->{"title"}, "\t";
        }
        print "\n";
    }
}


##! @todo: Write a file
##! @param: 0 => path
##! @param: 1 => content
sub write_file {
    my $path = shift;
    my $content = shift;
    open(OUT, ">" . $path);
    print OUT $content;
    close(OUT);
    Loglib::NOTICE_LOG("generating: " . $path);
}

##! @todo: Get category info from org file path
##! @param: 0 => org file path
##! @param: 1 => ptr to meta info
sub get_category {
    my $org_path = shift;
    my $meta_ref = shift;
    $org_path =~ s/\.\///;
    $meta_ref->{"category"} =
        substr($meta_ref->{"org_file"}, length($org_path),
               length($meta_ref->{"org_file"}) - length($org_path) -
               length($meta_ref->{"org_filename"}));
}

##! @todo: Generate post meta info
##! @param: 0 => path to org files
##! @param: 1 => output path
##! @param: 2 => base url
##! @param: 3 => ptr to meta info list
sub gen_post_meta {
    my $org_path = shift;
    my $output_path = shift;
    my $base_url = shift;
    my $post_meta_list_ref = shift;

    $base_url =~ s/\/+$//g;
    my @search_dir_list = ($org_path);
    my @org_file_list;
    list_all_files(\@search_dir_list, "*.org", \@org_file_list);
    foreach my $org_file (@org_file_list) {
        my %meta = ();

        $meta{"org_file"} = $org_file;
        $meta{"org_html_file"} = $org_file;
        $meta{"org_html_file"} =~ s/\.org$/\.html/;
        $meta{"org_img_path"} = $org_file;
        $meta{"org_img_path"} =~ s/\.org$//;
        $meta{"org_filename"} = fileparse($org_file);
        my @suffix_list = (".org");
        $meta{"basename"} = basename($org_file, @suffix_list);
        get_category($org_path, \%meta);

        push(@{$post_meta_list_ref}, \%meta);
    }

    foreach my $meta_ref (@{$post_meta_list_ref}) {
#        next if not $meta_ref->{"org_file"} eq "forge/Emacs/replace-semantic-code-helper-with-popup-from-auto-complete.org";
#        print "\norg_file===> ", $meta_ref->{"org_file"}, "\n\n";

        my $title = "";
        my $date = "";
        my $content = "";
        my $keywords = "";
        my $description = "";
        if (not extract_html($meta_ref->{"org_html_file"},
                             \$title, \$date, \$content)) {

            my $year = UnixDate($date, "%Y");
            my $month = UnixDate($date, "%m");
            my $day = UnixDate($date, "%d");

            #my $post_path = "$output_path/posts/$year/$month/$day/";
            my $post_path = $output_path . "/pages/" . dirname(File::Spec->abs2rel($meta_ref->{"org_file"}, $org_path)) . "/";
            my $post_file = $post_path . $meta_ref->{"basename"} . ".html";
            my $post_img_path = $post_path . $meta_ref->{"basename"};

            my $url_path = "pages/"
                . dirname(File::Spec->abs2rel($meta_ref->{"org_file"}, $org_path))
                . "/";
            my $url = $url_path . $meta_ref->{"basename"} . ".html";
            my $abs_url = $base_url . $url;
            my $url_img_path = $url_path . $meta_ref->{"basename"} . "/";

            #extract_keywords(\$content, \$keywords);
            extract_description(\$content, \$description);
            $description = $title . " " . $description;

            $meta_ref->{"keywords"} = $keywords;
            $meta_ref->{"description"} = $description;

            $meta_ref->{"post_path"} = $post_path;
            $meta_ref->{"post_file"} = $post_file;
            $meta_ref->{"post_img_path"} = $post_img_path;

            $meta_ref->{"url_path"} = $url_path;
            $meta_ref->{"url"} = $url;
            $meta_ref->{"abs_url"} = $abs_url;
            $meta_ref->{"url_img_path"} = $url_img_path;

            $meta_ref->{"title"} = $title;
            $meta_ref->{"content"} = $content;

            $meta_ref->{"date"} = UnixDate($date, "%Y-%m-%d");
            $meta_ref->{"sort_date"} = UnixDate($date, "%Y%m%d%H%M%S");

            #dump_post_meta($meta_ref);

        }
    }

}

sub gen_attach_meta {
    my $org_path = shift;
    my $output_path = shift;
    my $attach_meta_list_ref = shift;

    my @search_dir_list = ($org_path);
    my @attach_list;
    list_all_files(\@search_dir_list, qr/.(pdf|docx|doc|xls|xlsx|txt|pptx|ppt)$/, \@attach_list);
    foreach my $attach (@attach_list) {
        my %meta = ();

        $meta{"attach_file"} = $attach;

        my @suffix_list = (".pdf");
        $meta{"basename"} = basename($attach, @suffix_list);
        $meta{"url_path"} = "pages/"
            . dirname(File::Spec->abs2rel($attach, $org_path))
            . "/";
        #print "----------", $meta{"url_path"}, "\n";
        #print "----------", $meta{"attach_file"}, "\n";

        push(@{$attach_meta_list_ref}, \%meta);
    }
}

##! @todo: Generate cateogry meta info list
##! @param: 0 => ptr to post meta info list
##! @param: 1 => ptr to category meta info dict
##! @return:
##!   0 => success
##!   1 => failure
sub gen_category_meta {
    my $post_meta_list_ref = shift;
    my $category_meta_dict_ref = shift;
    foreach my $post_meta_ref (@{$post_meta_list_ref}) {
        my @level_list = split(/\//, $post_meta_ref->{"category"});
        foreach my $level (@level_list) {
            next if length($level) == 0;
            my @post_list = ();
            my $level_post_list_ref = \@post_list;
            if (exists $category_meta_dict_ref->{$level}) {
                $level_post_list_ref = $category_meta_dict_ref->{$level};
            }
            push(@{$level_post_list_ref}, $post_meta_ref);
            $category_meta_dict_ref->{$level} = $level_post_list_ref;
        }
    }
}

sub list_all_files {
    my $dir_list_ref = shift;
    my $pattern = shift;
    my $array_ref = shift;
    @{$array_ref} = File::Find::Rule->file()->name($pattern)->in(@{$dir_list_ref});
}

##! @todo: Export org files into html
##! @param: 0 => meta info list
##! @return:
##!   0 => success
##!   1 => failure
sub export_org {
    my $meta_list_ref = shift;
    foreach my $meta_ref (@{$meta_list_ref}) {
        next if ($meta_ref->{"title"} eq "");
        export_org_file($meta_ref->{"org_file"},
                        "Menglong Tan",
                        "tanmenglong\@gmail.com");
    }
}

sub export_attach {
    my $meta_list_ref = shift;

    my $cmd;
    foreach my $meta_ref (@{$meta_list_ref}) {
        $cmd = "mkdir -p \"" . $meta_ref->{"url_path"} . "\"";
        `$cmd`;
        $cmd = "cp \"" . $meta_ref->{"attach_file"} . "\" \"" . $meta_ref->{"url_path"} . "\"";
        #Loglib::NOTICE_LOG("copying: " . $meta_ref->{"attach_file"} . " to " . $meta_ref->{"url_path"});
        `$cmd`;
    }
}

##! @todo: Export an org file to html
##! @param: 0 => org filename
##! @return:
##!   0 => success
##!   1 => failure
sub export_org_file {
    my $org_file = shift;
    my $username = shift;
    my $email = shift;

    my $html_filename = $org_file;
    $html_filename =~ s/\.org$/\.html/g;
    if (not -e $html_filename) {
        my $cmd = "emacs --batch --eval \"(progn (setq user-full-name \"$username\")(setq user-mail-address \"$email\")(find-file \"$org_file\")(org-export-as-html 3))\"";
        `$cmd`;
    }
}

sub render_tree {
    my $tree_html = shift;
    my $tmpl_file = shift;
    my $output_file = shift;

    my $tmpl = HTML::Template->new(filename => $tmpl_file);
    $tmpl->param(TREE_HTML => $tree_html);

    write_file($output_file, $tmpl->output);
}

##! @todo: Render feed
##! @param: 0 => post meta list ptr
##! @param: 1 => tmpl file
##! @param: 2 => output file
##! @return:
##!   0 => success
##!   1 => failure
sub render_feed {
    my $post_meta_list_ref = shift;
    my $tmpl_file = shift;
    my $output_file = shift;

    my @tmpl_post_list = ();
    foreach my $meta_ref (@{$post_meta_list_ref}) {
        my %tmpl_post_info = ();
        $tmpl_post_info{"title"} = $meta_ref->{"title"};
        $tmpl_post_info{"date"} = $meta_ref->{"date"};
        $tmpl_post_info{"sort_date"} = $meta_ref->{"sort_date"};
        $tmpl_post_info{"abs_url"} = $meta_ref->{"abs_url"};
        $tmpl_post_info{"content"} = $meta_ref->{"content"};
        push(@tmpl_post_list, \%tmpl_post_info);
    }

    ### sort post list
    my @feed_post_list = sort {
        $b->{"sort_date"} cmp $a->{"sort_date"};
    } @tmpl_post_list;

    foreach my $meta_ref (@feed_post_list) {
        delete($meta_ref->{"sort_date"});
    }

    my $last_build_date = strftime "%Y%m%d-%H%M\n", localtime;

    my $feed_tmpl = HTML::Template->new(filename => $tmpl_file);
    $feed_tmpl->param(
        LAST_BUILD_DATE => $last_build_date,
        POST_LIST => \@feed_post_list);
    write_file($output_file, $feed_tmpl->output);
}

sub render_tree_html {
    my $tree = shift;
    my $html = shift;
    if ($tree->{"type"} eq "cate") {
        my $expanded = "false";
        if ($tree->{"meta"}->{"fold"} == 0) {
            $expanded = "true";
        }
        ${$html} = ${$html} . "<li item-checked=\"true\" item-expanded=\"$expanded\"><a href=\"" . $tree->{"path"} . "\" target=\"content\"><b>" . $tree->{"meta"}->{"label"} . "</b></a>\n" 
            ."<ul>\n";
        my @cate_list = ();
        my @post_list = ();

        foreach my $child_name (keys %{$tree->{"children"}}) {
            my $child = $tree->{"children"}->{$child_name};
            if ($child->{"type"} eq "cate") {
                push(@cate_list, $child);
            } elsif ($child->{"type"} eq "post") {
                push(@post_list, $child);
            }
        }

        foreach my $child (@post_list) {
            render_tree_html($child, $html);
        }
        foreach my $child (@cate_list) {
            render_tree_html($child, $html);
        }

        ${$html} = ${$html} . "</ul>\n</li>\n"
    } elsif (($tree->{"type"} eq "post") && length($tree->{"data"}->{"url"}) > 1) {
        ${$html} = ${$html} . "<li><a href=\"" . $tree->{"data"}->{"url"} . "\" target=\"content\">" . $tree->{"data"}->{"title"} . "</a></li>\n";
    }
}

##! @todo: Render templates
##! @param: 0 => post meta info list
##! @param: 2 => category meta info dict
##! @param: 2 => tmpl path
##! @param: 3 => org path
##! @param: 4 => base url
##! @param: 5 => output path
##! @return:
##!   0 => success
##!   1 => failure
sub render_tmpl {
    my $post_meta_list_ref = shift;
    my $category_meta_dict_ref = shift;
    my $tree = shift;
    my $tmpl_path = shift;
    my $org_path = shift;
    my $base_url = shift;
    my $output_path = shift;

    ### 1. create templates
    my $tree_tmpl = HTML::Template->new(filename => $tmpl_path . "/tree.html");
    my $post_tmpl = HTML::Template->new(filename => $tmpl_path . "/post.html");

    $base_url =~ s/\/+$//g;
    $tmpl_path =~ s/\/+$//g;
    $output_path =~ s/\/+$//g;

    ### 2. render posts
    my $cmd = "";
    foreach my $meta_ref (@{$post_meta_list_ref}) {
        next if ($meta_ref->{"title"} eq "");

        # get img list
        my @img_list = $meta_ref->{"content"} =~ /<img src="(.*?)"/g;
        my $category = $meta_ref->{"category"};

        # mkdir for post and images
        if (scalar @img_list > 0) {
            $cmd = "mkdir -p \"" . $meta_ref->{"post_img_path"} . "\"";
            `$cmd`;
            foreach my $img (@img_list) {
                $cmd = "cp \"$org_path/$category/$img\" \"" . $meta_ref->{"post_img_path"} . "\"";
                `$cmd`;
            }
        } else {
            $cmd = "mkdir -p \"" . $meta_ref->{"post_path"} . "\"";
            `$cmd`;
        }

        #path_rel2abs($base_url, $meta_ref->{"url_img_path"},
        #             \($meta_ref->{"content"}));
        path_rel2abs($base_url, $meta_ref->{"basename"},
                     \$meta_ref->{"content"});

        $post_tmpl->param(TITLE => $meta_ref->{"title"});
        $post_tmpl->param(DATE => $meta_ref->{"raw_date"});
        $post_tmpl->param(CONTENT => $meta_ref->{"content"});

        $post_tmpl->param(KEYWORDS => $meta_ref->{"keywords"});
        $post_tmpl->param(DESCRIPTION => $meta_ref->{"description"});

        write_file($meta_ref->{"post_file"}, $post_tmpl->output);

    }

    ### TODO redner archive

    ### 3. prepare tree
    my $tree_html = "";
    foreach my $child (keys %{$tree->{"children"}}) {
        next unless ($tree->{"children"}->{$child}->{"type"} eq "cate");
        render_tree_html($tree->{"children"}->{$child}, \$tree_html);
    }
    foreach my $child (keys %{$tree->{"children"}}) {
        next unless ($tree->{"children"}->{$child}->{"type"} eq "post");
        render_tree_html($tree->{"children"}->{$child}, \$tree_html);
    }

    ### render index
    render_tree($tree_html,
                "$tmpl_path/tree.html", "$output_path/tree.html");

    ### render feed
    render_feed($post_meta_list_ref, "$tmpl_path/feed.xml", "$output_path/feed.xml");
}

##! @todo: Extract info from html file
##! @return:
##!   0 => success
##!   1 => failure
sub extract_html {
    my $html_file_path = shift;
    my $title_ref = shift;
    my $date_ref = shift;
    my $content_ref = shift;

    my $find_title = 0;
    my $find_date = 0;
    my $find_content = 0;

    my $stat = 0;
    my $content = "";

    #print $html_file_path, "\n";
    open(HTML, "<" . $html_file_path);
    while (<HTML>) {
        chomp;
        my $file_content = $_;
        if ($stat == 0 &&
            $file_content =~ /<title>(.*?)<\/title>/) {
            $$title_ref = $1;
            $find_title = 1;
#            print("title:", $1, "\n");
            $stat = 2;
        #} elsif ($stat == 1 &&
        #         $file_content =~ /<meta name="generated" content="(.*?)"\/>/) {
        #    $$date_ref = $1;
        #    $find_date = 1;
#            print("date:", $1, "\n");
        #    $stat = 2;
        } elsif ($stat == 2 &&
                 $file_content =~ /<div id="table-of-contents">/) {
            $content = $content . $file_content;
#            print("3==>", $file_content, "\n");
            $stat = 3;
        } elsif ($stat == 3 &&
                 not $file_content =~ /<\/body>/) {
            $content = $content . $file_content . "\n";
#            print("4==>", $file_content, "\n");
            if ($file_content =~ /<p class="date">Date: (.*?)</) {
                $$date_ref = $1;
                $find_date = 1;
#                print("date:", $1, "\n");
            }
            $stat = 3;
        } elsif($stat == 3 &&
                $file_content =~ /<\/body>/) {
            ${$content_ref} = $content;
            $find_content = 1;
            last;
        }
    }
    close(HTML);
    return not ($find_title && $find_date && $find_content);
}

sub extract_keywords {
    my $content_ref = shift;
    my $keywords_ref = shift;

    foreach my $term (@keyword_dict) {
        if (${$content_ref} =~ /$term/ && length($term) > 6) {
            ${$keywords_ref} = ${$keywords_ref} . "," . $term;
        }
    }
}

sub extract_description {
    my $content_ref = shift;
    my $description_ref = shift;

    my $desp = ${$content_ref};

    $desp =~ s/[\r\n]//g;
    if (not $desp =~ /<div id="text-table-of-contents">(.*?)<\/div>/) {
        return;
    }

    my $desp = $1;
    $desp =~ s/<.+?>/ /g;
    $desp =~ s/ +/ /g;

    ${$description_ref} = $desp;
}

##! @todo: Change relative path to absolute in HTML
##! @param: 0 => base url
##! @param: 1 => path
##! @param: 2 => ptr to html content
##! @return:
##!   0 => success
##!   1 => failure
sub path_rel2abs {
    my $base_url = shift;
    my $path = shift;
    my $content_ref = shift;
    $base_url =~ s/\/+$//;
    $path =~ s/^\/+//;
#    ${$content_ref} =~ s/<img src="\.\//<img src="$path\//g;
    ${$content_ref} =~ s/<img src="(?!http|https|ftp)/<img src="$path\//g;
}

sub gen_tree {
    my $org_path = shift;
    my $post_meta_list_ref = shift;

    my $root = {};
    $root->{"data"} = "ROOT";
    $root->{"type"} = "cate";

    foreach my $post (@{$post_meta_list_ref}) {
        my $current = $root;
        my $post_file = $post->{"post_file"};
        my $path = "pages/";
        my $cate_path = $org_path . "/";
        foreach my $cate (split(/\//, $post->{"category"})) {
            next if length($cate) == 0;
            $path = $path . $cate . "/";
            $cate_path = $cate_path . $cate . "/";
            if (! exists $current->{"children"}) {
                $current->{"children"} = {};
            }
            my $children = $current->{"children"};
            if (! exists $children->{$cate}) {
                $children->{$cate} = {};
                $children->{$cate}->{"type"} = "cate";
                $children->{$cate}->{"label"} = $cate;
                $children->{$cate}->{"path"} = $path;

                my $meta_file = $cate_path . "/META";
                if ( -e $meta_file) {
                    open(META, $meta_file) or die "cannot open < $meta_file: $!";
                    my $raw_json = <META>;
                    $children->{$cate}->{"meta"} = from_json($raw_json);
                    close(META);
                }

                ## parse metadata
                if (! exists $children->{$cate}->{"meta"}) {
                    my %meta = ();
                    $children->{$cate}->{"meta"} = \%meta;
                }
                $children->{$cate}->{"meta"}->{"label"} = $cate
                    unless exists $children->{$cate}->{"meta"}->{"label"};
                $children->{$cate}->{"meta"}->{"fold"} = 1
                    unless exists $children->{$cate}->{"meta"}->{"fold"};
                ## end of parse metadata
            }
            $current = $children->{$cate};
        }
        $current->{"children"}->{$post_file} = {};
        $current->{"children"}->{$post_file}->{"type"} = "post";
        $current->{"children"}->{$post_file}->{"label"} = $post_file;
        $current->{"children"}->{$post_file}->{"data"} = $post;
    }

    return $root;
}

sub dump_tree {
    my $tree = shift;
    my $depth = shift;
    print "-" x $depth, $tree->{"label"}, " [", $tree->{"type"}, "]", "\n";
    foreach my $child (keys %{$tree->{"children"}}) {
        dump_tree($tree->{"children"}->{$child}, $depth + 1);
    }
}

#------------------- main -------------------

my %opts;

$opts{"i"} = "";
$opts{"b"} = "";
$opts{"t"} = "";
$opts{"o"} = "";
$opts{"d"} = "";
getopts("hi:t:o:b:d:", \%opts);

if (exists $opts{"h"} || length($opts{"i"}) == 0 ||
    length($opts{"t"}) == 0 || length($opts{"o"}) == 0 ||
    length($opts{"b"}) == 0 || length($opts{"d"}) == 0) {
    usage();
    exit 0;
}


################################# main

### 0. init data
my @post_meta_list;
my @attach_meta_list;
my %category_meta_dict;

open(D, $opts{"d"}) or die "open keyword dict fail";
while (<D>) {
    chomp;
    push(@keyword_dict, $_);
}
close(D);

### 1. generate post & attachments meta info
my $org_path = $opts{"i"};
my $output_path = $opts{"o"} . "/";
my $base_url = $opts{"b"} . "/";
gen_post_meta($org_path, $output_path, $base_url, \@post_meta_list);
gen_attach_meta($org_path, $output_path, \@attach_meta_list);

# generate hierarchy for wiki tree

my $tree = gen_tree($org_path, \@post_meta_list);

#dump_tree($tree, 0);

### 2. export org files to html
export_org(\@post_meta_list);

### 3. generate category meta info
gen_category_meta(\@post_meta_list, \%category_meta_dict);

### 4. render templates
my $tmpl_path = $opts{"t"} . "/";
render_tmpl(\@post_meta_list, \%category_meta_dict, $tree,
            $tmpl_path, $org_path, $base_url, $output_path);

### 5. copy attachments to output folder
export_attach(\@attach_meta_list);
