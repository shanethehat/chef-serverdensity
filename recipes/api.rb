# ex: set tabstop=2 shiftwidth=2 expandtab:
#
# Cookbook Name:: serverdensity
# Recipe:: api
#
# Get or create a device for the current hostname using the Server Density API

require 'open-uri'
require 'chef/log'
require 'chef/rest'
require 'chef/json_compat'

api_version = node['serverdensity']['api_version']

Chef::Log.info("No agent key defined, querying Server Density API v#{ api_version } for host '#{ node[:hostname] }'")

def group(node)
    if node['serverdensity']['device_group']
      node['serverdensity']['device_group']
    else
      'chef'
    end
end

case Float(api_version)

when 1..2
  base_url = "https://api.serverdensity.com/#{ api_version }/"
  headers = {
    "Authorization" => "Basic #{ node['serverdensity']['api_username'] }:#{ node['serverdensity']['api_password'] }"
  }
  client = Chef::REST::RESTRequest.new("GET", "#{ base_url }devices/getByHostName?hostName=#{ node[:hostname] }", nil, headers)
  response = client.call {|r| r.read_body}  
  device = Chef::JSONCompat.from_json(response.body.chomp)

  if device['status'] == 2
    Chef::Log.info("Couldn't find device, creating a new one")

    # Create new device
    data = {
      'name' => node[:node_name],
      'hostName' => node[:hostname],
      'group' => group(node)
    }

    data_array = []
    data.each_pair do |name, value|
      data_array.push(URI::encode("#{ name }=#{ value }"))
    end
    data_str = data_array.join("&")

    client = Chef::REST::RESTRequest.new("POST", "#{ base_url }devices/add", data_str, headers)
    response = client.call {|r| r.read_body}  
    device = Chef::JSONCompat.from_json(response.body.chomp)
  end

  agent_key = device['device']['agentKey']
  Chef::Log.info("Using agent key '#{ agent_key }'")

  node['serverdensity']['agent_key'] = agent_key

when 2..3

end
