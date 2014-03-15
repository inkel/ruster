class Ruster::Node
  attr :addr

  def initialize(addr)
    @addr = addr
  end

  def client
    @client ||= Redic.new("redis://#{addr}")
  end

  def enabled?
    client.call("INFO", "cluster").include?("cluster_enabled:1")
  end
end
