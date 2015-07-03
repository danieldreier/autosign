When(/^I get help for "([^"]*)"$/) do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} help`)
end

Given(/^a pre\-shared key of "([^"]*)"$/) do |presharedkey|
  @psk = presharedkey
end

Given(/^a hostname of "([^"]*)"$/) do |host|
  @hostname = host
end

Given(/^the current time is (\d+)$/) do |time|
  @current_time = time
end

Given(/^a static token file containing:$/) do |multiline|
    @static_token_file = multiline
end

Given(/^a mocked "\/(\S*)" directory$/)do |directory|
  dir_name = File.join(File.expand_path(current_dir), "etc")
  FileUtils.mkdir_p dir_name
  set_env 'ETCROOT', dir_name
#  create_dir("etc")
end

Then(/^a "\/(\S*)" (?:file|directory) should exist$/) do |file|
  #expect(File.exist?(File.join(File.expand_path(current_dir), file))).to be true
  fullpath = File.join(File.expand_path(current_dir), file)
  FileUtils.mkdir_p fullpath
  $world.puts "path: " + fullpath
  expect(File.exist?(file)).to be true
end
