// Copyright 2013-2014 Simon Sapin.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.


extern crate serialize;
extern crate url;
use std::char;
use std::u32;
use serialize::json;
use url::{Url, UrlParser};

#[deriving(Encodable)]
struct Result {
    input: String,
    base: String,
    href: String,
    protocol: String,
    username: Option<String>,
    password: Option<String>,
    hostname: Option<String>,
    port: Option<u16>,
    pathname: Option<String>,
    search: Option<String>,
    hash: Option<String>,
    exception: Option<String>,
}

fn main() {
    let mut results : Vec<Result> = Vec::new();
    for test in parse_test_data(include_str!("../../reference-implementation/test/urltestdata.txt")).into_iter() {
      let base = Url::parse(test.base.as_slice()).unwrap();

      let result = 
        match UrlParser::new().base_url(&base).parse(test.input.as_slice()) {

          Ok(url) => 
            Result {
              input: test.input,
              base: test.base,
              href: url.serialize(),
              protocol: format!("{}:", url.scheme.clone()),
              username: match url.username() {
                  None => None,
                  Some(ref username) => Some(username.to_string())
                },
              password: match url.password() {
                  None => None,
                  Some(ref password) => Some(password.to_string())
                },
              hostname: url.serialize_host(),
              port: url.port(),
              pathname: url.serialize_path(),
              search: match url.query {
                  None => None,
                  Some(ref query) => Some(format!("?{}", query))
                },
              hash: match url.fragment {
                  None => None,
                  Some(ref fragment) => Some(format!("#{}", fragment))
                },
              exception: None
            },

          Err(message) => 
            Result {
              input: test.input.clone(),
              base: test.base,
              href: test.input,
              protocol: ":".to_string(),
              username: None,
              password: None,
              hostname: None,
              port: None,
              pathname: None,
              search: None,
              hash: None,
              exception: Some(format!("{}", message))
            }
        };

      results.push(result);
    };

    println!("{}", json::encode(&results));
}

struct Test {
    input: String,
    base: String,
    scheme: Option<String>,
    username: String,
    password: Option<String>,
    host: String,
    port: Option<String>,
    path: Option<String>,
    query: Option<String>,
    fragment: Option<String>,
//  expected_failure: bool,
}

fn parse_test_data(input: &str) -> Vec<Test> {
    let mut tests: Vec<Test> = Vec::new();
    for line in input.lines() {
        if line == "" || line.starts_with("#") {
            continue
        }
        let mut pieces = line.split(' ').collect::<Vec<&str>>();
        let expected_failure = pieces[0] == "XFAIL";
        if expected_failure {
            pieces.remove(0);
        }
        let input = unescape(pieces.remove(0).unwrap());
        let mut test = Test {
            input: input,
            base: if pieces.is_empty() || pieces[0] == "" {
                tests.last().unwrap().base.clone()
            } else {
                unescape(pieces.remove(0).unwrap())
            },
            scheme: None,
            username: String::new(),
            password: None,
            host: String::new(),
            port: None,
            path: None,
            query: None,
            fragment: None,
//          expected_failure: expected_failure,
        };
        for piece in pieces.into_iter() {
            if piece == "" || piece.starts_with("#") {
                continue
            }
            let colon = piece.find(':').unwrap();
            let value = unescape(piece.slice_from(colon + 1));
            match piece.slice_to(colon) {
                "s" => test.scheme = Some(value),
                "u" => test.username = value,
                "pass" => test.password = Some(value),
                "h" => test.host = value,
                "port" => test.port = Some(from_str(value.as_slice()).unwrap()),
                "p" => test.path = Some(value),
                "q" => test.query = Some(value),
                "f" => test.fragment = Some(value),
                _ => panic!("Invalid token")
            }
        }
        tests.push(test)
    }
    tests
}

fn unescape(input: &str) -> String {
    let mut output = String::new();
    let mut chars = input.chars();
    loop {
        match chars.next() {
            None => return output,
            Some(c) => output.push(
                if c == '\\' {
                    match chars.next().unwrap() {
                        '#' => '#',
                        '\\' => '\\',
                        'n' => '\n',
                        'r' => '\r',
                        's' => ' ',
                        't' => '\t',
                        'f' => '\x0C',
                        'u' => {
                            let mut hex = String::new();
                            hex.push(chars.next().unwrap());
                            hex.push(chars.next().unwrap());
                            hex.push(chars.next().unwrap());
                            hex.push(chars.next().unwrap());
                            u32::parse_bytes(hex.as_bytes(), 16)
                                .and_then(char::from_u32).unwrap()
                        }
                        _ => panic!("Invalid test data input"),
                    }
                } else {
                    c
                }
            )
        }
    }
}
