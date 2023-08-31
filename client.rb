require 'socket'

PORT = 2000

class Client
  def initialize
    @socket = TCPSocket.new('localhost', PORT)  
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
      @socket.puts message
    end
  end

  def receive_from_server
    while line = @socket.gets
      puts line
    end
  end
end

client = Client.new

client.run
