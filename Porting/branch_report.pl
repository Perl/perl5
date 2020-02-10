#!perl

use strict;
use warnings;
use Data::Dumper;
use warnings 'FATAL' => 'all';

my $verbose;
my %can_delete;
my %maybe_delete;
my %keep;
my $remote= "origin";
my $master= "blead";

sub get_branches {
    my ($filter)= @_;
    #system("git remote update $remote");
    chomp(my @branches= `git branch -r`);
    @branches= grep { s!^\s+!! } @branches;
    @branches= grep { m!$filter! } @branches if $filter;
    return \@branches;
}

my $pretty= join "%x09",        # tab
            "%H",               # full hash
            "%aN <%aE>: %s",    # author subject
            "%aN <%aE>",        # author
            "%s",               # subject
            "%ci",              # commit date ISO 8601
            "%cr",              # commit date relative
;

sub get_oneline {
    my ($base,$branch)= @_;
    chomp(my @commits= `git log --pretty="$pretty" $base..$branch`);
    my $i=0;
    @commits= map { [split(/\t/, $_),$i++] } @commits;
    return \@commits;
}

sub get_cherry_flags {
    my ($upstream, $branch)= @_;
    chomp(my @cherry= `git cherry -v $upstream $branch`);
    my %cherry_flags;
    my %flag_count;
    foreach my $cherry (@cherry) {
        my ($flag, $sha1, $msg)= split / /, $cherry, 3;
        $cherry_flags{$sha1}= { flag => $flag, msg=> $flag };
        $flag_count{$flag}++;
    }
    return (\%cherry_flags,$flag_count{"+"}||0, $flag_count{"-"}||0)
}

sub git_merge_base {
    my ($upstream, $branch)= @_;
    chomp(my $merge_base= `git merge-base $upstream $branch`);
    return $merge_base;
}

sub git_describe {
    my ($commit)= @_;
    chomp(my $describe= `git describe --always $commit`);
    return $describe;
}

open my $fh_should_delete, ">", "can_delete.rpt" or die "Failed to open 'can_delete.rpt': $!";
open my $fh_maybe_delete, ">", "maybe_delete.rpt" or die "Failed to open 'maybe_delete.rpt': $!";
open my $fh_keep, ">", "not_delete.rpt" or die "Failed to open 'not_delete.rpt': $!";

my $branches= get_branches(qr!$remote/!);
my %flag_to_text= (
    '-' => "[-] patch-id upstream",
    '+' => "[+] patch-id not pushed",
    '?' => "[?] patch-id not computed by cherry - probably merge commit"
);

my %auth_branch;

