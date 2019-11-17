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

@GITHUB_SHA = ENV["GITHUB_SHA"]
@GITHUB_EVENT_PATH = ENV["GITHUB_EVENT_PATH"]
@GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
@GITHUB_WORKSPACE = ENV["GITHUB_WORKSPACE"]

@event = JSON.parse(File.read(ENV["GITHUB_EVENT_PATH"]))
@repository = @event["repository"]
@owner = @repository["owner"]["login"]
@repo = @repository["name"]

@check_name = "CWTools"

@headers = {
  "Content-Type": 'application/json',
  "Accept": 'application/vnd.github.antiope-preview+json',
  "Authorization": "Bearer #{@GITHUB_TOKEN}",
  "User-Agent": 'cwtools-action'
}

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
  if conclusion?nil
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
  "Error" => 'failure',
  "Warning" => 'warning',
  "Information" => 'notice',
  "Hint" => 'notice'
}

def run_cwtools
  annotations = []
  errors = nil
  puts "Running CWToolsCLI now..."
  Dir.chdir("/src/cwtools/CWToolsCLI") do
    `dotnet run -c Release -- --game hoi4 --directory "#{@GITHUB_WORKSPACE}" --cachefile "/src/cwtools/CWToolsCLI/hoi4.cwb" --rulespath "/src/cwtools-hoi4-config/Config" validate --reporttype json --scope mods --outputfile output.json all`
    errors = JSON.parse(`cat output.json`)
  end
  puts "Done running CWToolsCLI..."
  conclusion = "success"
  count = 0

  errors["files"].each do |file|
    path = file["file"]
    path = path.sub! '/github/workspace/', ''
    offenses = file["errors"]

    offenses.each do |offense|
      severity = offense["severity"]
      message = offense["category"] + ": " + offense["message"]
      location = offense["position"]
      annotation_level = @annotation_levels[severity]
      count = count + 1

      if annotation_level == "failure"
        conclusion = "failure"
      end

      if location["startLine"] == location["endLine"]
        annotations.push({
          "path" => path,
          "title" => @check_name,
          "start_line" => location["startLine"],
          "end_line" => location["endLine"],
          "start_column" => location["startColumn"],
          "end_column" => location["endColumn"],
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

  output = []
  annotations.each_slice(50).to_a.each do |annotation|
    output.push({
      "title": @check_name,
      "summary": "#{count} offense(s) found",
      "annotations" => annotation
    })
  end

  return { "output" => output, "conclusion" => conclusion }
end

def run
  unless defined?(@GITHUB_TOKEN)
    raise "GITHUB_TOKEN environment variable has not been defined"
  end
  id = create_check()
  begin
    results = run_cwtools()
    conclusion = results["conclusion"]
    output = results["output"]
    puts "Updating checks..."
    output.each do |o|
      update_check(id, nil, o)
    end
    update_check(id, conclusion, nil)
  rescue
    puts "There was an exception, failing"
    update_check(id, "failure", nil)
    fail
  end
end

run()