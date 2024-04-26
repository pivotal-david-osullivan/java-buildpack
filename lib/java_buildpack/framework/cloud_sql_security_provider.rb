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

      private_constant :FILTER

    end
  end
end
