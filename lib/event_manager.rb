require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def legislators_by_zipcode(zipcode)
    
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
          address: zipcode,
          levels: 'country',
          roles: ['legislatorUpperBody', 'legislatorLowerBody']
        )
        legislators = legislators.officials
      rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
      end
      legislators
end

def cleanup_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def save_thank_you_latter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end

end

def cleanup_phone_number(number)

    if number != nil
        number.gsub!(/[^0-9]/, '')
        if number.length < 10
            return "invalid number"
        elsif number.length == 11 && number[0] = "1"
            return number[1..10]
        elsif (number.length == 11 && number[0] != "1") || number.length > 11
            return "invalid number"
        else
            return number
        end
    else
        return "invalid number"
    end
end

def display_most_registered(t, d)
    hour_most_registered = t.group_by { |h| t.count(h)}.max_by {|h| h}
    day_most_registered = d.group_by { |h| d.count(h)}.max_by {|h| h}
    if hour_most_registered[1].uniq.length > 1
        puts "#{hour_most_registered[1].uniq.join(' & ')} o'clock are the hours of the day with the most registered number of people."
        puts "The number of people registered at each of these hours are #{hour_most_registered[0]} people"
    else
        puts "#{hour_most_registered[1].uniq.join} o'clock is the hour of the day with the most registered number of people."
        puts "The number of people registered at this hour are #{hour_most_registered[0]} people"
    end
    puts "#{day_most_registered[1].uniq.join(' & ')} is the day with the most registered number of people."
    puts "The number of people registered on this day of the week are #{day_most_registered[0]} people"
end


content = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
time = []
week_day = []
content.each do |row|
    id = row[0]

    name = row[:first_name]
    
    zipcode = cleanup_zipcode(row[:zipcode])
    
    phone_number = cleanup_phone_number(row[:home_phone])

    date_time = DateTime.strptime(row[:reg_date], "%m/%d/%Y %H:%M")

    time.push(date_time.strftime("%H"))

    week_day.push(date_time.strftime("%A"))

    legislators = legislators_by_zipcode(zipcode)

    personal_letter = erb_template.result(binding)

end

display_most_registered(time, week_day)

