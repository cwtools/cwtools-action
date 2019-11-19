# Based on https://github.com/gimenete/rubocop-action by Alberto Gimeno published under MIT License.
#
# MIT License
# 
# Copyright (c) 2019 Alberto Gimeno
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'net/http'
require 'json'
require 'time'
require 'set'

@GITHUB_EVENT_PATH = ENV["GITHUB_EVENT_PATH"]
@GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
@GITHUB_WORKSPACE = ENV["GITHUB_WORKSPACE"]

@event = JSON.parse(File.read(ENV["GITHUB_EVENT_PATH"]))
@repository = @event["repository"]
@owner = @repository["owner"]["login"]
@repo = @repository["name"]
@GITHUB_SHA = ENV["GITHUB_SHA"]
@is_pull_request = false
unless @event["pull_request"].nil?
  @GITHUB_SHA = @event["pull_request"]["head"]["sha"]
  @is_pull_request = [@event["pull_request"]["base"]["ref"], @event["pull_request"]["head"]["ref"]]
end
@CHANGED_ONLY = ENV["INPUT_CHANGEDFILESONLY"]
if @CHANGED_ONLY == '0' || @CHANGED_ONLY.downcase == 'false'
  @CHANGED_ONLY = false
else
  @CHANGED_ONLY = true
end

@SUPPRESSED_OFFENCE_CATEGORIES = JSON.parse(ENV["INPUT_SUPPRESSEDOFFENCECATEGORIES"])
@GAME = ENV["IMPUT_GAME"]
if @GAME == "stellaris"
  @GAME = "stl"
end

@changed_files = []
@check_name = "CWTools"

@headers = {
  "Content-Type": 'application/json',
  "Accept": 'application/vnd.github.antiope-preview+json',
  "Authorization": "Bearer #{@GITHUB_TOKEN}",
  "User-Agent": 'cwtools-action'
}

def get_changed_files
  diff_output = nil
  Dir.chdir(@GITHUB_WORKSPACE) do
    if @is_pull_request
      diff_output = `git log --name-only --pretty="" origin/#{@is_pull_request[0]}..origin/#{@is_pull_request[1]}`
    else
      diff_output = `git diff-tree --no-commit-id --name-only -r #{@GITHUB_SHA}`
    end
  end
  unless diff_output.nil?
    diff_output = diff_output.split("\n")
    diff_output.collect(&:strip)
  else
    diff_output = []
  end
  diff_output = diff_output.to_set
  p diff_output
  @changed_files = diff_output
end

def create_check
  body = {
    "name" => @check_name,
    "head_sha" => @GITHUB_SHA,
    "status" => "in_progress",
    "started_at" => Time.now.iso8601
  }

  http = Net::HTTP.new('api.github.com', 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs"

  resp = http.post(path, body.to_json, @headers)

  if resp.code.to_i >= 300
    puts JSON.pretty_generate(resp.body)
    raise resp.message
  end

  data = JSON.parse(resp.body)
  return data["id"]
end

def update_check(id, conclusion, output)
  if conclusion.nil?
    body = {
      "name" => @check_name,
      "head_sha" => @GITHUB_SHA,
      "output" => output
    }
  else
    body = {
      "name" => @check_name,
      "head_sha" => @GITHUB_SHA,
      "status" => 'completed',
      "completed_at" => Time.now.iso8601,
      "conclusion" => conclusion
    }
  end
  http = Net::HTTP.new('api.github.com', 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs/#{id}"

  resp = http.patch(path, body.to_json, @headers)

  if resp.code.to_i >= 300
    puts JSON.pretty_generate(resp.body)
    raise resp.message
  end
end


@annotation_levels = {
  "error" => 'failure',
  "warning" => 'warning',
  "information" => 'notice',
  "hint" => 'notice'
}

def run_cwtools
  annotations = []
  errors = nil
  puts "Running CWToolsCLI now..."
  Dir.chdir(@GITHUB_WORKSPACE) do
    `cwtools --game hoi4 --directory "#{@GITHUB_WORKSPACE}" --cachefile "/hoi4.cwb" --rulespath "/src/cwtools-hoi4-config/Config" validate --reporttype json --scope mods --outputfile output.json all`
    errors = JSON.parse(`cat output.json`)
  end
  puts "Done running CWToolsCLI..."
  conclusion = "success"
  count = { "failure" => 0, "warning" => 0, "notice" => 0 }

  errors["files"].each do |file|
    path = file["file"]
    path = path.sub! @GITHUB_WORKSPACE+"/", ''
    path = path.strip
    offenses = file["errors"]
    if !@CHANGED_ONLY || @changed_files.include?(path)
      offenses.each do |offense|
        severity = offense["severity"].downcase
        message = offense["category"] + ": " + offense["message"]
        location = offense["position"]
        annotation_level = @annotation_levels[severity]
        if annotation_level != "notice" && annotation_level != "warning" && annotation_level != "failure"
          annotation_level = "notice"
        end

        if @SUPPRESSED_OFFENCE_CATEGORIES[annotation_level].include?(offense["category"])
          next
        end

        if annotation_level == "failure"
          conclusion = "failure"
        elsif conclusion != "failure" && annotation_level == "warning"
          conclusion = "neutral"
        end
          count[annotation_level] = count[annotation_level] + 1
        if location["startLine"] == location["endLine"] && location["startColumn"].to_i <= location["endColumn"].to_i
          annotations.push({
            "path" => path,
            "title" => @check_name,
            "start_line" => location["startLine"],
            "end_line" => location["endLine"],
            "start_column" => location["startColumn"].to_i > 0 ? location["startColumn"] : 1,
            "end_column" => location["endColumn"].to_i > 0 ? location["endColumn"] : 1,
            "annotation_level": annotation_level,
            "message" => message
          })
        else
          annotations.push({
            "path" => path,
            "title" => @check_name,
            "start_line" => location["startLine"],
            "end_line" => location["endLine"],
            "annotation_level": annotation_level,
            "message" => message
          })
        end
      end
    end
  end

  output = []
  total_count = count["failure"]+count["warning"]+count["notice"]
  annotations.each_slice(50).to_a.each do |annotation|
    output.push({
      "title": @check_name,
      "summary": "**#{total_count}** offense(s) found:\n* #{count["failure"]} failure(s)\n* #{count["warning"]} warning(s)\n* #{count["notice"]} notice(s)",
      "annotations" => annotation
    })
  end

  return { "output" => output, "conclusion" => conclusion }
end

def run
  puts "CWTOOLS CHECK"
  unless defined?(@GITHUB_TOKEN)
    raise "GITHUB_TOKEN environment variable has not been defined"
  end
  if @is_pull_request
    puts "Is pull request..."
  else
    puts "Is commit..."
  end
  if @CHANGED_ONLY
    puts "Annotating only changed files..."
  else
    puts "Annotating all files..."
  end
  id = create_check()
  begin
    get_changed_files()
    results = run_cwtools()
    conclusion = results["conclusion"]
    output = results["output"]
    puts "Updating checks..."
    output.each do |o|
      update_check(id, nil, o)
    end
    fail if conclusion == "failure"
    update_check(id, conclusion, nil)
  rescue
    update_check(id, "failure", nil)
    fail("At least one check failed! Exiting with a non-zero error code...")
  end
end

run()