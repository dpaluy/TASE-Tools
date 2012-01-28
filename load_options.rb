require 'csv'
require 'date'
require 'time'
require "net/http"
require 'json'
require 'option'

@input_file = "1.csv"
@hostURL = "stockcollector.herokuapp.com"
@expiration_dates = "/expiration_dates.json?search=TA25"
@options = "/assets/1091826/options.json"
@values = "/assets/1091826/values"

@http = Net::HTTP.new(@hostURL)

def get_option_params_from_file(filename)
  name = File.basename(filename).gsub('.csv', '')
  option = {}
  option[:option_type]  = (name[0] == "C")
  option[:strike] = name[1..-6]
  option[:expiration]  = @expiration_hash[name[-5..-1]]
  option
end

def mmmyy(date)
  d = Date.strptime(date, "%Y-%m-%d")
  d.strftime("%b%y")
end

def get_expiration_dates
  request = Net::HTTP::Get.new(@expiration_dates)
  request.content_type = 'application/json'
  response = @http.request(request)
  result = JSON.parse(response.body)
  list = {}
  result.each {|d| list[mmmyy(d["date"])] = d["date"]}
  list
end

def get_all_options
  request = Net::HTTP::Get.new(@options)
  request.content_type = 'application/json'
  response = @http.request(request)
  result = JSON.parse(response.body)
  list = {}
  result.each do |r| 
    o = Option.new(r)
    list[o.to_short] = o
  end
  list
end

def create_option(option)
  request = Net::HTTP::Post.new(@options)
  request.content_type = 'application/json'
  request.body = option.to_json
  response = @http.request(request)
  if response.code != "200" && response.code != "302"
    puts "Error(#{response.code}) adding: #{option}" 
  else
    puts "Added: #{option}" 
  end
end

def create_all_options(files)
  files.each do |f|
    option = get_option_params_from_file(f)
    puts "Creating #{f}"
    create_option(option)
  end
end

def create_option_value(option_id, price, timestamp)
  url = "#{@options.gsub('.json', '')}/#{option_id}/option_values"
  request = Net::HTTP::Post.new(url)
  request.content_type = 'application/json'
  request.body = {:price => price, :timestamp => timestamp}.to_json
  response = @http.request(request)
  if response.code != "200" && response.code != "302"
    puts "Error(#{response.code}) adding: #{price} #{timestamp}" 
  else
    puts "Added: #{price} #{timestamp}" 
  end  
end

def is_a_number?(s)
  s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true 
end

def load_file(filename)
  name = File.basename(filename).gsub('.csv', '')
  o = @option_hash[name]
  if o.nil?
    puts "Option not found #{name}"
    exit
  end
  CSV.read(filename).reject {|x| x.first.nil? }.each_with_index do |row, i|
    next if i < 5 # skip headers
    break if row[0].strip.empty?
    break if !is_a_number(row[1])
    date = row[0].to_s.strip
    price = row[1].to_s.strip
    puts "Load from file #{name}"
    create_option_value(o.id, price, date)
  end
end

##############
#    MAIN    #
##############
if ARGV.length() < 1
  puts "Usage: " + __FILE__ + " filename/folder"
  exit
end

@expiration_hash = get_expiration_dates

if File.directory?(ARGV[0])
  path = "#{ARGV[0].chomp('/')}/**/*.csv"
  filelist = Dir[path].sort
  create_all_options(filelist)
  @option_hash = get_all_options
  filelist.each {|f| load_file(f) }
else
  create_option(get_option_params_from_file(ARGV[0]))
  @option_hash = get_all_options
  load_file(ARGV[0])
end

puts "All Done"
