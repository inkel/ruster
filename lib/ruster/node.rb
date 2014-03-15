class Ruster::Node
  attr :addr

  def initialize(addr)
    @addr = addr
  end

  def client
    @client ||= Redic.new("redis://#{addr}")
  end
end
