# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

DAY = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

def clean_zip(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zip(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'Your ZIP code is likely Invalid'
  end
end

def letter_generation(result, id)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/guess_#{id}.html"
  File.open(filename, 'w') { |file| file.write result }
end

def zip_bindings(letter_template, data)
  data.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zip(row[:zipcode])
    legislators = legislator_by_zip(zipcode)

    letter_generation(letter_template.result(binding), id)
  end
end

def clean_phone_numbers(phone_numbers)
  phone_numbers = phone_numbers.gsub('-', '')
  phone_numbers.gsub!('(', '')
  phone_numbers.gsub!(')', '')
  phone_numbers.gsub!(' ', '')
  phone_numbers.gsub!('.', '')
  phone_numbers[1..] if phone_numbers.length == 11 && phone_numbers.split('')[0] == '1'
  phone_numbers
end

def print_valid_phone(data)
  data.each do |row|
    phone_numbers = clean_phone_numbers(row[:homephone])
    next if phone_numbers.length < 10 || phone_numbers.length > 11

    puts "#{row[:first_name]}, #{phone_numbers}"
  end
end

def create_time_arr(data)
  data.map do |row|
    Time.strptime(row[:regdate], '%m/%d/%y %H:%M').hour
  end
end

def busy_hour(data)
  popular_time = create_time_arr(data).tally.sort_by { |_, v| v }.reverse
  popular_time.each { |hour, count| puts "Hour: #{hour}, Count: #{count}" }
end

def busy_day(data)
  popular_day = data.map { |row| Time.strptime(row[:regdate], '%m/%d/%y %H:%M').wday }.tally.sort_by { |_, v| v}.reverse
  popular_day.each { |day, count| puts "Day: #{DAY[day]}, Count: #{count}" }
end

data = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

form_letter = File.read 'form_letter.erb'
letter_template = ERB.new form_letter

busy_day(data)
