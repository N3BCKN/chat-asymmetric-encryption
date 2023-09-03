require 'socket'
require 'base64' 
require 'openssl'
require 'json'

PORT       = 2000
KEY_LENGTH = 4096

ConnectedClient = Struct.new(:socket, :username)

class Server
  def initialize 
    @server       = TCPServer.open(PORT)
    @clients      = []
    @digest_func  = OpenSSL::Digest::SHA256.new
    @key_pair     = OpenSSL::PKey::RSA.new(KEY_LENGTH)
    @public_key   = OpenSSL::PKey::RSA.new(@key_pair.public_key.to_der)
  end 

  def run
    loop do            
      Thread.start(@server.accept) do |client|   
        client.puts 'Welcome to the chat!'
        client.puts "It's #{server_time("%d/%m/%Y %I:%M %p")} and currently there are #{@clients.size} active users"
        client.puts 'What is your nickname?'
        nickname = ''
      
        loop do 
          nickname = client.gets.chomp
          break if nickname_valid?(nickname)
          client.puts 'invalid nickname. Please try again'
        end 

        response = {public_key: @public_key}.to_json
        client.puts response

        client.puts "Hello #{nickname}, enjoy the conversation!"
        broadcast("SYSTEM: #{nickname} enters the chat")

        connected_client = ConnectedClient.new(client, nickname)
        @clients << connected_client

        begin
          while message = client.gets.chomp
            decrypted_message = decrypt(JSON.parse(message)["message"])
            broadcast(connected_client, "#{nickname}: #{decrypted_message}")
          end
        rescue
          client.close
          @clients.delete(connected_client)
          broadcast("SYSTEM: #{nickname} left chat" )
        end
      end
    end
  end

  private
  def broadcast(sender = nil, message)
    @clients.each do |client|
      unless client == sender
        full_message = "#{server_time}> #{message}"
        signature = sign_message(full_message)
             
        to_broadcast = {
          message: encrypt(full_message),
          signature: signature
        }.to_json

        client.socket.puts to_broadcast
      end 
    end 
  end

  def nickname_valid?(nickname)
    ((3...20).include? nickname.size) && (@clients.none? {|client| client.username == nickname})
  end 

  def server_time(format = "%I:%M %p")
    Time.now.utc.strftime(format)
  end 

  def encrypt(message)
    Base64.encode64(@key_pair.private_encrypt(message))
  end

  def decrypt(message)
    @key_pair.private_decrypt(Base64.decode64(message))
  end

  def sign_message(message)
    Base64.encode64(@key_pair.sign(@digest_func, message))
  end
end 

server = Server.new 
server.run

