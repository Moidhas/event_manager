# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

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

data = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

form_letter = File.read 'form_letter.erb'
letter_template = ERB.new form_letter

data.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zip(row[:zipcode])
  legislators = legislator_by_zip(zipcode)

  letter_generation(letter_template.result(binding), id)
end
