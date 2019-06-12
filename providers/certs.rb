action :generate do

	# I haven't found a way of passing the password for the key in Kubeadm (Kubernetes?)
  # So here we generate unencrypted keys.

  bash 'generate-key' do
    user "root"
    group "root"
    cwd new_resource.path
    code <<-EOH
      openssl genrsa -out #{new_resource.name}.key #{node['kube-hops']['pki']['keysize']}
    EOH
  end

  if new_resource.self_signed
    bash 'self-sign' do
      user "root"
      group "root"
      cwd new_resource.path
      code <<-EOH
        openssl req -x509 -new -nodes -key #{new_resource.name}.key -subj "#{new_resource.subject}" -days #{node['kube-hops']['pki']['days']} -out #{new_resource.name}.crt
      EOH
    end
  else
    # Generate CSR
    bash 'generate-csr' do
      user "root"
      group "root"
      cwd new_resource.path
      code <<-EOH
        openssl req -new -key #{new_resource.name}.key -subj "#{new_resource.subject}" -out #{new_resource.name}.csr
      EOH
    end

    if new_resource.ca_path.nil? || new_resource.ca_path.empty?

      # Send HTTP(s) request to Hopsworks-ca to sing the csr
      ruby_block 'sign-csr' do
        block do
          require 'net/https'
          require 'http-cookie'
          require 'json'

          url = URI.parse("https://#{node['kube-hops']['pki']['ca_api']}/hopsworks-api/api/auth/login")
          ca_url = URI.parse("https://#{node['kube-hops']['pki']['ca_api']}/hopsworks-ca/v2/certificate/kube")


          params =  {
            :email => node["kagent"]["dashboard"]["user"],
            :password => node["kagent"]["dashboard"]["password"]
          }

          http = Net::HTTP.new(url.host, url.port)
          http.read_timeout = 120
          http.use_ssl = true
          http.verify_mode = node['kube-hops']['pki']['verify_hopsworks_cert'].eql?("true") ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

          jar = ::HTTP::CookieJar.new

          http.start do |connection|

            request = Net::HTTP::Post.new(url)
            request.set_form_data(params, '&')
            response = connection.request(request)

            if( response.is_a?( Net::HTTPSuccess ) )
                # your request was successful
                puts "The Response -> #{response.body}"

                response.get_fields('Set-Cookie').each do |value|
                  jar.parse(value, url)
                end

                csr = ::File.read("#{new_resource.path}/#{new_resource.name}.csr")
                request = Net::HTTP::Post.new(ca_url)
                request.body = {'csr' => csr}.to_json
                request['Content-Type'] = "application/json"
                request['Cookie'] = ::HTTP::Cookie.cookie_value(jar.cookies(ca_url))
		            request['Authorization'] = response['Authorization']
                response = connection.request(request)

                if ( response.is_a? (Net::HTTPSuccess))
                  json_response = ::JSON.parse(response.body)
                  ::File.write("#{new_resource.path}/#{new_resource.name}.crt", json_response['signedCert'])
                else
                  raise "Error signing certificate #{new_resource.name}"
                end
            else
                puts response.body
                raise "Error logging in"
            end
          end
        end
      end

    else

      # Sign the certificate with a local CA
      # This is used for instance from the ETCD ca and relative certificates on master.
      bash 'self-sign' do
        user "root"
        group "root"
        cwd new_resource.path
        code <<-EOH
          openssl x509 -req -in #{new_resource.name}.csr -days #{node['kube-hops']['pki']['days']} -out #{new_resource.name}.crt \
          -CAcreateserial -CA #{new_resource.ca_path}/#{new_resource.ca_name}.crt -CAkey #{new_resource.ca_path}/#{new_resource.ca_name}.key -extensions v3_ext -extfile #{node['kube-hops']['pki']['dir']}/kube-ca.cnf
        EOH
      end

    end
  end
end

action :fetch_cert do

  ruby_block 'fetch-ca' do
      block do
        require 'net/https'
        require 'http-cookie'
        require 'json'

        url = URI.parse("https://#{node['kube-hops']['pki']['ca_api']}/hopsworks-api/api/auth/login")
        ca_url = URI.parse("https://#{node['kube-hops']['pki']['ca_api']}/hopsworks-ca/v2/certificate/kube")

        params =  {
          :email => node["kagent"]["dashboard"]["user"],
          :password => node["kagent"]["dashboard"]["password"]
        }

        http = Net::HTTP.new(url.host, url.port)
        http.read_timeout = 120
        http.use_ssl = true
        http.verify_mode = node['kube-hops']['pki']['verify_hopsworks_cert'].eql?("true") ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

        jar = ::HTTP::CookieJar.new

        http.start do |connection|

          request = Net::HTTP::Post.new(url)
          request.set_form_data(params, '&')
          response = connection.request(request)

          if( response.is_a?( Net::HTTPSuccess ) )
              # your request was successful
              puts "The Response -> #{response.body}"

              response.get_fields('Set-Cookie').each do |value|
                jar.parse(value, url)
              end

              request = Net::HTTP::Get.new(ca_url)
              request['Cookie'] = ::HTTP::Cookie.cookie_value(jar.cookies(ca_url))
	            request['Authorization'] = response['Authorization']
              response = connection.request(request)

              if ( response.is_a? (Net::HTTPSuccess))
                json_response = ::JSON.parse(response.body)
                ::File.write("#{new_resource.path}/#{new_resource.name}.crt", json_response['intermediateCaCert'])
              else
                raise "Error signing certificate #{new_resource.name}"
              end
          else
              puts response.body
              raise "Error logging in"
          end
        end
      end
   end
end
