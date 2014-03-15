require_relative "./helper"

require "timeout"

Protest.describe "Ruster::Cluster" do
  test "add node" do
    with_nodes(n: 2) do |ports|
      port_a, port_b = ports.to_a

      bob = Ruster::Node.new("127.0.0.1:#{port_a}")
      bob.add_slots(*0..16383)
      cluster = Ruster::Cluster.new(bob)

      Timeout.timeout(10) { sleep 0.05 until cluster.ok? }

      assert_equal 1, cluster.nodes.size
      assert_equal [0..16383], bob.slots

      cluster.add_node("127.0.0.1", port_b)

      Timeout.timeout(10) { sleep 0.05 until cluster.ok? }

      assert_equal 2, cluster.nodes.size

      slots = cluster.nodes.map do |node|
        [node.addr, node.slots]
      end

      # Do not realloce slots
      assert_equal 2, slots.size
      assert slots.include?(["127.0.0.1:#{port_a}", [0..16383]])
      assert slots.include?(["127.0.0.1:#{port_b}", []])
    end
  end
end
