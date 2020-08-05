use base "installedtest";
use strict;
use testapi;
use lockapi;
use utils;
use tapnet;
use cockpit;

sub run {
    my $self = shift;
    # use FreeIPA server as DNS server
    bypass_1691487;
    assert_script_run "printf 'search domain.local\nnameserver 172.16.2.100' > /etc/resolv.conf";
    # wait for the server to be ready (do it now just to make sure name
    # resolution is working before we proceed)
    mutex_lock "freeipa_ready";
    mutex_unlock "freeipa_ready";
    # do repo setup
    repo_setup();
    # set sssd debugging level higher (useful for debugging failures)
    # optional as it's not really part of the test
    script_run "dnf -y install sssd-tools", 220;
    script_run "sss_debuglevel 9";
    # run firefox and login to cockpit
    # note: we can't use wait_screen_change, wait_still_screen or
    # check_type_string in cockpit because of that fucking constantly
    # scrolling graph
    start_cockpit(1);
    # on cockpit 209+ we have to scroll down before the button is
    # visible
    if (check_screen "cockpit_join_domain_button", 5) {
        click_lastmatch;
    }
    else {
        # to activate the right pane
        assert_and_click "cockpit_main";
        send_key "pgdn";
        # wait out scroll...
        wait_still_screen 2;
        assert_and_click "cockpit_join_domain_button", 5;
    }
    assert_screen "cockpit_join_domain";
    send_key "tab";
    sleep 3;
    type_string("ipa001.domain.local", 4);
    type_string("\t\t", 4);
    type_string("admin", 4);
    send_key "tab";
    sleep 3;
    type_string("monkeys123", 4);
    sleep 3;
    assert_and_click "cockpit_join_button";
    # join involves package installs, so it may take some time
    assert_screen "cockpit_join_complete", 300;
    # quit browser to return to console
    quit_firefox;
    # we don't get back to a prompt instantly and keystrokes while X
    # is still shutting down are swallowed, so be careful before
    # finishing (and handing off to next test)
    assert_screen "root_console";
    wait_still_screen 5;
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
