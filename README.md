# Pruny

![Meet Pruny and his best friend Edward!](doc/edward.jpg "Meet Pruny and his best friend Edward!")

`Pruny` is a small example app with a Sinatra component that implements an HTTP API that __wraps__ an hypothetical `FaultyTreeSevice` adding two main
features:

* Filtering of trees by indicators nodes;
* Service resilience.

Pruny was the product of an exercise I made for a previous job interview and I'm making it available here mainly to illustrate:
* How to create a microservce that exposes an HTTP API with a Sinatra component;
* A homebrew tree structure that can be created from a json-like structure (array and or hash in Ruby), searched, filtered and converted back to json and served as `application/json` through HTTP.

The original private repo had a URL pointing to another service (what I called `FaultyTreeService` above) that returned a big tree but that was also, as
its name imples, flaky - it failed several times during requests. In this version I'm removing the URL to this service, but you can see an example of
that tree in `/spec/fixtures/input-tree-ficture.json`.

# Algorithms Overview

## Tree-pruning/Filtering

To filter the trees, the json structure returned by `FaultyTreeService` is:

1. Converted to a tree-like data structure;
2. One or more nodes are searched using a BFS(ish) algorithm;
3. These nodes are grouped by common parents and finally the direct path torwards the root node is calculated, excluding any non-relevant siblings;
4. A copy of the tree for each of these nodes starting from the root is then returned.

## Resilience

The external `FaultyTreeService` fails a lot. `Pruny` will retry up to __4__ times before losing faith on the Micro-service gods and returning to the Monolith church.

# Setting it up

`Pruny` requires:

* Ruby 2.5.1;
* Bundler.

To get it running, follow the steps below:

1. Install rbenv https://github.com/rbenv/rbenv;
2. Install Ruby 2.5.1 (see instructions at the rbenv page above);
3. Install the Bundler gem: `$ gem install bundler`;
4. Install the Dotenv gem: `$ gem install dotenv`;
3. Clone this repo somewhere, cd into it;
4. Run `$ bundle install` and wait for all gems to be downloaded and installed;
5. Open an account at `rollbar.com` if you don't have one already, get your API token;
6. Run `$ cp .env.example .env`, edit it using your favorite editor (emacs!);
7. Set the value for the `ROLLBAR_ACCESS_TOKEN` to the token you copied in step #5;
8. Run the app with `$ bundle exec dotenv rackup`, it should be accessible @ `localhost:9292`.

## Manual Testing

At the moment, `Pruny` has ony one endpoint called `/tree`. It accepts two parameters:

1. The tree name (as in`/tree/<name>`). Right now only `input` is officially supported and tested;
2. The id of indicators to filter by (i.e `/tree/input?indicator_ids[]=1&indicator_ids[]=2...`).

Use your favorite HTTP client or API testing tool (Postman is a good one) or if you're in a hurry just open the following URL in your browser or use `curl`:

```
$ curl -XGET "localhost:9292/tree/input?indicator_ids[]=32&indicator_ids[]=31&indicator_ids[]=1" --globoff
```

This request will filter the upstream `input` tree by the indicator nodes with id `32`, `31` and `1`. You should get the following pruned tree structure json:

```json
[
    {
        "id":2,
        "name":"Demographics",
        "sub_themes": [
            {
                "id":4,
                "name":"Births and Deaths",
                "categories":[
                    {
                        "id": 11,
                        "name": "Crude death rate",
                        "unit": "(deaths per 1000 people)",
                        "indicators": [
                            {"id":1,"name":"total"}
                        ]
                    }
                ]
            }
        ]
    },
    {
        "id":3,
        "name":"Jobs",
        "sub_themes": [
            {
                "id":8,
                "name": "Unemployment", 
                "categories": [
                    {
                        "id":23,
                        "name": "Unemployment rate, 15–24 years, usual",
                        "unit": "(percent of labor force)",
                        "indicators": [
                            {"id":31,"name":"Total"},
                            {"id":32,"name":"Female"}
                        ]
                    }
                ]
            }
        ]
    }
]
```

If the upstream `FaultyTreeService` fails after too many retries (4 at the time of this writing) or if there's any other general error then `Pruny` will return an error in the form of a json, like:

```
{"error":"Woopsie! The server got confused. We have been notified."}
```

The end-user will not see the specific error, but it will be sent alongisde a backtrace will to Rollbar, where the awesome `Pruny` developers can deal with them in a timely manner (hopefully!).

# Automated tests

The suite of specs are located in the [spec](spec) directory. To run the whole suite just run `rake` at the project root directory.

If you'd like to run a specific spec, use the `m` cli helper:

`$ bundle exec m spec/path/to/the/spec.rb`

To run a specific example within a spec, pass in the line for it after the spec path after a colon:

`$ bundle exec m spec/path/to/the/spec.rb:55`

If `m` can't find the example in the line you specified, it will let you know and will list all examples in the spec alongside their lines, like so:

```
No tests found on line 22. Valid tests to run:

test_0001_anonymous: m spec/integration/app_spec.rb:82
test_0001_anonymous: m spec/integration/app_spec.rb:93
test_0001_anonymous: m spec/integration/app_spec.rb:104
test_0001_anonymous: m spec/integration/app_spec.rb:118
```

Just pick the right line number and run it again ;)
