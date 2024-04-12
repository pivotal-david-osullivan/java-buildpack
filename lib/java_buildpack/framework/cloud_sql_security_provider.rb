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
require 'java_buildpack/component/base_component'
require 'java_buildpack/framework'
require 'java_buildpack/util/qualify_path'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling secure communication with GCP CloudSQL instances.
    class CloudSqlSecurityProvider < JavaBuildpack::Component::BaseComponent
      include JavaBuildpack::Util

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        return unless supports?

        credentials = @application.services.find_service(FILTER, 'sslrootcert', 'sslcert', 'sslkey')['credentials']

      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        return unless supports?
        
        FileUtils.mkdir_p (@droplet.root + '.profile.d/')
        @droplet.copy_resources (@droplet.root + '.profile.d/')
     end

      def detect
        CloudSqlSecurityProvider.to_s.dash_case
      end

      protected

      def supports?
        @application.services.one_service? FILTER, 'sslrootcert', 'sslcert', 'sslkey'
      end

      private

      FILTER = /csb-google-/.freeze
      POSTGRES_PEM = '.postgresql/postgresql-key.pem'
      POSTGRES_DER = '.postgresql/postgresql.pk8'

      private_constant :FILTER

      private_constant :POSTGRES_PEM
      private_constant :POSTGRES_DER

      def keystore
        @droplet.sandbox + 'cloud-sql-keystore.jks'
      end

      def keytool
        @droplet.java_home.root + 'bin/keytool'
      end

      def create_der
        shell "openssl pkcs8 -topk8 -inform PEM -in #{qualify_path(POSTGRES_PEM)} " \
              "-outform DER -out #{qualify_path(POSTGRES_DER)} -v1 PBE-MD5-DES -nocrypt"
      end

    end
  end
end
