#include <check.h>
#include <string.h>
#include "check_suites.h"
#include "xcb.h"

/* XCBParseDisplay tests {{{ */

#define parse_display_pass(n,h,d,s) do_parse_display_pass(n,h,d,s,__FILE__,__LINE__)

static void do_parse_display_pass(const char *name, const char *host, const int display, const int screen,
		const char *file, const int line)
{
	int success;
	char *got_host;
	int got_display, got_screen;

	got_host = (char *) -1;
	got_display = got_screen = -42;
	mark_point();
	success = XCBParseDisplay(name, &got_host, &got_display, &got_screen);
	_fail_unless(success, file, line, "unexpected parse failure");
	_fail_unless(strcmp(host, got_host) == 0, file, line, "parse produced unexpected hostname");
	_fail_unless(display == got_display, file, line, "parse produced unexpected display");
	_fail_unless(screen == got_screen, file, line, "parse produced unexpected screen");

	if(screen)
		return;

	got_host = (char *) -1;
	got_display = got_screen = -42;
	mark_point();
	success = XCBParseDisplay(name, &got_host, &got_display, 0);
	_fail_unless(success, file, line, "unexpected screenless parse failure");
	_fail_unless(strcmp(host, got_host) == 0, file, line, "screenless parse produced unexpected hostname");
	_fail_unless(display == got_display, file, line, "screenless parse produced unexpected display");
}

#define parse_display_fail(n) do_parse_display_fail(n,__FILE__,__LINE__)

static void do_parse_display_fail(const char *name, const char *file, const int line)
{
	int success;
	char *got_host;
	int got_display, got_screen;

	got_host = (char *) -1;
	got_display = got_screen = -42;
	mark_point();
	success = XCBParseDisplay(name, &got_host, &got_display, &got_screen);
	_fail_unless(!success, file, line, "unexpected parse success");
	_fail_unless(got_host == (char *) -1, file, line, "host changed on failure");
	_fail_unless(got_display == -42, file, line, "display changed on failure");
	_fail_unless(got_screen == -42, file, line, "screen changed on failure");

	got_host = (char *) -1;
	got_display = got_screen = -42;
	mark_point();
	success = XCBParseDisplay(name, &got_host, &got_display, 0);
	_fail_unless(!success, file, line, "unexpected screenless parse success");
	_fail_unless(got_host == (char *) -1, file, line, "host changed on failure");
	_fail_unless(got_display == -42, file, line, "display changed on failure");
}

START_TEST(parse_display_unix)
{
	parse_display_pass(":0", "", 0, 0);
	parse_display_pass(":1", "", 1, 0);
	parse_display_pass(":0.1", "", 0, 1);
}
END_TEST

START_TEST(parse_display_ip)
{
	parse_display_pass("x.org:0", "x.org", 0, 0);
	parse_display_pass("expo:0", "expo", 0, 0);
	parse_display_pass("bigmachine:1", "bigmachine", 1, 0);
	parse_display_pass("hydra:0.1", "hydra", 0, 1);
}
END_TEST

START_TEST(parse_display_ipv4)
{
	parse_display_pass("198.112.45.11:0", "198.112.45.11", 0, 0);
	parse_display_pass("198.112.45.11:0.1", "198.112.45.11", 0, 1);
}
END_TEST

START_TEST(parse_display_ipv6)
{
	parse_display_pass("::1:0", "::1", 0, 0);
	parse_display_pass("::1:0.1", "::1", 0, 1);
	parse_display_pass("2002:83fc:d052::1:0", "2002:83fc:d052::1", 0, 0);
	parse_display_pass("2002:83fc:d052::1:0.1", "2002:83fc:d052::1", 0, 1);
}
END_TEST

START_TEST(parse_display_decnet)
{
	parse_display_pass("myws::0", "myws:", 0, 0);
	parse_display_pass("big::1", "big:", 1, 0);
	parse_display_pass("hydra::0.1", "hydra:", 0, 1);
}
END_TEST

START_TEST(parse_display_negative)
{
	parse_display_fail("");
	parse_display_fail(":");
	parse_display_fail("::");
	parse_display_fail(":.");
	parse_display_fail(":a");
	parse_display_fail(":a.");
	parse_display_fail(":0.");
	parse_display_fail(":0.a");
	parse_display_fail(":0.0.");

	parse_display_fail("localhost");
	parse_display_fail("localhost:");
}
END_TEST

/* }}} */

Suite *public_suite(void)
{
	Suite *s = suite_create("Public API");
	suite_add_test(s, parse_display_unix, "XCBParseDisplay unix");
	suite_add_test(s, parse_display_ip, "XCBParseDisplay ip");
	suite_add_test(s, parse_display_ipv4, "XCBParseDisplay ipv4");
	suite_add_test(s, parse_display_ipv6, "XCBParseDisplay ipv6");
	suite_add_test(s, parse_display_decnet, "XCBParseDisplay decnet");
	suite_add_test(s, parse_display_negative, "XCBParseDisplay negative");
	return s;
}
