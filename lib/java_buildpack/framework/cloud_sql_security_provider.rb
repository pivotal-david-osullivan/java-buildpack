# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2013-2020 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'shellwords'
require 'tempfile'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'
require 'java_buildpack/util/qualify_path'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Safenet ProtectApp Java Security Provider support.
    class CloudSqlSecurityProvider < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Util

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        log '#release'.yellow
        download_zip false

        @droplet.copy_resources

        credentials = @application.services.find_service(FILTER, 'sslrootcert', 'sslcert', 'sslkey')['credentials']

        pkcs12 = merge_client_credentials credentials
        add_client_credentials pkcs12

        add_trusted_certificates credentials['sslrootcert']
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        log '#release'.yellow
        java_opts = @droplet.java_opts

        add_additional_properties(java_opts)
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        log '#supports?'.yellow
        @application.services.one_service? FILTER, 'sslrootcert', 'sslcert', 'sslkey'
      end

      private

      FILTER = /csb-google-mysql/.freeze

      private_constant :FILTER


      def log(message)
        puts "#{'===========>'.blue} #{'CloudSqlSecurityProvider'.red.bold} #{message}"
      end
      def add_additional_properties(java_opts)
        java_opts
          .add_system_property('javax.net.ssl.keyStore', keystore)
          .add_system_property('javax.net.ssl.keyStorePassword', password)
      end

      def add_client_credentials(pkcs12)
        shell "#{keytool} -importkeystore -noprompt -destkeystore #{keystore} -deststorepass #{password} " \
              "-srckeystore #{pkcs12.path} -srcstorepass #{password} -srcstoretype pkcs12" \
              " -alias #{File.basename(pkcs12)}"
      end

      def add_trusted_certificates(trusted_certificate)
        File.open("#{@droplet.root}/etc/ssl/certs/ca-certificates.crt", 'a') do |f|
          f.write("#{trusted_certificate}\n")
        end
      end

      def ext_dir
        @droplet.sandbox + 'ext'
      end

      def keystore
        @droplet.sandbox + 'cloud-sql-keystore.jks'
      end

      def keytool
        @droplet.java_home.root + 'bin/keytool'
      end

      def merge_client_credentials(credentials)
        certificate = write_certificate credentials['sslcert']
        private_key = write_private_key credentials['sslkey']

        pkcs12 = Tempfile.new('pkcs12-')
        pkcs12.close

        shell "openssl pkcs12 -export -in #{certificate.path} -inkey #{private_key.path} " \
              "-name #{File.basename(pkcs12)} -out #{pkcs12.path} -passout pass:#{password}"

        pkcs12
      end

      def password
        'cloud-sql-keystore-password'
      end

      def write_certificate(certificate)
        Tempfile.open('certificate-') do |f|
          f.write "#{certificate}\n"
          f.sync
          f
        end
      end

      def write_private_key(private_key)
        Tempfile.open('private-key-') do |f|
          f.write "#{private_key}\n"
          f.sync
          f
        end
      end

    end
  end
end
