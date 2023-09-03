require 'socket'
require 'json'
require 'openssl'
require 'base64'
require 'byebug'

PORT = 2000

class Client
  def initialize
    @socket       = TCPSocket.new('localhost', PORT)
    @digest_func  = OpenSSL::Digest::SHA256.new
    @public_key
  end 

  def run
    local_typing_thread = Thread.new { local_typing }
    receive_from_server_thread = Thread.new { receive_from_server}
    local_typing_thread.join
    receive_from_server_thread.join
    
    @socket.close
  end 

  private
  def local_typing
    loop do
      message = gets.chomp
      if @public_key.nil? 
        @socket.puts message
      else
        encrypted_message = {message: encrypt(message)}.to_json
        @socket.puts encrypted_message
      end 
    end
  end

  def receive_from_server
    while line = @socket.gets
      
      if @public_key.nil? && !valid_json?(line)
        puts line
        next
      end 
      
      response = JSON.parse(line)
  
      if response.has_key? 'public_key'
        @public_key = OpenSSL::PKey::RSA.new(response['public_key'])
        next
      end

      decrypted_message = decrypt(response['message'])
      signature         = Base64.decode64(response['signature'])

      if valid_signature?(signature,decrypted_message)
        puts decrypted_message
      else
        p 'ERROR: server responded with invalid signature.'
      end





      # if valid_json?(line)
      #   response = JSON.parse(line)
      #   if response.has_key? 'message'
          
      #     decrypted_message = decrypt(response['message'])
      #     signature         = Base64.decode64(response['signature'])

      #     if valid_signature?(signature,decrypted_message)
      #       puts decrypted_message
      #     else
      #       p 'wrong signature'
      #     end 
      #   elsif response.has_key? 'public_key'
      #     @public_key = OpenSSL::PKey::RSA.new(response['public_key'])
      #   else
      #     p response
      #   end 
      # else
      #   puts line
      # end 
    end
  end

  private
  def valid_json?(json)
    JSON.parse(json)
    true
  rescue JSON::ParserError, TypeError => e
    false
  end

  def encrypt(message)
    Base64.encode64(@public_key.public_encrypt(message))
  end 

  def decrypt(message)
    @public_key.public_decrypt(Base64.decode64(message))
  end

  def valid_signature?(signature, message)
    @public_key.verify(@digest_func, signature, message)
  end 
end

client = Client.new
client.run