foreach my $branch (
    @$branches
) {
    next if $branch =~ /HEAD/ or $branch eq "$remote/$master" or $branch =~m!$remote/maint!;
    my $msg= "Branch $branch\n";
    #if ($verbose) {
    #    my $log= `git log -1 --decorate --stat $branch`;
    #    print $log,"\n";
    #}

    my ($cherry_flags, $count_missing, $count_upstream)= get_cherry_flags("$remote/$master", $branch);

    my $merge_base= git_merge_base("$remote/$master",$branch);
    my $merge_descr= git_describe($merge_base);

    my $commits= get_oneline($merge_base,$branch);
    $msg .= sprintf "This branch has %d commit%s.\n", 0+@$commits, @$commits > 1 ? "s" : "";
    if ($merge_base) {
        $msg .= "merge-base is: $merge_base - $merge_descr\n";
    } else {
        $msg .= "THIS BRANCH DOES NOT HAVE A COMMON ANCESTOR WITH $remote/$master\n";
    }

    my %want_by_auth_subj;
    foreach my $line (@$commits) {
        my ($sha1, $auth_subj)= @$line;
        $want_by_auth_subj{$auth_subj}= $line;
    }
    my $ocommits= get_oneline($merge_base,"$remote/$master");
    my %have_by_auth_subj;
    foreach my $line (@$ocommits) {
        my ($sha1, $auth_subj)= @$line;
        if ($want_by_auth_subj{$auth_subj}) {
            $have_by_auth_subj{$auth_subj}= $line;
        }
    }
    my $width1= length("$master commit date");
    my $width2= length("branch commit date");
    my $width= $width1 > $width2 ? $width1 : $width2;
    $width= -$width;

    my $most_recent_want_auth= @$commits && $commits->[0][2];


    my $first_line_report= "";
    foreach my $want_tuple (@$commits) {
        my ($want_sha1, $want_auth_subj, $want_auth, $want_subject, $want_date, $want_date_relative)= @$want_tuple;
        my $flag= $cherry_flags->{$want_sha1}{flag} || "?";
        my $want_describe= git_describe($want_sha1);
        if (my $tuple= $have_by_auth_subj{$want_auth_subj}) {
            my ($have_sha1, $have_auth_subj, $have_auth, $have_subject, $have_date, $have_date_relative)= @$tuple;
            my $have_describe= git_describe($have_sha1);
            $first_line_report .= "in $master $flag_to_text{$flag}\n"
                                . sprintf("  %*s: %s\n", $width, "author" => $have_auth)
                                . sprintf("  %*s: %s\n", $width, "subject" => $have_subject)
                                . sprintf("  %*s: %s\n", $width, "$master commit date" => "$have_date - $have_date_relative")
                                . sprintf("  %*s: %s\n", $width, "$master sha1" => $have_sha1)
                                . sprintf("  %*s: %s\n", $width, "$master describe" =>  $have_describe)
                                . sprintf("  %*s: %s\n", $width, "branch sha1" => $want_sha1)
                                . sprintf("  %*s: %s\n", $width, "branch describe" => $want_describe)
            ;
        } else {
            $first_line_report .= "subject/author only in branch $flag_to_text{$flag}\n"
                                . sprintf("  %*s: %s\n", $width, "author" => $want_auth)
                                . sprintf("  %*s: %s\n", $width, "subject" => $want_subject)
                                . sprintf("  %*s: %s\n", $width, "branch commit date" => "$want_date - $want_date_relative")
                                . sprintf("  %*s: %s\n", $width, "branch sha1" => $want_sha1)
                                . sprintf("  %*s: %s\n", $width, "branch describe" => $want_describe)
            ;
        }
    }
    if (!@$commits) {
        $msg .= "Branch has no commits on it.\n"
              . "This branch should be deleted.\n"
              . "---\n\n";
        $can_delete{$branch}++;
        print $fh_should_delete $msg;
    }
    elsif ($count_missing == 0) {
        $msg.= "All commits are upstream:\n"
               . $first_line_report
               . "Recommend that this branch be deleted.\n"
               . "---\n\n";
        $can_delete{$branch}++;
        push @{$auth_branch{$most_recent_want_auth}{delete}}, $branch;
        print $fh_should_delete $msg;
    }
    elsif (keys %have_by_auth_subj != keys %want_by_auth_subj) {
        $msg .= "Not all commits are upstream. $count_missing not pushed.\n"
              . $first_line_report
              . "Recommend to keep this branch.\n"
              . "---\n\n";
        $keep{$branch}++;
        push @{$auth_branch{$most_recent_want_auth}{keep}}, $branch;
        print $fh_keep $msg;
    }
    else {
        # $cherry=~/\+/ and keys %have_by_auth_subj == keys %want_by_auth_subj
        $msg .= "All commits seem to be upstream (by author/subject), but `git cherry` says $count_missing have not been pushed:\n";
        $msg .= $first_line_report;
        my @bad;
        foreach my $auth_subj (
            sort {
                $want_by_auth_subj{$a}->[-1] <=> $want_by_auth_subj{$b}->[-1]
            } keys %want_by_auth_subj
        ) {
            my ($have_sha1)= @{$have_by_auth_subj{$auth_subj}};
            my ($want_sha1)= @{$want_by_auth_subj{$auth_subj}};

            my $have_body= `git log -1 --pretty="%aN <%aE>%n%B" $have_sha1`;
            my $want_body= `git log -1 --pretty="%aN <%aE>%n%B" $want_sha1`;
            if ($have_body ne $want_body) {
                $msg .= "Have commit $have_sha1 which has a similar subject but whose body not the same as $want_sha1\n";
                push @bad, [$have_sha1,$want_sha1];
            }
        }
        if (!@bad) {
            $msg .= "Nevertheless all full commit messages were seen upstream of merge base.\n"
                  . "This branch can probably be deleted.\n---\n\n";
            $maybe_delete{$branch}++;
            push @{$auth_branch{$most_recent_want_auth}{maybe_delete}}, $branch;
            print $fh_maybe_delete $msg;
        } else {
            $msg .= "Upstream commit message and authors are different.\n";
            $msg .= "Recommend keep this branch.\n---\n\n";
            push @{$auth_branch{$most_recent_want_auth}{keep}}, $branch;
            $keep{$branch}++;
            print $fh_keep $msg;
        }
    }
    print $msg;
}
if  (keys %can_delete) {
    my $summary= "Branches that can be deleted as all patches are already in $remote/$master\n";
    foreach my $branch (sort keys %can_delete) {
        $summary .= "  $branch\n";
    }
    $summary .= "\n";
    print $fh_should_delete $summary;
    print $summary;
}
if (keys %maybe_delete) {
    my $summary= "Branches that look like they are pushed (based on author and commit message) but have different patch-ids\n";
    foreach my $branch (sort keys %maybe_delete) {
        $summary .= "  $branch\n";
    }
    $summary .= "\n";
    print $fh_maybe_delete $summary;
    print $summary;
}
if (keys %keep) {
    my $summary = "Branches that have not been merged upstream yet at all\n";
    foreach my $branch (sort keys %keep) {
        $summary .= "  $branch\n";
    }
    $summary .= "\n";
    print $fh_keep $summary;
    print $summary;
}
my $all_branches= keys(%can_delete)+keys(%maybe_delete)+keys(%keep);

printf $fh_should_delete "%d branches can be deleted of %d branches in total:\n", 0+keys %can_delete, $all_branches;
close $fh_should_delete;
printf $fh_keep "%d branches should be kept of %d branches in total:\n", 0+keys %keep, $all_branches;
close $fh_keep;
printf $fh_maybe_delete "%d branches should be kept of %d branches in total:\n", 0+keys %maybe_delete, $all_branches;
close $fh_maybe_delete;

printf "Total branches: %d. Should delete: %d. Maybe delete: %d. Definitely keep: %d.\n",
    $all_branches,
    0+keys(%can_delete),0+keys(%maybe_delete),0+keys(%keep);

my $final= "Branches by most recent commit author:\n";
foreach my $auth (sort keys %auth_branch) {
    $final.="$auth\n";
    foreach my $type (sort keys %{$auth_branch{$auth}}) {
        $final.="    $type\n";
        foreach my $branch (@{$auth_branch{$auth}{$type}}) {
            $final .= (" " x 8) . $branch. "\n";
        }
    }
}
print $final;
open my $fh_final, ">", "auth_branch_report.rpt" or die "Failed to open for write 'auth_branch_report.rpt': $!";
print $fh_final $final;
close $fh_final;




