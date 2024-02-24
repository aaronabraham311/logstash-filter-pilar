# Logstash Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

Logstash provides infrastructure to automatically generate documentation for this plugin. We use the asciidoc format to write documentation so any comments in the source code will be first converted into asciidoc and then into html. All plugin documentation are placed under one [central location](http://www.elastic.co/guide/en/logstash/current/).

- For formatting code or config example, you can use the asciidoc `[source,ruby]` directive
- For more asciidoc formatting tips, see the excellent reference here https://github.com/elastic/docs#asciidoc-guide

## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Plugin Development and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Install logstash locally and add the env variable 'LOGSTASH_PATH' which points to your logstash instance, to your path.

- Install dependencies
```sh
bundle install
```

- Run `rubocop -A` to run and fix Ruby style guide issues

- Add the following to `.git/hooks/pre-commit`

```
 #!/usr/bin/env sh

 # This hook has a focus on portability.
 # This hook will attempt to setup your environment before running checks.
 #
 # If you would like `pre-commit` to get out of your way and you are comfortable
 # setting up your own environment, you can install the manual hook using:
 #
 #     pre-commit install --manual
 #

 # This is a work-around to get GitHub for Mac to be able to run `node` commands
 # https://stackoverflow.com/questions/12881975/git-pre-commit-hook-failing-in-github-for-mac-works-on-command-line
 PATH=$PATH:/usr/local/bin:/usr/local/sbin


 cmd=`git config pre-commit.ruby 2>/dev/null`
 if   test -n "${cmd}"
 then true
 elif which rvm   >/dev/null 2>/dev/null
 then cmd="rvm default do ruby"
 elif which rbenv >/dev/null 2>/dev/null
 then cmd="rbenv exec ruby"
 else cmd="ruby"
 fi

 export rvm_silence_path_mismatch_check_flag=1

 ${cmd} -rrubygems -e '
   begin
     require "pre-commit"
     true
   rescue LoadError => e
     $stderr.puts <<-MESSAGE
 pre-commit: WARNING: Skipping checks because: #{e}
 pre-commit: Did you set your Ruby version?
 MESSAGE
     false
   end and PreCommit.run
 '
```


#### Test

- Update your dependencies

```sh
bundle install
```

- Run tests

```sh
bundle exec rspec
```

### 2. Running your unpublished Plugin in Logstash

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-filter-pilar", :path => "/your/local/logstash-filter-pilar"
```
- Install plugin
```sh
bin/logstash-plugin install --no-verify
```
- Run Logstash with your plugin, you can test your code by typing a log in the command line, and the output will immediately be reflected
```sh
bin/logstash -e 'filter {pilar {}}'
```
Alternatively, you can include a file path for seed logs by running the following:
```sh
bin/logstash -e 'filter { pilar { seed_logs_path => "example/file/path" } }'
```

At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-filter-pilar.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/logstash-plugin install /your/local/plugin/logstash-filter-pilar.gem
```
- Start Logstash and proceed to test the plugin

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members  saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/main/CONTRIBUTING.md) file.
