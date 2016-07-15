require 'telegram/bot'
require "rubygems"
require "shikashi"

#require 'openssl'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

include Shikashi
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

class TestBot
  @token = ''
  @bot = NIL
  @last_message=NIL

  def initialize(token)
    @token = token
  end

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

  # def puts(o)
  #   super(o)
  #   $bot.api.send_message(chat_id: $message.chat.id, text: o.to_s)
  # end

  def send_reply(text)
    @bot.api.send_message(chat_id: @last_message.chat.id, text: text)
  end

  def start_bot
    Telegram::Bot::Client.run(@token) do |bot|
      @bot=bot
      bot.listen do |message|
        @last_message=message
        puts message
        case message.text
          when '/start'
            bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}. I am started! >.<")
          when '/stop'
            bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}. Why did you stop me? T^T")
          when '/help'
            bot.api.send_message(chat_id: message.chat.id, text: "This bot is created by @Energy0124. \nSource code is avaliable here:\n https://github.com/Energy0124/EnergyRubyTelegramBot.git ")
          when /\A\/run/i
            message.text.slice! '/run'
            begin
              stdout=with_captured_stdout {
                s = Sandbox.new
                priv = Privileges.new
                priv.allow_methods :times, :puts, :print, :each
                s.run(priv, message.text, :no_base_namespace => true)
              }
              puts(stdout)
              send_reply("Result:\n#{stdout}")
            rescue Exception => ex
              send_reply("Error:\n#{ex}")
            end
          when /fuck/i
            send_reply("I fucking hate people saying 'fuck'.")
          when /shit/i
            send_reply('Shit!')
          when /dota/i
            send_reply('Dota is the best!')
          when /stupid bot/i
            send_reply('Still a bit smarter than you.')
        end
      end
    end
  end
end

token = File.read("token.txt").chomp!
test_bot=TestBot.new token
test_bot.start_bot
