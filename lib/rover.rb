require 'socket'

module Rover

  class Rover
    @HOST = '192.168.1.100'
    @PORT = 80
    @Socket

    TARGET_ID = 'AC13'
    TARGET_PASSWORD = 'AC13'

    def initialize
      @Socket = socket
      send_command_int_request(0, [0, 0, 0, 0])
      reply = receive_command_reply(82)
    end


    def self.class
      puts "classmethod"
    end

    def instance
      puts "instance method"
    end
  end

  #private

  def socket
    socket ||=  TCPSocket.new @HOST, @PORT
    socket
  end

  def send_command_int_request(id, intvals)
    bytevals = []
    intvals.pack("L*").each { |i|  bytevals << i.ord }
    self.send_command_request(id, 4*intvals.size, bytevals)
  end

  def send_command_request(id, n, contents)
    send_request('O', id, n, contents)
  end

  def send_request(c, id, n contents)
    bytes = ['M'.ord, 'O'.ord, '_'.ord, c.ord, id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0]
    bytes + conents
    request = bytes.collect{ |b| b.chr}.join
    socket.send(request)
  end

  def receive_command_reply(count)
     socket.recv(count)
  end

end
