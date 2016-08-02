module Fog
  module Network
    class AzureRM
      # Real class for Network Request
      class Real
        def add_dns_servers_in_virtual_network(resource_group_name, virtual_network_name, new_dns_servers)
          Fog::Logger.debug "Adding DNS Servers: #{new_dns_servers.join(', ')} in Virtual Network: #{virtual_network_name}"

          virtual_network = get_virtual_network_object_for_add_dns!(resource_group_name, virtual_network_name, new_dns_servers)
          begin
            promise = @network_client.virtual_networks.create_or_update(resource_group_name, virtual_network_name, virtual_network)
            result = promise.value!
            Fog::Logger.debug "DNS Servers: #{new_dns_servers.join(', ')} added successfully."
            Azure::ARM::Network::Models::VirtualNetwork.serialize_object(result.body)
          rescue  MsRestAzure::AzureOperationError => e
            msg = "Exception adding DNS Servers: #{new_dns_servers.join(', ')} in Virtual Network: #{virtual_network_name}. #{e.body['error']['message']}"
            raise msg
          end
        end

        private

        def get_virtual_network_object_for_add_dns!(resource_group_name, virtual_network_name, new_dns_servers)
          begin
            promise = @network_client.virtual_networks.get(resource_group_name, virtual_network_name)
            result = promise.value!
          rescue MsRestAzure::AzureOperationError => e
            msg = "Exception adding DNS Servers: #{new_dns_servers.join(', ')} in Virtual Network: #{virtual_network_name}. #{e.body['error']['message']}"
            raise msg
          end

          virtual_network = result.body
          if virtual_network.properties.dhcp_options.nil?
            dhcp_options = Azure::ARM::Network::Models::DhcpOptions.new
            dhcp_options.dns_servers = new_dns_servers
            virtual_network.properties.dhcp_options = dhcp_options
          else
            attached_servers = virtual_network.properties.dhcp_options.dns_servers
            raise "Cannot add DNS Server(s): Provided DNS Server(s) is/are already added in Virtual Network: #{virtual_network_name}" if attached_servers & new_dns_servers == new_dns_servers
            virtual_network.properties.dhcp_options.dns_servers = attached_servers | new_dns_servers
          end
          virtual_network
        end
      end

      # Mock class for Network Request
      class Mock
        def add_dns_servers_in_virtual_network(*)
          {
            'id' => '/subscriptions/########-####-####-####-############/resourceGroups/fog-rg/providers/Microsoft.Network/virtualNetworks/fog-vnet',
            'name' => 'fog-vnet',
            'type' => 'Microsoft.Network/virtualNetworks',
            'location' => 'westus',
            'properties' =>
              {
                'addressSpace' =>
                  {
                    'addressPrefixes' =>
                      [
                        '10.1.0.0/16',
                        '10.2.0.0/16'
                      ]
                  },
                'dhcpOptions' => {
                  'dnsServers' => [
                    '10.1.0.5',
                    '10.1.0.6'
                  ]
                },
                'subnets' =>
                  [
                    {
                      'id' => '/subscriptions/########-####-####-####-############/resourceGroups/fog-rg/providers/Microsoft.Network/virtualNetworks/fog-vnet/subnets/fog-subnet',
                      'properties' =>
                        {
                          'addressPrefix' => '10.1.0.0/24',
                          'provisioningState' => 'Succeeded'
                        },
                      'name' => 'fog-subnet'
                    }
                  ],
                'resourceGuid' => 'c573f8e2-d916-493f-8b25-a681c31269ef',
                'provisioningState' => 'Succeeded'
              }
          }
        end
      end
    end
  end
end
