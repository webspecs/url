use JSON;
use URI;

my %optionals = (
  hostname => host,
  username => user,
  password => password,
  port => _port
);

open TESTDATA, "urltestdata.json";
my $testdata = decode_json(join("", <TESTDATA>));
my @constructor_results=();

foreach (@$testdata) {
  my %test = %$_;
  my $uri = URI->new_abs($test{input}, $test{base})->canonical;

  my %result = (
    input => $test{input},
    base => $test{base},
    href => $uri->as_string,
    protocol => $uri->scheme . ":",
    pathname => $uri->path,
    search => $uri->can('query') && $uri->query ? '?'.$uri->query : '',
    hash => $uri->fragment ? '#'.$uri->fragment : ''
  );

  if ($uri->can('userinfo')) {
    my ($username, $password) = split /:/, $uri->userinfo, 2;
    $result{username} = $username;
    $result{password} = $password;
  }

  while (($var, $method) = each %optionals) {
    $result{$var} = $uri->$method if $uri->can($method);
  }

  push @constructor_results, \%result;
};

my %results = (
  useragent => 'Perl URI version ' . URI->VERSION,
  constructor => \@constructor_results
);

do {
  no warnings "utf8";
  binmode(STDOUT, ":utf8");
  print to_json(\%results, {pretty => 1});
}
