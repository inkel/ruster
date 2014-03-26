require_relative "./helper"

Protest.describe "Ruster::Util" do
  U = Module.new { extend Ruster::Util }

  test "parse INFO as hash"do
    info = "cluster_state:fail\r\ncluster_slots_assigned:0\r\ncluster_slots_ok:0\r\ncluster_slots_pfail:0\r\ncluster_slots_fail:0\r\ncluster_known_nodes:1\r\ncluster_size:0\r\ncluster_current_epoch:0\r\ncluster_stats_messages_sent:0\r\ncluster_stats_messages_received:0\r\n"

    data = U.parse_info(info)

    assert data.is_a?(Hash)

    assert_equal "fail", data[:cluster_state]
    assert_equal "0",    data[:cluster_slots_assigned]
    assert_equal "0",    data[:cluster_slots_ok]
    assert_equal "0",    data[:cluster_slots_pfail]
    assert_equal "0",    data[:cluster_slots_fail]
    assert_equal "1",    data[:cluster_known_nodes]
    assert_equal "0",    data[:cluster_size]
    assert_equal "0",    data[:cluster_current_epoch]
    assert_equal "0",    data[:cluster_stats_messages_sent]
    assert_equal "0",    data[:cluster_stats_messages_received]
  end

  test "ignore comments in INFO parsing" do
    data = U.parse_info("# Cluster\r\ncluster_enabled:1\r\n")

    assert_equal 1, data.size
  end
end
