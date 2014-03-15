class Ruster::Node
  attr :addr
  attr :id
  attr :flags
  attr :master_id
  attr :ping_epoch
  attr :pong_epoch
  attr :config_epoch
  attr :state
  attr :slots

  def initialize(addr)
    @addr = addr
  end

  def client
    @client ||= Redic.new("redis://#{addr}")
  end

  def enabled?
    client.call("INFO", "cluster").include?("cluster_enabled:1")
  end

  def read_info_line!(info_line)
    parts = info_line.split

    @id = parts.shift
    addr = parts.shift
    @flags = parts.shift.split(",")
    @addr = addr unless @flags.include?("myself")
    @master_id = parts.shift
    @ping_epoch = parts.shift.to_i
    @pong_epoch = parts.shift.to_i
    @config_epoch = parts.shift.to_i
    @state = parts.shift
    @slots = parts
  end
end
