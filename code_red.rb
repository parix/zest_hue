require "huey"
require "gmail"

Huey::Request.register

$table = {}
$code_red_status = "off"
GMAIL_USERNAME = ""
GMAIL_PASSWORD = ""

def hue_turn_bulbs_red
  Huey::Bulb.all.update(on: true, rgb: "#FF0000")
end

def hue_turn_bulbs_white
  Huey::Bulb.all.update(on: true, rgb: "#FFE74A", bri: 80)
end

def hue_blink_bulbs
  5.times { Huey::Bulb.all.alert!; sleep(1) }
end

def code_red_exists?(name)
  !$table[name].nil?
end

def open_code_red(name)
  unless code_red_exists?(name)
    $table[name] = "opened"
  end
end

def close_code_red(name)
  if code_red_exists?(name)
    $table[name] = "closed"
  end
end

def are_there_any_code_reds_open?
  !($table.select { |k, v| v == "opened" }.empty?)
end

def turn_on_code_red_lights
  $code_red_status = "on"
  puts "BLINK!"
  hue_turn_bulbs_red
  hue_blink_bulbs
  puts "SOLID"
end

def turn_off_code_red_lights
  $code_red_status = "off"
  puts "OFF"
  hue_turn_bulbs_white
  hue_blink_bulbs
end

def update_table
  gmail = Gmail.connect(GMAIL_USERNAME, GMAIL_PASSWORD)
  emails = gmail.inbox.find(:unread, :to => "hue-code-red@zestfinance.com")

  starter_emails = emails.reject { |email| email.subject.include?("Re:") }
  replies = emails.select { |email| email.subject.include?("Re:") }

  # add new code reds
  starter_emails.each { |email| open_code_red(email.subject) }

  # close existing code reds
  closing_emails = replies.select { |email| /#closed/i.match(email.message.to_s) }
  closing_emails.each { |email| close_code_red(email.subject.sub(/^Re: /,"")) }

  emails.each(&:read!)
  gmail.logout
end

hue_turn_bulbs_white
while(true) do
  # update code red table
  update_table

  # lights
  if are_there_any_code_reds_open? && $code_red_status == "off"
    turn_on_code_red_lights
  elsif !are_there_any_code_reds_open? && $code_red_status == "on"
    turn_off_code_red_lights
  end

  sleep(10)
end
