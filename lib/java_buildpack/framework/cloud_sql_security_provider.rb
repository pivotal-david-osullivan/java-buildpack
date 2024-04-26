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
        puts "#{'----->'.red.bold} #{'Cloud Security Provider'.blue.bold} enabled for bound service"
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        return unless supports?
        
        FileUtils.mkdir_p (@droplet.root + '.profile.d/')
        FileUtils.mkdir_p (@droplet.root + 'sql-scripts/')
        @droplet.copy_resources (@droplet.root + 'sql-scripts/')

        if @application.services.find_service(PSQL_FILTER)
          FileUtils.cp_r(@droplet.root + 'sql-scripts/gcp_postgres.sh', @droplet.root + '.profile.d/')
        elsif @application.services.find_service(MYSQL_FILTER)
          FileUtils.cp_r(@droplet.root + 'sql-scripts/gcp_mysql.sh', @droplet.root + '.profile.d/')
        end
     end

      def detect
        CloudSqlSecurityProvider.to_s.dash_case
      end

      protected

      def supports?
        @application.services.one_service? FILTER, 'sslrootcert', 'sslcert', 'sslkey'
      end

      private

      FILTER = /csb-google/.freeze
      PSQL_FILTER = /csb-google-postgres/.freeze
      MYSQL_FILTER = /csb-google-mysql/.freeze

      private_constant :PSQL_FILTER, :MYSQL_FILTER

    end
  end
end
