require 'telegram/bot'
require "rubygems"
require "shikashi"
require 'net/http'


# debug only:
# require 'openssl'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# available methods:
# p :times, :puts, :print, :each, :p, *Fixnum.methods


include Shikashi
# override the default Privileges class from Shikashi to add allow_methods for convenient
module Shikashi
  class Privileges
    def allow_methods(*method_names)
      method_names.each do |mn|
        @allowed_methods << mn
      end

      self
    end
  end
end

# declare bot class
class TestBot


  # class constructor
  def initialize(token)
    # declare instance variable
    @token = token
    @bot = NIL
    @last_message=NIL
    @allowed_const_read=Array.new
    @allowed_methods=Array.new
    # method whitelist
    methods=Fixnum.methods+Fixnum.instance_methods+Array.methods+Array.instance_methods+String.methods+String.instance_methods+Net::HTTP.methods+Net::HTTP.instance_methods+Math.methods+Math.instance_methods
    methods.each { |method|
      @allowed_methods << method
    }
    [:times, :puts, :print, :each, :p].each { |method|
      @allowed_methods << method
    }
    # constant whitelist
    [Math].each { |const|
      @allowed_const_read << const
    }

  end

  # utility method for capturing stdout
  def with_captured_stdout
    begin
      old_stdout = $stdout
      $stdout = StringIO.new('', 'w')
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end
  end

  # utility method for sending telegram message a bit more conveniently
  def send_reply(text)
    @bot.api.send_message(chat_id: @last_message.chat.id, text: text)
  end

  # main method for running the bot
  def start_bot
    Telegram::Bot::Client.run(@token) do |bot|
      @bot=bot
      bot.listen do |message|
        @last_message=message
        # print message to terminal for debug
        puts message
        # switch case for different command
        # TODO: extract each command to a new method
        case message.text
          when /\A\/start/
            bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}. I am started! >.<")
          when /\A\/stop/
            bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}. Why did you stop me? T^T")
          when /\A\/help/
            bot.api.send_message(chat_id: message.chat.id, text:
                "/run\nFormat: /run {code}\nAvailable method: times, puts, print, each, p \nExample: \n/run 3.times{|x| puts x*x}\n/run puts 'I am a happy little bot.'\nThis bot is created by @Energy0124. \nSource code is avaliable here:\n https://github.com/Energy0124/EnergyRubyTelegramBot.git ")
          # running ruby code on server in a sandbox
          when /\A\/run/
            if message.text=~ /\A\/run@Energy0124TestBot/
              message.text.slice! '/run@Energy0124TestBot'
            else
              message.text.slice! '/run'
            end
            begin
              # capture the stdout
              stdout=with_captured_stdout {
                s = Sandbox.new
                priv = Privileges.new
                # whitelist some safe method
                priv.allow_const_read *@allowed_const_read
                priv.allow_methods *@allowed_methods
                # eval the ruby code
                s.run(priv, message.text, :timeout => 3)
              }
              # print the stdout
              puts(stdout)
              # send stdout as telegram message
              send_reply("Result:\n#{stdout}")
                #   catch exception
            rescue Exception => ex
              send_reply("Error:\n#{ex}")
            end
          #   for fun
          when /fuck/i
            send_reply("I fucking hate people saying 'fuck'.")
          when /dota/i
            send_reply('Dota is the best!')
          when /stupid bot/i
            send_reply('Still a bit smarter than you :P')
          when /\A\/(admin|secret)/i
            send_reply('https://youtu.be/dQw4w9WgXcQ')
        end
      end
    end
  end
end

# read token from file
token = File.read("token.txt").chomp!
test_bot=TestBot.new token
# start the bot
test_bot.start_bot
